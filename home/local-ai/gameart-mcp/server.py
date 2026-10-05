"""Game-art MCP: tuned ComfyUI workflows exposed as discrete tools.

Tools:
  - generate_icon: item/ability icons, alpha-cut by default
  - generate_sprite: character sprites (pixel-art aware)
  - generate_background: scene/parallax backgrounds
  - generate_ui_panel: UI chrome elements
  - generate_layered: one prompt → separate RGBA layers (subject/background/...)
  - generate_text_art: art with legible in-image text (logos, signage, banners)
  - generate_image: unopinionated escape hatch
  - refine: upscale + low-denoise second pass on an existing image
  - cutout: alpha-cut an existing image file
  - pixelize / conform_palette: snap art to a pixel grid and a fixed palette
  - tile_preview: check whether a terrain tile wraps without visible seams
  - critique / generate_best: local VLM scores renders, best one wins
  - list_palettes / list_checkpoints / list_loras / list_diffusion_models / health

Backends:
  zimage     Z-Image-Turbo (6B, 8 steps, cfg 1) — the default. Sharp prompt
             adherence, ~5x faster than SDXL at 1024px, no LoRA ecosystem.
  zimage-hq  Z-Image base, 30 steps at cfg 4 — same encoder/VAE, for finals.
  sdxl       SDXL base + LoRA stack, where a style LoRA does the work
             (pixel-art sprites, 3d-icon look).
  layered    Qwen-Image-Layered — emits real RGBA layers, no matting step.
  ideogram   Ideogram 4 (dual conditional/unconditional UNets) — the only
             local model that renders readable text.

Each tool submits a workflow to a running ComfyUI on COMFY_URL, waits for
completion over the websocket, and returns absolute paths of the PNGs.
"""

from __future__ import annotations

import asyncio
import base64
import json
import mimetypes
import os
import random
import time
import uuid
from pathlib import Path
from typing import Any

import httpx
import numpy as np
import websockets
from mcp.server.fastmcp import FastMCP
from PIL import Image, ImageDraw

COMFY_URL = os.environ.get("COMFY_URL", "http://127.0.0.1:8188")
OUTPUT_DIR = Path(
    os.environ.get(
        "GAMEART_OUTPUT_DIR",
        os.path.expanduser("~/.local/share/gameart-mcp/output"),
    )
)

# --- Z-Image-Turbo (Comfy-Org/z_image_turbo split files) --------------------
# Node/param values mirror ComfyUI's own `image_z_image_turbo` template:
# CLIPLoader type is "lumina2", sampling needs ModelSamplingAuraFlow(shift=3),
# and the distilled model runs at cfg 1 where a negative prompt is a no-op.
Z_UNET = os.environ.get("GAMEART_ZIMAGE_UNET", "z_image_turbo_bf16.safetensors")
Z_CLIP = os.environ.get("GAMEART_ZIMAGE_CLIP", "qwen_3_4b.safetensors")
Z_VAE = os.environ.get("GAMEART_ZIMAGE_VAE", "ae.safetensors")
Z_STEPS = int(os.environ.get("GAMEART_ZIMAGE_STEPS", "8"))
Z_CFG = float(os.environ.get("GAMEART_ZIMAGE_CFG", "1.0"))
Z_SHIFT = float(os.environ.get("GAMEART_ZIMAGE_SHIFT", "3.0"))
# Non-distilled Z-Image: same text encoder and VAE, 30-50 steps at cfg 3-5.
Z_BASE_UNET = os.environ.get("GAMEART_ZIMAGE_BASE_UNET", "z_image_bf16.safetensors")
Z_BASE_STEPS = int(os.environ.get("GAMEART_ZIMAGE_BASE_STEPS", "30"))
Z_BASE_CFG = float(os.environ.get("GAMEART_ZIMAGE_BASE_CFG", "4.0"))

# --- Qwen-Image-Layered (Comfy-Org/Qwen-Image-Layered_ComfyUI) --------------
# Decomposes a prompt into stacked RGBA layers. Beats generate-then-matte:
# the alpha is inherent, so soft edges (glow, smoke, hair) survive.
LAYERED_UNET = os.environ.get("GAMEART_LAYERED_UNET", "qwen_image_layered_fp8mixed.safetensors")
# The encoder must be the HunyuanVideo_1.5_repackaged build of this filename.
# Comfy-Org/Qwen-Image_ComfyUI ships a same-named, differently-scaled file that
# fails to load with "shape '[3420, 1280]' is invalid".
LAYERED_CLIP = os.environ.get("GAMEART_LAYERED_CLIP", "qwen_2.5_vl_7b_fp8_scaled.safetensors")
LAYERED_VAE = os.environ.get("GAMEART_LAYERED_VAE", "qwen_image_layered_vae.safetensors")

# --- Ideogram 4 (Comfy-Org/Ideogram-4) --------------------------------------
# Guidance runs two UNets (conditional + unconditional) through
# DualModelGuider, so both files are required. Sigmas come from
# Ideogram4Scheduler, not the KSampler schedulers.
IDEOGRAM_UNET = os.environ.get("GAMEART_IDEOGRAM_UNET", "ideogram4_fp8_scaled.safetensors")
IDEOGRAM_UNET_UNCOND = os.environ.get(
    "GAMEART_IDEOGRAM_UNET_UNCOND", "ideogram4_unconditional_fp8_scaled.safetensors"
)
IDEOGRAM_CLIP = os.environ.get("GAMEART_IDEOGRAM_CLIP", "qwen3vl_8b_fp8_scaled.safetensors")
IDEOGRAM_VAE = os.environ.get("GAMEART_IDEOGRAM_VAE", "flux2-vae.safetensors")

# --- Qwen-Image-Edit 2511 (Comfy-Org/Qwen-Image-Edit_ComfyUI) --------------
# Identity-preserving edits. Shares the qwen_2.5_vl_7b encoder with the
# layered model but wants the standard Qwen-Image VAE, not the layered one.
EDIT_UNET = os.environ.get("GAMEART_EDIT_UNET", "qwen_image_edit_2511_fp8mixed.safetensors")
EDIT_VAE = os.environ.get("GAMEART_EDIT_VAE", "qwen_image_vae.safetensors")
# LoRA trained for turnarounds — "same subject, different camera angle".
EDIT_ANGLES_LORA = os.environ.get(
    "GAMEART_EDIT_ANGLES_LORA", "Qwen-Edit-2509-Multiple-angles.safetensors"
)

# --- Local VLM judge --------------------------------------------------------
# Renders are cheap, picking is not. qwen3-vl scores a batch against the brief
# so the caller gets one good asset instead of four to sift through.
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434")
VLM_MODEL = os.environ.get("GAMEART_VLM_MODEL", "qwen3-vl:8b")

# --- Palette conforming -----------------------------------------------------
# A diffusion model will not hold a 46-colour palette no matter how the prompt
# is worded. Nearest-colour mapping after the fact does hold it, exactly.
PALETTES_PATH = Path(
    os.environ.get("GAMEART_PALETTES", Path(__file__).with_name("palettes.json"))
)

# --- SDXL + LoRA ------------------------------------------------------------
DEFAULT_CHECKPOINT = os.environ.get("GAMEART_SDXL_CHECKPOINT", "sd_xl_base_1.0.safetensors")
DEFAULT_PIXEL_LORA = os.environ.get("GAMEART_PIXEL_LORA", "pixel-art-xl.safetensors")
# Civitai's game-icon-institute LoRA is geo-blocked in AU; the HF-hosted
# 8glabs/3d-icon-sdxl-lora is the installed substitute.
DEFAULT_ICON_LORA = os.environ.get("GAMEART_ICON_LORA", "3d-icon-sdxl-lora.safetensors")

# BiRefNet in models/background_removal/ — ComfyUI's native matting model.
# Real alpha beats "dark background" prompting: icons and sprites drop
# straight into an engine without a manual key.
BG_REMOVAL_MODEL = os.environ.get("GAMEART_BG_REMOVAL_MODEL", "birefnet.safetensors")

JOB_TIMEOUT = float(os.environ.get("GAMEART_TIMEOUT", "600"))

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
mcp = FastMCP("gameart")


def _seed(seed: int | None) -> int:
    return seed if seed is not None else random.randint(0, 2**31 - 1)


def _dims(aspect: str) -> tuple[int, int]:
    return {
        "portrait": (1024, 1536),
        "square": (1024, 1024),
        "wide": (1536, 640),
    }.get(aspect, (1536, 1024))


def _finish(
    g: dict[str, dict],
    image_ref: list,
    filename_prefix: str,
    transparent: bool,
) -> dict[str, dict]:
    """Append optional alpha-cut, then SaveImage. Returns the graph."""
    if transparent:
        g["bg_model"] = {
            "class_type": "LoadBackgroundRemovalModel",
            "inputs": {"bg_removal_name": BG_REMOVAL_MODEL},
        }
        g["bg_mask"] = {
            "class_type": "RemoveBackground",
            "inputs": {"image": image_ref, "bg_removal_model": ["bg_model", 0]},
        }
        # RemoveBackground's output is documented as a foreground mask, but it
        # comes back in ComfyUI's mask convention (selected region = 1 = the
        # background). Feeding it straight to JoinImageWithAlpha produces a PNG
        # with the subject transparent and the backdrop opaque — which still
        # looks correct in any viewer that composites over dark, so check the
        # alpha values, not the thumbnail, if this ever regresses.
        g["bg_mask_inv"] = {"class_type": "InvertMask", "inputs": {"mask": ["bg_mask", 0]}}
        # JoinImageWithAlpha turns the RGB + mask pair into the RGBA that
        # SaveImage writes as a PNG.
        g["rgba"] = {
            "class_type": "JoinImageWithAlpha",
            "inputs": {"image": image_ref, "alpha": ["bg_mask_inv", 0]},
        }
        image_ref = ["rgba", 0]
    g["save"] = {
        "class_type": "SaveImage",
        "inputs": {"filename_prefix": filename_prefix, "images": image_ref},
    }
    return g


def _zimage_graph(
    *,
    prompt: str,
    negative: str,
    seed: int,
    width: int,
    height: int,
    batch: int,
    filename_prefix: str,
    transparent: bool,
    steps: int = Z_STEPS,
    cfg: float = Z_CFG,
    unet: str = Z_UNET,
    loras: list[tuple[str, float]] | None = None,
) -> dict[str, Any]:
    g: dict[str, dict] = {
        "unet": {
            "class_type": "UNETLoader",
            "inputs": {"unet_name": unet, "weight_dtype": "default"},
        },
        "clip": {
            "class_type": "CLIPLoader",
            "inputs": {"clip_name": Z_CLIP, "type": "lumina2", "device": "default"},
        },
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": Z_VAE}},
    }

    # Z-Image LoRAs (what `lora-train` produces) patch the transformer only —
    # there is no CLIP side to strengthen, so LoraLoaderModelOnly is the node.
    model_ref: list = ["unet", 0]
    for idx, (lora_name, strength) in enumerate(loras or []):
        node = f"lora_{idx}"
        g[node] = {
            "class_type": "LoraLoaderModelOnly",
            "inputs": {
                "lora_name": lora_name,
                "strength_model": strength,
                "model": model_ref,
            },
        }
        model_ref = [node, 0]

    g |= {
        "shift": {
            "class_type": "ModelSamplingAuraFlow",
            "inputs": {"model": model_ref, "shift": Z_SHIFT},
        },
        "pos": {
            "class_type": "CLIPTextEncode",
            "inputs": {"text": prompt, "clip": ["clip", 0]},
        },
        "latent": {
            "class_type": "EmptySD3LatentImage",
            "inputs": {"width": width, "height": height, "batch_size": batch},
        },
    }

    # At cfg 1 the negative branch is never evaluated, so zeroing it out is
    # both correct and cheaper. Above cfg 1 (base Z-Image, 30-50 steps) a real
    # negative prompt starts to matter.
    if cfg > 1.0:
        g["neg"] = {
            "class_type": "CLIPTextEncode",
            "inputs": {"text": negative, "clip": ["clip", 0]},
        }
        neg_ref = ["neg", 0]
    else:
        g["neg"] = {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["pos", 0]}}
        neg_ref = ["neg", 0]

    g["sampler"] = {
        "class_type": "KSampler",
        "inputs": {
            "seed": seed,
            "steps": steps,
            "cfg": cfg,
            "sampler_name": "res_multistep",
            "scheduler": "simple",
            "denoise": 1.0,
            "model": ["shift", 0],
            "positive": ["pos", 0],
            "negative": neg_ref,
            "latent_image": ["latent", 0],
        },
    }
    g["decode"] = {
        "class_type": "VAEDecode",
        "inputs": {"samples": ["sampler", 0], "vae": ["vae", 0]},
    }
    return _finish(g, ["decode", 0], filename_prefix, transparent)


def _sdxl_graph(
    *,
    prompt: str,
    negative: str,
    seed: int,
    width: int,
    height: int,
    batch: int,
    checkpoint: str,
    loras: list[tuple[str, float, float]],  # (name, model_strength, clip_strength)
    filename_prefix: str,
    transparent: bool,
    steps: int = 28,
    cfg: float = 6.5,
) -> dict[str, Any]:
    g: dict[str, dict] = {
        "ckpt": {
            "class_type": "CheckpointLoaderSimple",
            "inputs": {"ckpt_name": checkpoint},
        },
        "latent": {
            "class_type": "EmptyLatentImage",
            "inputs": {"width": width, "height": height, "batch_size": batch},
        },
    }

    model_ref: list = ["ckpt", 0]
    clip_ref: list = ["ckpt", 1]
    vae_ref: list = ["ckpt", 2]

    for idx, (name, ms, cs) in enumerate(loras):
        node = f"lora_{idx}"
        g[node] = {
            "class_type": "LoraLoader",
            "inputs": {
                "lora_name": name,
                "strength_model": ms,
                "strength_clip": cs,
                "model": model_ref,
                "clip": clip_ref,
            },
        }
        model_ref = [node, 0]
        clip_ref = [node, 1]

    g["pos"] = {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": clip_ref}}
    g["neg"] = {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": clip_ref}}
    g["sampler"] = {
        "class_type": "KSampler",
        "inputs": {
            "seed": seed,
            "steps": steps,
            "cfg": cfg,
            "sampler_name": "dpmpp_2m",
            "scheduler": "karras",
            "denoise": 1.0,
            "model": model_ref,
            "positive": ["pos", 0],
            "negative": ["neg", 0],
            "latent_image": ["latent", 0],
        },
    }
    g["decode"] = {
        "class_type": "VAEDecode",
        "inputs": {"samples": ["sampler", 0], "vae": vae_ref},
    }
    return _finish(g, ["decode", 0], filename_prefix, transparent)


def _layered_graph(
    *,
    prompt: str,
    negative: str,
    seed: int,
    width: int,
    height: int,
    layers: int,
    batch: int,
    filename_prefix: str,
    steps: int = 20,
    cfg: float = 2.5,
) -> dict[str, Any]:
    """Qwen-Image-Layered text-to-layers: one prompt, N stacked RGBA images."""
    g: dict[str, dict] = {
        "unet": {
            "class_type": "UNETLoader",
            "inputs": {"unet_name": LAYERED_UNET, "weight_dtype": "default"},
        },
        "clip": {
            "class_type": "CLIPLoader",
            "inputs": {"clip_name": LAYERED_CLIP, "type": "qwen_image", "device": "default"},
        },
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": LAYERED_VAE}},
        # shift 1 here, unlike Z-Image's 3 — taken from the upstream template.
        "shift": {
            "class_type": "ModelSamplingAuraFlow",
            "inputs": {"model": ["unet", 0], "shift": 1.0},
        },
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["clip", 0]}},
        "neg": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["clip", 0]}},
        "latent": {
            "class_type": "EmptyQwenImageLayeredLatentImage",
            "inputs": {
                "width": width,
                "height": height,
                "layers": layers,
                "batch_size": batch,
            },
        },
        "sampler": {
            "class_type": "KSampler",
            "inputs": {
                "seed": seed,
                "steps": steps,
                "cfg": cfg,
                "sampler_name": "euler",
                "scheduler": "simple",
                "denoise": 1.0,
                "model": ["shift", 0],
                "positive": ["pos", 0],
                "negative": ["neg", 0],
                "latent_image": ["latent", 0],
            },
        },
        # The layer stack comes back on the temporal axis; cutting it to a
        # batch is what turns it into one RGBA image per layer.
        "cut": {
            "class_type": "LatentCutToBatch",
            "inputs": {"samples": ["sampler", 0], "dim": "t", "slice_size": 1},
        },
        "decode": {
            "class_type": "VAEDecode",
            "inputs": {"samples": ["cut", 0], "vae": ["vae", 0]},
        },
    }
    # Layers arrive with alpha already — matting here would only damage them.
    return _finish(g, ["decode", 0], filename_prefix, False)


def _ideogram_graph(
    *,
    prompt: str,
    negative: str,
    seed: int,
    width: int,
    height: int,
    batch: int,
    filename_prefix: str,
    transparent: bool,
    steps: int = 20,
    cfg: float = 7.0,
    mu: float = 0.0,
    std: float = 1.75,
) -> dict[str, Any]:
    """Ideogram 4: dual-model guidance + its own sigma schedule."""
    del negative  # guidance uses the unconditional model, not a negative prompt
    g: dict[str, dict] = {
        "unet": {
            "class_type": "UNETLoader",
            "inputs": {"unet_name": IDEOGRAM_UNET, "weight_dtype": "default"},
        },
        "unet_uncond": {
            "class_type": "UNETLoader",
            "inputs": {"unet_name": IDEOGRAM_UNET_UNCOND, "weight_dtype": "default"},
        },
        "clip": {
            "class_type": "CLIPLoader",
            "inputs": {"clip_name": IDEOGRAM_CLIP, "type": "ideogram4", "device": "default"},
        },
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": IDEOGRAM_VAE}},
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["clip", 0]}},
        "neg": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["pos", 0]}},
        "guider": {
            "class_type": "DualModelGuider",
            "inputs": {
                "model": ["unet", 0],
                "positive": ["pos", 0],
                "model_negative": ["unet_uncond", 0],
                "negative": ["neg", 0],
                "cfg": cfg,
            },
        },
        # Presets from the upstream template: Turbo 12 steps (mu 0.5),
        # Default 20 (mu 0.0), Quality 48 (std 1.5).
        "sigmas": {
            "class_type": "Ideogram4Scheduler",
            "inputs": {
                "steps": steps,
                "width": width,
                "height": height,
                "mu": mu,
                "std": std,
            },
        },
        "sampler_sel": {"class_type": "KSamplerSelect", "inputs": {"sampler_name": "euler"}},
        "noise": {"class_type": "RandomNoise", "inputs": {"noise_seed": seed}},
        "latent": {
            "class_type": "EmptyFlux2LatentImage",
            "inputs": {"width": width, "height": height, "batch_size": batch},
        },
        "adv": {
            "class_type": "SamplerCustomAdvanced",
            "inputs": {
                "noise": ["noise", 0],
                "guider": ["guider", 0],
                "sampler": ["sampler_sel", 0],
                "sigmas": ["sigmas", 0],
                "latent_image": ["latent", 0],
            },
        },
        "decode": {
            "class_type": "VAEDecode",
            "inputs": {"samples": ["adv", 0], "vae": ["vae", 0]},
        },
    }
    return _finish(g, ["decode", 0], filename_prefix, transparent)


def _refine_graph(
    *,
    image_name: str,
    prompt: str,
    seed: int,
    denoise: float,
    scale: float,
    filename_prefix: str,
    transparent: bool,
    steps: int = Z_STEPS,
) -> dict[str, Any]:
    """Upscale then re-diffuse at low denoise — Z-Image adds detail cheaply."""
    g: dict[str, dict] = {
        "unet": {
            "class_type": "UNETLoader",
            "inputs": {"unet_name": Z_UNET, "weight_dtype": "default"},
        },
        "clip": {
            "class_type": "CLIPLoader",
            "inputs": {"clip_name": Z_CLIP, "type": "lumina2", "device": "default"},
        },
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": Z_VAE}},
        "shift": {
            "class_type": "ModelSamplingAuraFlow",
            "inputs": {"model": ["unet", 0], "shift": Z_SHIFT},
        },
        "load": {"class_type": "LoadImage", "inputs": {"image": image_name}},
        "upscale": {
            "class_type": "ImageScaleBy",
            "inputs": {"image": ["load", 0], "upscale_method": "lanczos", "scale_by": scale},
        },
        "encode": {
            "class_type": "VAEEncode",
            "inputs": {"pixels": ["upscale", 0], "vae": ["vae", 0]},
        },
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["clip", 0]}},
        "neg": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["pos", 0]}},
        "sampler": {
            "class_type": "KSampler",
            "inputs": {
                "seed": seed,
                "steps": steps,
                "cfg": Z_CFG,
                "sampler_name": "res_multistep",
                "scheduler": "simple",
                "denoise": denoise,
                "model": ["shift", 0],
                "positive": ["pos", 0],
                "negative": ["neg", 0],
                "latent_image": ["encode", 0],
            },
        },
        "decode": {
            "class_type": "VAEDecode",
            "inputs": {"samples": ["sampler", 0], "vae": ["vae", 0]},
        },
    }
    return _finish(g, ["decode", 0], filename_prefix, transparent)


async def _submit_and_wait(workflow: dict[str, Any]) -> list[Path]:
    """Submit a workflow, wait for completion, download the results."""
    client_id = str(uuid.uuid4())
    async with httpx.AsyncClient(timeout=60.0) as http:
        resp = await http.post(
            f"{COMFY_URL}/prompt",
            json={"prompt": workflow, "client_id": client_id},
        )
        if resp.status_code == 400:
            # ComfyUI returns a structured validation error here — surfacing it
            # verbatim is the difference between "it failed" and "lora_name
            # 'foo.safetensors' not in list".
            raise RuntimeError(f"ComfyUI rejected the workflow: {resp.text}")
        resp.raise_for_status()
        prompt_id = resp.json()["prompt_id"]

        ws_url = COMFY_URL.replace("http", "ws") + f"/ws?clientId={client_id}"
        async with websockets.connect(ws_url, max_size=None) as ws:
            async with asyncio.timeout(JOB_TIMEOUT):
                while True:
                    msg = await ws.recv()
                    if isinstance(msg, bytes):  # preview frames
                        continue
                    data = json.loads(msg)
                    payload = data.get("data", {})
                    if payload.get("prompt_id") not in (None, prompt_id):
                        continue
                    if data.get("type") == "execution_error":
                        raise RuntimeError(
                            f"{payload.get('node_type')}: {payload.get('exception_message')}"
                        )
                    if data.get("type") in ("execution_interrupted", "execution_cached_error"):
                        raise RuntimeError(f"execution interrupted: {payload}")
                    # node None on an `executing` message == queue drained
                    if data.get("type") == "executing" and payload.get("node") is None:
                        break

        hist = (await http.get(f"{COMFY_URL}/history/{prompt_id}")).json()
        outputs = hist.get(prompt_id, {}).get("outputs", {})
        saved: list[Path] = []
        stamp = int(time.time())
        for node_out in outputs.values():
            for img in node_out.get("images", []):
                params = {
                    "filename": img["filename"],
                    "subfolder": img.get("subfolder", ""),
                    "type": img.get("type", "output"),
                }
                r = await http.get(f"{COMFY_URL}/view", params=params)
                r.raise_for_status()
                dest = OUTPUT_DIR / f"{stamp}-{img['filename']}"
                dest.write_bytes(r.content)
                saved.append(dest)
        if not saved:
            raise RuntimeError("workflow completed but produced no images")
        return saved


async def _upload(path: Path) -> str:
    """Push a local file into ComfyUI's input dir; returns its LoadImage name."""
    if not path.is_file():
        raise FileNotFoundError(path)
    mime = mimetypes.guess_type(path.name)[0] or "image/png"
    async with httpx.AsyncClient(timeout=60.0) as http:
        r = await http.post(
            f"{COMFY_URL}/upload/image",
            files={"image": (path.name, path.read_bytes(), mime)},
            data={"overwrite": "true"},
        )
        r.raise_for_status()
        body = r.json()
        sub = body.get("subfolder") or ""
        return f"{sub}/{body['name']}" if sub else body["name"]


def _result(paths: list[Path], seed: int, **extra: Any) -> dict[str, Any]:
    return {
        "paths": [str(p) for p in paths],
        "path": str(paths[0]),
        "seed": seed,
        **extra,
    }


@mcp.tool()
async def generate_icon(
    prompt: str,
    style: str = "fantasy rpg",
    seed: int | None = None,
    transparent: bool = True,
    variants: int = 1,
    backend: str = "sdxl",
) -> dict[str, Any]:
    """Generate a game icon (item, ability, status effect).

    Args:
        prompt: Subject of the icon, e.g. "fire potion", "lightning sword".
        style: Visual style, e.g. "fantasy rpg", "sci-fi", "pixel art".
        seed: Reproducibility seed. Random if omitted. With variants > 1 the
            batch walks seed, seed+1, ...
        transparent: Cut the background with BiRefNet and save RGBA.
        variants: How many images to render in one batch.
        backend: "sdxl" keeps the 3d-icon LoRA look; "zimage" is faster and
            follows complex prompts better but ignores LoRAs.
    """
    s = _seed(seed)
    full_prompt = (
        f"game icon, {prompt}, {style} style, centered, single object, "
        "studio lighting, plain dark background, sharp details, high contrast"
    )
    negative = (
        "text, watermark, blurry, multiple objects, frame, border, "
        "low quality, jpeg artifacts"
    )
    common = dict(
        prompt=full_prompt,
        negative=negative,
        seed=s,
        width=1024,
        height=1024,
        batch=variants,
        filename_prefix="icon",
        transparent=transparent,
    )
    wf = (
        _zimage_graph(**common)
        if backend == "zimage"
        else _sdxl_graph(
            **common,
            checkpoint=DEFAULT_CHECKPOINT,
            loras=[(DEFAULT_ICON_LORA, 0.8, 1.0)],
        )
    )
    return _result(await _submit_and_wait(wf), s, transparent=transparent, backend=backend)


@mcp.tool()
async def generate_sprite(
    prompt: str,
    pose: str = "idle, front view",
    seed: int | None = None,
    transparent: bool = True,
    variants: int = 1,
) -> dict[str, Any]:
    """Generate a pixel-art character sprite (SDXL + pixel-art LoRA).

    Args:
        prompt: Character description, e.g. "wizard with red robe and staff".
        pose: Pose/orientation, e.g. "idle, front view", "walking, side view".
        seed: Reproducibility seed.
        transparent: Cut the background with BiRefNet and save RGBA.
        variants: How many images to render in one batch. Useful for picking
            a pose from a sheet of candidates.
    """
    s = _seed(seed)
    full_prompt = (
        f"pixel art sprite, {prompt}, {pose}, full body, centered, "
        "plain flat background, clean pixel art, limited palette, crisp pixels"
    )
    negative = "blurry, anti-aliased, photorealistic, 3d render, watermark, text"
    wf = _sdxl_graph(
        prompt=full_prompt,
        negative=negative,
        seed=s,
        width=1024,
        height=1024,
        batch=variants,
        checkpoint=DEFAULT_CHECKPOINT,
        loras=[(DEFAULT_PIXEL_LORA, 1.0, 1.0)],
        filename_prefix="sprite",
        transparent=transparent,
    )
    return _result(await _submit_and_wait(wf), s, transparent=transparent)


@mcp.tool()
async def generate_background(
    prompt: str,
    biome: str = "fantasy forest",
    aspect: str = "landscape",
    seed: int | None = None,
    variants: int = 1,
) -> dict[str, Any]:
    """Generate a scene/parallax background (Z-Image-Turbo).

    Args:
        prompt: Scene description.
        biome: Setting, e.g. "fantasy forest", "cyberpunk city", "desert".
        aspect: "landscape" 1536x1024, "portrait" 1024x1536, "square" 1024,
            or "wide" 1536x640 for parallax strips.
        seed: Reproducibility seed.
        variants: How many images to render in one batch.
    """
    s = _seed(seed)
    w, h = _dims(aspect)
    full_prompt = (
        f"{biome} background, {prompt}, atmospheric, painterly, depth, "
        "parallax-friendly composition, no characters, no text"
    )
    wf = _zimage_graph(
        prompt=full_prompt,
        negative="characters, people, text, watermark, ui elements, low quality",
        seed=s,
        width=w,
        height=h,
        batch=variants,
        filename_prefix="bg",
        transparent=False,
    )
    return _result(await _submit_and_wait(wf), s, size=[w, h])


@mcp.tool()
async def generate_ui_panel(
    prompt: str,
    style: str = "ornate fantasy",
    seed: int | None = None,
    transparent: bool = True,
    variants: int = 1,
) -> dict[str, Any]:
    """Generate a UI panel/frame/dialog-box element (Z-Image-Turbo).

    Caveat: diffusion models still struggle with structural UI. Output is
    reference art, not ship-ready chrome — expect hand cleanup.
    """
    s = _seed(seed)
    full_prompt = (
        f"game ui panel frame, {prompt}, {style} style, centered, symmetrical, "
        "plain dark background, high contrast, decorative border"
    )
    wf = _zimage_graph(
        prompt=full_prompt,
        negative="text, characters, blurry, asymmetric, low quality",
        seed=s,
        width=1024,
        height=768,
        batch=variants,
        filename_prefix="ui",
        transparent=transparent,
    )
    return _result(await _submit_and_wait(wf), s, transparent=transparent)


@mcp.tool()
async def generate_image(
    prompt: str,
    negative: str = "",
    width: int = 1024,
    height: int = 1024,
    seed: int | None = None,
    steps: int | None = None,
    cfg: float | None = None,
    variants: int = 1,
    transparent: bool = False,
    backend: str = "zimage",
    lora: str = "",
    lora_strength: float = 1.0,
) -> dict[str, Any]:
    """Unopinionated render — no prompt templating, full control of sampling.

    Use when the tuned tools get in the way. backend "zimage" (default) runs
    Z-Image-Turbo at 8 steps / cfg 1; "zimage-hq" is the non-distilled model at
    30 steps / cfg 4; "ideogram" for text; "sdxl" for the SDXL LoRA stack.

    Args:
        lora: A LoRA from `list_loras` to stack on the Z-Image backends — this
            is how a style LoRA built by `lora-train` gets used. Ignored by the
            sdxl and ideogram backends.
        lora_strength: 1.0 is the trained strength; drop to 0.6-0.8 if the
            style is overpowering the subject.
    """
    s = _seed(seed)
    common = dict(
        prompt=prompt,
        negative=negative,
        seed=s,
        width=width,
        height=height,
        batch=variants,
        filename_prefix="gen",
        transparent=transparent,
    )
    override: dict[str, Any] = {}
    if steps:
        override["steps"] = steps
    if cfg:
        override["cfg"] = cfg

    z_loras = [(lora, lora_strength)] if lora else None

    if backend == "sdxl":
        wf = _sdxl_graph(**common, checkpoint=DEFAULT_CHECKPOINT, loras=[], **override)
    elif backend == "zimage-hq":
        # Non-distilled Z-Image: needs real guidance and ~4x the steps.
        wf = _zimage_graph(
            **common,
            unet=Z_BASE_UNET,
            loras=z_loras,
            **{"steps": Z_BASE_STEPS, "cfg": Z_BASE_CFG, **override},
        )
    elif backend == "ideogram":
        wf = _ideogram_graph(**common, **override)
    else:
        wf = _zimage_graph(**common, loras=z_loras, **override)
    return _result(await _submit_and_wait(wf), s, backend=backend)


@mcp.tool()
async def cutout(image_path: str) -> dict[str, Any]:
    """Alpha-cut an existing image file with BiRefNet; returns a new RGBA PNG.

    Works on any image, including art produced outside this server.
    """
    name = await _upload(Path(image_path).expanduser())
    g: dict[str, dict] = {
        "load": {"class_type": "LoadImage", "inputs": {"image": name}},
    }
    _finish(g, ["load", 0], "cutout", True)
    paths = await _submit_and_wait(g)
    return {"paths": [str(p) for p in paths], "path": str(paths[0]), "source": image_path}


@mcp.tool()
async def generate_layered(
    prompt: str,
    layers: int = 2,
    width: int = 1024,
    height: int = 1024,
    seed: int | None = None,
) -> dict[str, Any]:
    """Generate an image already split into separate RGBA layers.

    Qwen-Image-Layered emits each element as its own transparent image
    (background, subject, effects, ...) instead of one flat render. Use it when
    the asset needs to be recomposed or animated per element — a glowing sword
    whose glow is its own layer, a parallax plate set, an icon plus its base.

    Args:
        prompt: Scene description. Say what belongs on which layer.
        layers: How many layers to decompose into (2-8; more layers = slower).
        width/height: Layer size. 640-1024 is the sweet spot.
        seed: Reproducibility seed.

    Returns paths in layer order, back to front.
    """
    s = _seed(seed)
    wf = _layered_graph(
        prompt=prompt,
        negative="",
        seed=s,
        width=width,
        height=height,
        layers=layers,
        batch=1,
        filename_prefix="layered",
    )
    paths = await _submit_and_wait(wf)
    return _result(paths, s, layers=len(paths))


@mcp.tool()
async def generate_text_art(
    prompt: str,
    text: str = "",
    aspect: str = "square",
    seed: int | None = None,
    quality: str = "default",
    transparent: bool = False,
    variants: int = 1,
) -> dict[str, Any]:
    """Generate art containing readable text — logos, signage, banners, cards.

    Runs Ideogram 4, the only local model here that renders legible glyphs.
    Diffusion still garbles long strings: keep `text` short and check it.

    Args:
        prompt: What the piece looks like.
        text: The exact string that must appear in the image.
        aspect: "square", "landscape", "portrait", "wide".
        seed: Reproducibility seed.
        quality: "turbo" (12 steps), "default" (20), "quality" (48).
        transparent: Alpha-cut the result with BiRefNet.
        variants: How many to render in one batch.
    """
    s = _seed(seed)
    w, h = (1024, 1024) if aspect == "square" else _dims(aspect)
    preset = {
        "turbo": (12, 0.5, 1.75),
        "quality": (48, 0.0, 1.5),
    }.get(quality, (20, 0.0, 1.75))
    full_prompt = f'{prompt}, with the text "{text}" rendered clearly' if text else prompt
    wf = _ideogram_graph(
        prompt=full_prompt,
        negative="",
        seed=s,
        width=w,
        height=h,
        batch=variants,
        filename_prefix="text",
        transparent=transparent,
        steps=preset[0],
        mu=preset[1],
        std=preset[2],
    )
    return _result(await _submit_and_wait(wf), s, size=[w, h], quality=quality)


@mcp.tool()
async def refine(
    image_path: str,
    prompt: str = "",
    scale: float = 2.0,
    denoise: float = 0.35,
    seed: int | None = None,
    transparent: bool = False,
) -> dict[str, Any]:
    """Upscale an image and re-diffuse it lightly to add real detail.

    Cheaper and sharper than generating at high resolution directly. Denoise
    0.2-0.3 preserves composition, 0.4-0.5 lets it reinterpret detail.

    Args:
        image_path: Existing image, from these tools or anywhere else.
        prompt: Optional description to steer the added detail.
        scale: Upscale factor before the pass.
        denoise: How much freedom the model gets.
        seed: Reproducibility seed.
        transparent: Re-cut alpha afterwards (the pass loses the old alpha).
    """
    s = _seed(seed)
    name = await _upload(Path(image_path).expanduser())
    wf = _refine_graph(
        image_name=name,
        prompt=prompt,
        seed=s,
        denoise=denoise,
        scale=scale,
        filename_prefix="refined",
        transparent=transparent,
    )
    return _result(await _submit_and_wait(wf), s, source=image_path, scale=scale)


async def _score(path: Path, criteria: str) -> dict[str, Any]:
    """Ask the local VLM to score one image against a brief."""
    b64 = base64.b64encode(path.read_bytes()).decode()
    payload = {
        "model": VLM_MODEL,
        "stream": False,
        "format": {
            "type": "object",
            "properties": {
                "score": {"type": "number"},
                "notes": {"type": "string"},
            },
            "required": ["score", "notes"],
        },
        "messages": [
            {
                "role": "user",
                "content": (
                    "Score this game-art asset from 0 to 10 against the brief. "
                    "Judge subject accuracy, silhouette readability at small size, "
                    "clean edges, and absence of artefacts or stray text. "
                    f"Brief: {criteria}. Reply with score and one line of notes."
                ),
                "images": [b64],
            }
        ],
    }
    async with httpx.AsyncClient(timeout=300.0) as http:
        r = await http.post(f"{OLLAMA_URL}/api/chat", json=payload)
        r.raise_for_status()
        body = json.loads(r.json()["message"]["content"])
    return {"path": str(path), "score": float(body.get("score", 0)), "notes": body.get("notes", "")}


@mcp.tool()
async def critique(image_paths: list[str], criteria: str) -> list[dict[str, Any]]:
    """Rank images with the local vision model, best first.

    Runs on Ollama (qwen3-vl), so it costs nothing and leaves no trace of the
    art. Useful on its own for reviewing hand-made assets too.
    """
    scored = await asyncio.gather(
        *(_score(Path(p).expanduser(), criteria) for p in image_paths)
    )
    return sorted(scored, key=lambda d: d["score"], reverse=True)


@mcp.tool()
async def generate_best(
    prompt: str,
    kind: str = "background",
    n: int = 4,
    criteria: str = "",
    seed: int | None = None,
) -> dict[str, Any]:
    """Render n candidates, have the VLM judge them, return the winner.

    Diffusion output varies wildly seed to seed; this spends cheap GPU time to
    save the round trip of a human sifting four files.

    Args:
        prompt: Passed to the underlying generator.
        kind: "background", "icon", "sprite", "ui_panel", or "text".
        n: How many candidates to render.
        criteria: What "good" means here. Defaults to the prompt.
        seed: Base seed for the batch.
    """
    gen = {
        "background": lambda: generate_background(prompt, seed=seed, variants=n),
        "icon": lambda: generate_icon(prompt, seed=seed, variants=n),
        "sprite": lambda: generate_sprite(prompt, seed=seed, variants=n),
        "ui_panel": lambda: generate_ui_panel(prompt, seed=seed, variants=n),
        "text": lambda: generate_text_art(prompt, seed=seed, variants=n),
    }.get(kind)
    if gen is None:
        raise ValueError(f"unknown kind {kind!r}")
    batch = await gen()
    ranked = await critique(batch["paths"], criteria or prompt)
    return {
        "path": ranked[0]["path"],
        "score": ranked[0]["score"],
        "notes": ranked[0]["notes"],
        "ranked": ranked,
        "seed": batch["seed"],
    }


def _load_palettes() -> dict[str, dict[str, Any]]:
    with PALETTES_PATH.open() as fh:
        return {k: v for k, v in json.load(fh).items() if not k.startswith("_")}


def _srgb_to_lab(rgb: "np.ndarray") -> "np.ndarray":
    """sRGB 0-255 → CIE Lab. Nearest-colour in Lab tracks perceived hue far
    better than RGB distance, which is what keeps hue-shifted ramps intact."""
    srgb = rgb.astype(np.float64) / 255.0
    lin = np.where(srgb <= 0.04045, srgb / 12.92, ((srgb + 0.055) / 1.055) ** 2.4)
    m = np.array(
        [
            [0.4124564, 0.3575761, 0.1804375],
            [0.2126729, 0.7151522, 0.0721750],
            [0.0193339, 0.1191920, 0.9503041],
        ]
    )
    xyz = lin @ m.T
    white = np.array([0.95047, 1.0, 1.08883])
    t = xyz / white
    f = np.where(t > 0.008856, np.cbrt(t), 7.787 * t + 16 / 116)
    return np.stack(
        [116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])],
        axis=-1,
    )


def _conform(img: "Image.Image", palette: list[str]) -> "Image.Image":
    """Map every pixel to its nearest palette entry, preserving alpha."""
    rgba = img.convert("RGBA")
    arr = np.array(rgba)
    rgb, alpha = arr[..., :3], arr[..., 3]

    pal_rgb = np.array([[int(h[i : i + 2], 16) for i in (1, 3, 5)] for h in palette])
    d = _srgb_to_lab(rgb.reshape(-1, 3))[:, None, :] - _srgb_to_lab(pal_rgb)[None, :, :]
    nearest = np.argmin((d**2).sum(axis=-1), axis=1)

    out = pal_rgb[nearest].reshape(rgb.shape).astype(np.uint8)
    return Image.fromarray(np.dstack([out, alpha]), "RGBA")


@mcp.tool()
async def list_palettes() -> dict[str, str]:
    """List available named palettes and what each is for."""
    return {k: v.get("description", "") for k, v in _load_palettes().items()}


@mcp.tool()
async def conform_palette(
    image_path: str,
    palette: str = "apollo",
    output_path: str | None = None,
) -> dict[str, Any]:
    """Snap an image to a fixed palette (default Apollo's 46 colours).

    Prompting cannot enforce a palette; this can. Run it as the last step on
    anything that has to sit next to existing art without clashing.

    Args:
        image_path: Image to convert.
        palette: Name from `list_palettes`.
        output_path: Where to write. Defaults to alongside the source.
    """
    palettes = _load_palettes()
    if palette not in palettes:
        raise ValueError(f"unknown palette {palette!r}; have {sorted(palettes)}")
    src = Path(image_path).expanduser()
    out = Path(output_path).expanduser() if output_path else src.with_name(f"{src.stem}-{palette}.png")
    result = _conform(Image.open(src), palettes[palette]["colors"])
    result.save(out)
    return {"path": str(out), "palette": palette, "colors": len(palettes[palette]["colors"])}


@mcp.tool()
async def pixelize(
    image_path: str,
    target_px: int = 32,
    palette: str = "apollo",
    upscale: int = 1,
    output_path: str | None = None,
) -> dict[str, Any]:
    """Turn a smooth render into a true pixel-art sprite on a fixed grid.

    Downsamples to `target_px` on its longest side with box averaging (so
    detail merges instead of aliasing), snaps to the palette, then optionally
    nearest-neighbour upscales for viewing. Evergreen's grid: 16 for terrain
    tiles and small props, 24 bushes, 32 trees and NPCs, 48 player scale.

    Args:
        image_path: Render to convert.
        target_px: Longest-side size of the real sprite, in pixels.
        palette: Name from `list_palettes`; pass "" to skip palette snapping.
        upscale: Nearest-neighbour zoom applied after conversion (1 = none).
        output_path: Where to write. Defaults to alongside the source.
    """
    src = Path(image_path).expanduser()
    img = Image.open(src).convert("RGBA")

    scale = target_px / max(img.size)
    small = img.resize(
        (max(1, round(img.width * scale)), max(1, round(img.height * scale))),
        Image.BOX,
    )
    # Averaging leaves semi-transparent fringes; a hard threshold keeps sprite
    # edges crisp instead of softly haloed against the engine background.
    a = np.array(small)[..., 3]
    if a.min() < 255:
        arr = np.array(small)
        arr[..., 3] = np.where(a >= 128, 255, 0)
        small = Image.fromarray(arr, "RGBA")

    if palette:
        palettes = _load_palettes()
        if palette not in palettes:
            raise ValueError(f"unknown palette {palette!r}; have {sorted(palettes)}")
        small = _conform(small, palettes[palette]["colors"])

    final = (
        small.resize((small.width * upscale, small.height * upscale), Image.NEAREST)
        if upscale > 1
        else small
    )
    out = Path(output_path).expanduser() if output_path else src.with_name(f"{src.stem}-{target_px}px.png")
    final.save(out)
    return {
        "path": str(out),
        "sprite_size": list(small.size),
        "saved_size": list(final.size),
        "palette": palette or None,
    }


@mcp.tool()
async def make_tileable(
    image_path: str,
    seed: int | None = None,
    band: float = 0.18,
    output_path: str | None = None,
) -> dict[str, Any]:
    """Make a texture wrap seamlessly: offset by half, then inpaint the seam.

    Core ComfyUI has no circular-padding node, so this is the way to get a
    genuinely seamless source texture locally. The image is rolled 50% in both
    axes (which moves the four edges into a cross through the middle), SDXL
    inpaints that cross away, and the result tiles cleanly as-is.

    Args:
        image_path: Texture to fix, ideally 1024px and fairly uniform.
        seed: Reproducibility seed.
        band: Width of the repainted cross as a fraction of the image.
        output_path: Where to write the seamless texture.
    """
    s = _seed(seed)
    src = Path(image_path).expanduser()
    img = Image.open(src).convert("RGB")
    w, h = img.size

    rolled = Image.fromarray(np.roll(np.array(img), (h // 2, w // 2), axis=(0, 1)))
    half = max(2, int(min(w, h) * band / 2))
    mask = np.zeros((h, w), dtype=np.uint8)
    mask[h // 2 - half : h // 2 + half, :] = 255
    mask[:, w // 2 - half : w // 2 + half] = 255

    tmp = OUTPUT_DIR / f"_tileable-{s}.png"
    tmp_mask = OUTPUT_DIR / f"_tileable-mask-{s}.png"
    rolled.save(tmp)
    Image.fromarray(mask, "L").save(tmp_mask)
    img_name = await _upload(tmp)
    mask_name = await _upload(tmp_mask)

    g: dict[str, dict] = {
        "ckpt": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": DEFAULT_CHECKPOINT}},
        "load": {"class_type": "LoadImage", "inputs": {"image": img_name}},
        "load_mask": {"class_type": "LoadImage", "inputs": {"image": mask_name}},
        "mask": {"class_type": "ImageToMask", "inputs": {"image": ["load_mask", 0], "channel": "red"}},
        "pos": {
            "class_type": "CLIPTextEncode",
            "inputs": {"text": "seamless repeating texture, uniform, no seams", "clip": ["ckpt", 1]},
        },
        "neg": {
            "class_type": "CLIPTextEncode",
            "inputs": {"text": "seam, line, border, edge, discontinuity", "clip": ["ckpt", 1]},
        },
        "latent": {
            "class_type": "VAEEncodeForInpaint",
            "inputs": {
                "pixels": ["load", 0],
                "vae": ["ckpt", 2],
                "mask": ["mask", 0],
                # Feathering the mask lets the repaint blend into the texture
                # instead of leaving a second, softer seam where it stops.
                "grow_mask_by": 12,
            },
        },
        "sampler": {
            "class_type": "KSampler",
            "inputs": {
                "seed": s,
                "steps": 24,
                "cfg": 6.0,
                "sampler_name": "dpmpp_2m",
                "scheduler": "karras",
                "denoise": 1.0,
                "model": ["ckpt", 0],
                "positive": ["pos", 0],
                "negative": ["neg", 0],
                "latent_image": ["latent", 0],
            },
        },
        "decode": {"class_type": "VAEDecode", "inputs": {"samples": ["sampler", 0], "vae": ["ckpt", 2]}},
        "save": {"class_type": "SaveImage", "inputs": {"filename_prefix": "tileable", "images": ["decode", 0]}},
    }
    paths = await _submit_and_wait(g)
    result = paths[0]
    if output_path:
        result = Path(output_path).expanduser()
        Image.open(paths[0]).save(result)
    return {"path": str(result), "seed": s}


@mcp.tool()
async def edit_image(
    image_path: str,
    instruction: str,
    seed: int | None = None,
    steps: int = 40,
    cfg: float = 3.0,
    lora: str = "",
    lora_strength: float = 1.0,
    reference_2: str = "",
    output_path: str | None = None,
) -> dict[str, Any]:
    """Edit an existing image by instruction, keeping the subject's identity.

    Qwen-Image-Edit 2511. This is what makes local character work viable:
    text-to-image re-invents a character every seed, but an edit conditioned on
    the original keeps it. Use it for turnarounds ("same character, side view"),
    palette swaps, equipment changes, and animation key poses.

    Args:
        image_path: The image to edit — the identity source.
        instruction: What to change, e.g. "show the same character from the
            side, facing left, same outfit and colours".
        seed: Reproducibility seed.
        steps: 40 at cfg 3 is the upstream default.
        cfg: Guidance. Drop to 1.0 with a Lightning LoRA.
        lora: Optional edit LoRA, e.g. the multiple-angles one for turnarounds.
        lora_strength: LoRA weight.
        reference_2: Optional second reference image (style or target object).
        output_path: Where to write the result.
    """
    s = _seed(seed)
    img_name = await _upload(Path(image_path).expanduser())

    g: dict[str, dict] = {
        "unet": {
            "class_type": "UNETLoader",
            "inputs": {"unet_name": EDIT_UNET, "weight_dtype": "default"},
        },
        "clip": {
            "class_type": "CLIPLoader",
            "inputs": {"clip_name": LAYERED_CLIP, "type": "qwen_image", "device": "default"},
        },
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": EDIT_VAE}},
        "load": {"class_type": "LoadImage", "inputs": {"image": img_name}},
        # Snaps the reference to a resolution the edit model was trained on.
        "scale": {"class_type": "FluxKontextImageScale", "inputs": {"image": ["load", 0]}},
    }

    model_ref: list = ["unet", 0]
    if lora:
        g["lora"] = {
            "class_type": "LoraLoaderModelOnly",
            "inputs": {"lora_name": lora, "strength_model": lora_strength, "model": model_ref},
        }
        model_ref = ["lora", 0]

    g["shift"] = {
        "class_type": "ModelSamplingAuraFlow",
        "inputs": {"model": model_ref, "shift": 3.1},
    }
    # CFGNorm keeps the edit from drifting in contrast across the guidance pass.
    g["cfgnorm"] = {"class_type": "CFGNorm", "inputs": {"model": ["shift", 0], "strength": 1.0}}

    pos_inputs: dict[str, Any] = {
        "clip": ["clip", 0],
        "prompt": instruction,
        "vae": ["vae", 0],
        "image1": ["scale", 0],
    }
    if reference_2:
        ref_name = await _upload(Path(reference_2).expanduser())
        g["load2"] = {"class_type": "LoadImage", "inputs": {"image": ref_name}}
        g["scale2"] = {"class_type": "FluxKontextImageScale", "inputs": {"image": ["load2", 0]}}
        pos_inputs["image2"] = ["scale2", 0]

    g["pos"] = {"class_type": "TextEncodeQwenImageEditPlus", "inputs": pos_inputs}
    g["neg"] = {
        "class_type": "TextEncodeQwenImageEditPlus",
        "inputs": {"clip": ["clip", 0], "prompt": "", "vae": ["vae", 0], "image1": ["scale", 0]},
    }
    g["latent"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["scale", 0], "vae": ["vae", 0]}}
    g["sampler"] = {
        "class_type": "KSampler",
        "inputs": {
            "seed": s,
            "steps": steps,
            "cfg": cfg,
            "sampler_name": "euler",
            "scheduler": "simple",
            "denoise": 1.0,
            "model": ["cfgnorm", 0],
            "positive": ["pos", 0],
            "negative": ["neg", 0],
            "latent_image": ["latent", 0],
        },
    }
    g["decode"] = {"class_type": "VAEDecode", "inputs": {"samples": ["sampler", 0], "vae": ["vae", 0]}}
    g["save"] = {
        "class_type": "SaveImage",
        "inputs": {"filename_prefix": "edit", "images": ["decode", 0]},
    }

    paths = await _submit_and_wait(g)
    result = paths[0]
    if output_path:
        result = Path(output_path).expanduser()
        Image.open(paths[0]).save(result)
    return {"path": str(result), "seed": s, "source": image_path}


@mcp.tool()
async def slice_sheet(
    image_path: str,
    cols: int,
    rows: int = 1,
    output_dir: str | None = None,
    name: str = "frame",
) -> dict[str, Any]:
    """Cut a sheet into equal cells — turnaround sheets, animation strips, atlases."""
    src = Path(image_path).expanduser()
    img = Image.open(src).convert("RGBA")
    cw, ch = img.width // cols, img.height // rows
    out_dir = Path(output_dir).expanduser() if output_dir else src.parent / src.stem
    out_dir.mkdir(parents=True, exist_ok=True)

    paths = []
    for r in range(rows):
        for c in range(cols):
            cell = img.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
            p = out_dir / f"{name}_{r * cols + c:02d}.png"
            cell.save(p)
            paths.append(str(p))
    return {"paths": paths, "cell_size": [cw, ch], "count": len(paths)}


@mcp.tool()
async def contact_sheet(
    image_paths: list[str],
    cols: int = 5,
    cell_px: int = 384,
    output_path: str | None = None,
) -> dict[str, Any]:
    """Combine candidates into one numbered sheet for picking a winner.

    Returns the sheet path plus the index→path mapping, so "I like 3" resolves
    to a real file.
    """
    paths = [Path(p).expanduser() for p in image_paths]
    rows = (len(paths) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell_px, rows * cell_px), (24, 24, 28, 255))
    draw = ImageDraw.Draw(sheet)

    for i, p in enumerate(paths):
        im = Image.open(p).convert("RGBA")
        im.thumbnail((cell_px - 8, cell_px - 8), Image.LANCZOS)
        x, y = (i % cols) * cell_px, (i // cols) * cell_px
        sheet.paste(im, (x + (cell_px - im.width) // 2, y + (cell_px - im.height) // 2), im)
        label = str(i + 1)
        draw.rectangle([x + 4, y + 4, x + 30, y + 30], fill=(0, 0, 0, 200))
        draw.text((x + 12, y + 10), label, fill=(255, 255, 255, 255))

    out = Path(output_path).expanduser() if output_path else OUTPUT_DIR / f"contact-{int(time.time())}.png"
    sheet.save(out)
    return {"path": str(out), "index_to_path": {i + 1: str(p) for i, p in enumerate(paths)}}


@mcp.tool()
async def describe_style(image_path: str, focus: str = "") -> dict[str, Any]:
    """Extract reusable prompt fragments describing an image's *style*.

    The inverse of the LoRA captioner: here we want the palette, light, line and
    rendering language, not the subject. Feed the result back into the style
    preset so the next generation starts where the winner landed.
    """
    b64 = base64.b64encode(Path(image_path).expanduser().read_bytes()).decode()
    payload = {
        "model": VLM_MODEL,
        "stream": False,
        "format": {
            "type": "object",
            "properties": {
                "palette": {"type": "string"},
                "lighting": {"type": "string"},
                "linework": {"type": "string"},
                "rendering": {"type": "string"},
                "prompt_fragment": {"type": "string"},
            },
            "required": ["palette", "lighting", "linework", "rendering", "prompt_fragment"],
        },
        "messages": [
            {
                "role": "user",
                "content": (
                    "Describe the ART STYLE of this image, not its subject. Cover palette "
                    "(named hues and saturation), lighting direction and hue shift, linework "
                    "and outline treatment, and rendering (shading steps, texture, edge "
                    "hardness). Then give `prompt_fragment`: a comma-separated clause under 40 "
                    "words that would steer an image model to this exact look. "
                    + (f"Pay particular attention to {focus}. " if focus else "")
                ),
                "images": [b64],
            }
        ],
    }
    async with httpx.AsyncClient(timeout=300.0) as http:
        r = await http.post(f"{OLLAMA_URL}/api/chat", json=payload)
        r.raise_for_status()
        return json.loads(r.json()["message"]["content"])


def _corner_mask(size: int, corners: tuple[bool, bool, bool, bool], ss: int = 8) -> "np.ndarray":
    """Boolean mask for one dual-grid tile, given which corners are terrain A.

    Corners are (NW, NE, SW, SE), matching evergreen's `wang_index` bit order.

    Each set corner contributes a linear falloff `max(0, 1 - distance)`, and a
    pixel is terrain A where the contributions sum to >= 0.5. Two properties
    make this work, and both depend on the falloff reaching exactly zero at
    distance 1:

    - Along any edge, the two far corners sit at distance >= 1 and contribute
      nothing, so the edge depends only on the two corners it shares with its
      neighbour. Adjacent tiles therefore agree exactly — seamless by
      construction, no per-pair authoring.
    - Contributions accumulate, so all four corners set fills the centre
      (4 x 0.29 = 1.17) while one corner set gives a clean quarter-disc of
      radius 0.5. A plain union-of-discs cannot do both: any radius large
      enough to cover the centre spills across the edges.
    """
    n = size * ss
    ys, xs = np.mgrid[0:n, 0:n]
    # +0.5 puts sample points at pixel centres so the two halves stay balanced.
    u, v = (xs + 0.5) / n, (ys + 0.5) / n

    field = np.zeros((n, n), dtype=np.float64)
    for corner, (cx, cy) in zip(corners, [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]):
        if corner:
            field += np.clip(1.0 - np.sqrt((u - cx) ** 2 + (v - cy) ** 2), 0.0, None)
    mask = field >= 0.5

    # Majority-downsample the supersampled mask: crisp pixel edges, no alpha
    # fringe, and stable under the palette conform that follows.
    blocks = mask.reshape(size, ss, size, ss)
    return blocks.mean(axis=(1, 3)) >= 0.5


@mcp.tool()
async def dual_grid_set(
    tile_a: str,
    tile_b: str,
    output_dir: str,
    name: str = "terrain",
    dither: bool = True,
    palette: str = "apollo_forest",
) -> dict[str, Any]:
    """Build a 16-tile dual-grid (corner wang) atlas from two seamless tiles.

    Dual grid renders on a half-tile offset, so each drawn tile is defined by
    the four world cells at its corners — 16 combinations instead of the 47 a
    blob set needs. Transitions are composited, not generated, so they are
    guaranteed to line up.

    Output atlas index == evergreen's `wang_index` (NW=8, NE=4, SW=2, SE=1) on
    a 4-column sheet, which makes `WANG_TO_ATLAS` the identity mapping.

    Args:
        tile_a: The "set" terrain (bit = 1), e.g. grass.
        tile_b: The "unset" terrain (bit = 0), e.g. dirt.
        output_dir: Directory for the atlas, the 16 tiles, and metadata.
        name: Basename for the outputs.
        dither: Checkerboard the boundary pixels, the pixel-art way of
            softening a hard edge without adding colours.
        palette: Conform the result; pass "" to leave colours untouched.
    """
    a = Image.open(Path(tile_a).expanduser()).convert("RGBA")
    b = Image.open(Path(tile_b).expanduser()).convert("RGBA")
    if a.size != b.size:
        raise ValueError(f"tiles must match: {a.size} vs {b.size}")
    size = a.width
    if a.width != a.height:
        raise ValueError(f"tiles must be square, got {a.size}")

    out_dir = Path(output_dir).expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)
    arr_a, arr_b = np.array(a), np.array(b)

    atlas = Image.new("RGBA", (size * 4, size * 4))
    tiles = []
    for idx in range(16):
        corners = (bool(idx & 8), bool(idx & 4), bool(idx & 2), bool(idx & 1))
        mask = _corner_mask(size, corners)

        if dither:
            # Boundary = A-pixels that touch a B-pixel. Halving those on a
            # checkerboard reads as a gradient at 16 px without new colours.
            pad = np.pad(mask, 1, constant_values=False)
            neighbours = (
                pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
            )
            edge = mask & ~neighbours
            checker = (np.add.outer(np.arange(size), np.arange(size)) % 2).astype(bool)
            mask = mask & ~(edge & checker)

        tile = Image.fromarray(np.where(mask[..., None], arr_a, arr_b), "RGBA")
        if palette:
            palettes = _load_palettes()
            if palette not in palettes:
                raise ValueError(f"unknown palette {palette!r}; have {sorted(palettes)}")
            tile = _conform(tile, palettes[palette]["colors"])

        tile.save(out_dir / f"{name}_{idx:02d}.png")
        atlas.paste(tile, ((idx % 4) * size, (idx // 4) * size))
        tiles.append(f"{name}_{idx:02d}.png")

    atlas_path = out_dir / f"{name}_atlas.png"
    atlas.save(atlas_path)
    meta = {
        "name": name,
        "tile_size": size,
        "columns": 4,
        "bit_order": "NW=8, NE=4, SW=2, SE=1",
        "atlas_index_equals_wang_index": True,
        "wang_to_atlas": list(range(16)),
        "tiles": tiles,
    }
    (out_dir / f"{name}_atlas.json").write_text(json.dumps(meta, indent=2))
    return {"atlas": str(atlas_path), "metadata": str(out_dir / f"{name}_atlas.json"), **meta}


@mcp.tool()
async def to_webp(
    image_path: str,
    lossless: bool = True,
    output_path: str | None = None,
    keep_source: bool = True,
) -> dict[str, Any]:
    """Convert to WebP, losslessly by default.

    Lossy WebP is wrong for pixel art at any quality setting: it resamples
    across hard colour boundaries, which un-does a palette conform and puts
    colours in the file that are not in the palette. Only pass lossless=False
    for large smooth artwork such as backdrops.
    """
    src = Path(image_path).expanduser()
    out = Path(output_path).expanduser() if output_path else src.with_suffix(".webp")
    img = Image.open(src).convert("RGBA")
    img.save(out, "WEBP", lossless=lossless, quality=100 if lossless else 90, method=6)
    if not keep_source and src != out:
        src.unlink()
    return {
        "path": str(out),
        "lossless": lossless,
        "bytes": out.stat().st_size,
        "source_bytes": src.stat().st_size if src.exists() else None,
    }


@mcp.tool()
async def tile_preview(
    image_path: str,
    grid: int = 3,
    upscale: int = 4,
    output_path: str | None = None,
) -> dict[str, Any]:
    """Tile an image grid x grid so you can see whether the seams line up.

    Core ComfyUI has no circular-padding node, so nothing here generates truly
    seamless terrain. This makes the seams obvious in one glance instead of
    after they ship in a level. Also reports how different the wrapping edges
    are: 0 means the tile already wraps, larger means visible seams.
    """
    src = Path(image_path).expanduser()
    img = Image.open(src).convert("RGBA")
    a = np.array(img).astype(np.int16)

    # Mean absolute difference between the edges that would meet when tiled.
    h_seam = float(np.abs(a[:, 0, :3] - a[:, -1, :3]).mean())
    v_seam = float(np.abs(a[0, :, :3] - a[-1, :, :3]).mean())

    sheet = Image.new("RGBA", (img.width * grid, img.height * grid))
    for y in range(grid):
        for x in range(grid):
            sheet.paste(img, (x * img.width, y * img.height))
    if upscale > 1:
        sheet = sheet.resize((sheet.width * upscale, sheet.height * upscale), Image.NEAREST)

    out = Path(output_path).expanduser() if output_path else src.with_name(f"{src.stem}-tiled.png")
    sheet.save(out)
    return {
        "path": str(out),
        "seam_diff_horizontal": round(h_seam, 1),
        "seam_diff_vertical": round(v_seam, 1),
        "wraps_cleanly": h_seam < 8 and v_seam < 8,
    }


async def _combo(node: str, field: str) -> list[str]:
    """Read a node's dropdown options.

    Two shapes are in play: the classic `[[...options], {...}]` and the newer
    typed `["COMBO", {"options": [...]}]` that nodes like
    LoadBackgroundRemovalModel use. Iterating the wrong one yields characters.
    """
    async with httpx.AsyncClient(timeout=10.0) as http:
        r = await http.get(f"{COMFY_URL}/object_info/{node}")
        r.raise_for_status()
        spec = r.json()[node]["input"]["required"][field]
    head = spec[0]
    if isinstance(head, list):
        return list(head)
    opts = spec[1].get("options", []) if len(spec) > 1 and isinstance(spec[1], dict) else []
    return list(opts)


@mcp.tool()
async def list_checkpoints() -> list[str]:
    """List SD/SDXL checkpoints available in the running ComfyUI."""
    return await _combo("CheckpointLoaderSimple", "ckpt_name")


@mcp.tool()
async def list_loras() -> list[str]:
    """List LoRAs available in the running ComfyUI."""
    return await _combo("LoraLoader", "lora_name")


@mcp.tool()
async def list_diffusion_models() -> list[str]:
    """List UNet/DiT weights (Z-Image, Flux, Qwen-Image, ...) in models/diffusion_models."""
    return await _combo("UNETLoader", "unet_name")


@mcp.tool()
async def health() -> dict[str, Any]:
    """Report ComfyUI version, VRAM, and whether the configured models exist."""
    async with httpx.AsyncClient(timeout=10.0) as http:
        r = await http.get(f"{COMFY_URL}/system_stats")
        r.raise_for_status()
        stats = r.json()
    dev = (stats.get("devices") or [{}])[0]
    unets = await _combo("UNETLoader", "unet_name")
    clips = await _combo("CLIPLoader", "clip_name")
    vaes = await _combo("VAELoader", "vae_name")
    loras = await _combo("LoraLoader", "lora_name")
    checks = {
        "zimage_unet": Z_UNET in unets,
        "zimage_base_unet": Z_BASE_UNET in unets,
        "zimage_clip": Z_CLIP in clips,
        "layered_unet": LAYERED_UNET in unets,
        "layered_clip": LAYERED_CLIP in clips,
        "layered_vae": LAYERED_VAE in vaes,
        "ideogram_unet": IDEOGRAM_UNET in unets,
        "ideogram_unet_uncond": IDEOGRAM_UNET_UNCOND in unets,
        "ideogram_clip": IDEOGRAM_CLIP in clips,
        "ideogram_vae": IDEOGRAM_VAE in vaes,
        "sdxl_checkpoint": DEFAULT_CHECKPOINT in await _combo("CheckpointLoaderSimple", "ckpt_name"),
        "icon_lora": DEFAULT_ICON_LORA in loras,
        "pixel_lora": DEFAULT_PIXEL_LORA in loras,
        "bg_removal": BG_REMOVAL_MODEL
        in await _combo("LoadBackgroundRemovalModel", "bg_removal_name"),
    }
    vlm_ok = False
    try:
        async with httpx.AsyncClient(timeout=10.0) as http:
            tags = (await http.get(f"{OLLAMA_URL}/api/tags")).json()
        vlm_ok = any(m["name"].startswith(VLM_MODEL.split(":")[0]) for m in tags.get("models", []))
    except Exception:  # noqa: BLE001 - health must not fail on a down sidecar
        vlm_ok = False
    return {
        "comfyui_version": stats.get("system", {}).get("comfyui_version"),
        "pytorch_version": stats.get("system", {}).get("pytorch_version"),
        "device": dev.get("name"),
        "vram_free_gb": round(dev.get("vram_free", 0) / 2**30, 1),
        "models_present": checks,
        "vlm_judge": {"model": VLM_MODEL, "available": vlm_ok},
        "output_dir": str(OUTPUT_DIR),
    }


def main() -> None:
    asyncio.run(mcp.run_stdio_async())


if __name__ == "__main__":
    main()
