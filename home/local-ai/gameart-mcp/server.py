"""Game-art MCP: tuned ComfyUI workflows exposed as discrete tools.

Tools:
  - generate_icon: transparent-background item/ability icons
  - generate_sprite: character sprites (pixel-art aware)
  - generate_background: scene/parallax backgrounds
  - generate_ui_panel: UI chrome elements
  - list_checkpoints / list_loras: introspect ComfyUI installation

Each tool submits a tuned workflow to a running ComfyUI on COMFY_URL,
polls until done, and returns the absolute path of the produced PNG.
"""

from __future__ import annotations

import asyncio
import json
import os
import random
import time
import uuid
from pathlib import Path
from typing import Any

import httpx
import websockets
from mcp.server.fastmcp import FastMCP

COMFY_URL = os.environ.get("COMFY_URL", "http://127.0.0.1:8188")
OUTPUT_DIR = Path(
    os.environ.get(
        "GAMEART_OUTPUT_DIR",
        os.path.expanduser("~/.local/share/gameart-mcp/output"),
    )
)
DEFAULT_CHECKPOINT = os.environ.get("GAMEART_SDXL_CHECKPOINT", "sd_xl_base_1.0.safetensors")
DEFAULT_PIXEL_LORA = os.environ.get("GAMEART_PIXEL_LORA", "pixel-art-xl.safetensors")
DEFAULT_ICON_LORA = os.environ.get("GAMEART_ICON_LORA", "game-icon-institute.safetensors")

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
mcp = FastMCP("gameart")


def _seed(seed: int | None) -> int:
    return seed if seed is not None else random.randint(0, 2**31 - 1)


def _ksampler(model_in: list, positive: list, negative: list, latent: list, seed: int, steps: int = 28, cfg: float = 6.5) -> dict:
    return {
        "class_type": "KSampler",
        "inputs": {
            "seed": seed,
            "steps": steps,
            "cfg": cfg,
            "sampler_name": "dpmpp_2m",
            "scheduler": "karras",
            "denoise": 1.0,
            "model": model_in,
            "positive": positive,
            "negative": negative,
            "latent_image": latent,
        },
    }


def _build_workflow(
    *,
    prompt: str,
    negative: str,
    seed: int,
    width: int,
    height: int,
    checkpoint: str,
    loras: list[tuple[str, float, float]],  # (name, model_strength, clip_strength)
    filename_prefix: str,
) -> dict[str, Any]:
    """Build a minimal SDXL workflow with optional stacked LoRAs."""
    g: dict[str, dict] = {
        "ckpt": {
            "class_type": "CheckpointLoaderSimple",
            "inputs": {"ckpt_name": checkpoint},
        },
        "latent": {
            "class_type": "EmptyLatentImage",
            "inputs": {"width": width, "height": height, "batch_size": 1},
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

    g["pos"] = {
        "class_type": "CLIPTextEncode",
        "inputs": {"text": prompt, "clip": clip_ref},
    }
    g["neg"] = {
        "class_type": "CLIPTextEncode",
        "inputs": {"text": negative, "clip": clip_ref},
    }
    g["sampler"] = _ksampler(model_ref, ["pos", 0], ["neg", 0], ["latent", 0], seed)
    g["decode"] = {
        "class_type": "VAEDecode",
        "inputs": {"samples": ["sampler", 0], "vae": vae_ref},
    }
    g["save"] = {
        "class_type": "SaveImage",
        "inputs": {"filename_prefix": filename_prefix, "images": ["decode", 0]},
    }
    return g


async def _submit_and_wait(workflow: dict[str, Any]) -> list[Path]:
    """Submit workflow, wait for completion via websocket, return saved file paths."""
    client_id = str(uuid.uuid4())
    async with httpx.AsyncClient(timeout=30.0) as http:
        resp = await http.post(
            f"{COMFY_URL}/prompt",
            json={"prompt": workflow, "client_id": client_id},
        )
        resp.raise_for_status()
        prompt_id = resp.json()["prompt_id"]

        ws_url = COMFY_URL.replace("http", "ws") + f"/ws?clientId={client_id}"
        async with websockets.connect(ws_url, max_size=None) as ws:
            while True:
                msg = await ws.recv()
                if isinstance(msg, bytes):
                    continue
                data = json.loads(msg)
                if data.get("type") == "executing":
                    payload = data.get("data", {})
                    if payload.get("prompt_id") == prompt_id and payload.get("node") is None:
                        break

        hist = (await http.get(f"{COMFY_URL}/history/{prompt_id}")).json()
        outputs = hist.get(prompt_id, {}).get("outputs", {})
        saved: list[Path] = []
        for node_out in outputs.values():
            for img in node_out.get("images", []):
                params = {"filename": img["filename"], "subfolder": img.get("subfolder", ""), "type": img.get("type", "output")}
                r = await http.get(f"{COMFY_URL}/view", params=params)
                r.raise_for_status()
                dest = OUTPUT_DIR / f"{int(time.time())}-{img['filename']}"
                dest.write_bytes(r.content)
                saved.append(dest)
        return saved


@mcp.tool()
async def generate_icon(
    prompt: str,
    style: str = "fantasy rpg",
    seed: int | None = None,
    transparent: bool = True,
) -> dict[str, Any]:
    """Generate a single game icon (item, ability, status effect).

    Args:
        prompt: Subject of the icon, e.g. "fire potion", "lightning sword".
        style: Visual style, e.g. "fantasy rpg", "sci-fi", "pixel art".
        seed: Reproducibility seed. Random if omitted.
        transparent: Reserved. Real transparency requires rembg post-processing.

    Returns:
        Dict with `path` (absolute file path) and `seed`.
    """
    s = _seed(seed)
    full_prompt = (
        f"game icon, {prompt}, {style} style, centered, single object, "
        "studio lighting, dark background, sharp details, high contrast"
    )
    negative = "text, watermark, blurry, multiple objects, frame, border, low quality, pixelated, jpeg artifacts"
    wf = _build_workflow(
        prompt=full_prompt,
        negative=negative,
        seed=s,
        width=1024,
        height=1024,
        checkpoint=DEFAULT_CHECKPOINT,
        loras=[(DEFAULT_ICON_LORA, 0.8, 1.0)],
        filename_prefix="icon",
    )
    paths = await _submit_and_wait(wf)
    return {"path": str(paths[0]) if paths else None, "seed": s, "transparent": transparent}


@mcp.tool()
async def generate_sprite(
    prompt: str,
    pose: str = "idle, front view",
    palette_size: int = 32,
    seed: int | None = None,
) -> dict[str, Any]:
    """Generate a pixel-art character sprite.

    Args:
        prompt: Character description, e.g. "wizard with red robe and staff".
        pose: Pose/orientation, e.g. "idle, front view", "walking, side view".
        palette_size: Reserved for post-process palette quantization step.
        seed: Reproducibility seed.
    """
    s = _seed(seed)
    full_prompt = (
        f"pixel art sprite, {prompt}, {pose}, full body, centered, "
        "transparent background, clean pixel art, limited palette, crisp pixels"
    )
    negative = "blurry, anti-aliased, photorealistic, 3d render, watermark, text"
    wf = _build_workflow(
        prompt=full_prompt,
        negative=negative,
        seed=s,
        width=1024,
        height=1024,
        checkpoint=DEFAULT_CHECKPOINT,
        loras=[(DEFAULT_PIXEL_LORA, 1.0, 1.0)],
        filename_prefix="sprite",
    )
    paths = await _submit_and_wait(wf)
    return {"path": str(paths[0]) if paths else None, "seed": s, "palette_size": palette_size}


@mcp.tool()
async def generate_background(
    prompt: str,
    biome: str = "fantasy forest",
    aspect: str = "landscape",
    seed: int | None = None,
) -> dict[str, Any]:
    """Generate a scene/parallax background.

    Args:
        prompt: Scene description.
        biome: Setting, e.g. "fantasy forest", "cyberpunk city", "desert".
        aspect: "landscape" (1536x1024), "portrait" (1024x1536), or "square".
        seed: Reproducibility seed.
    """
    s = _seed(seed)
    if aspect == "portrait":
        w, h = 1024, 1536
    elif aspect == "square":
        w, h = 1024, 1024
    else:
        w, h = 1536, 1024
    full_prompt = (
        f"{biome} background, {prompt}, "
        "atmospheric, painterly, depth, parallax-friendly composition, no characters, no text"
    )
    negative = "characters, people, text, watermark, ui elements, low quality"
    wf = _build_workflow(
        prompt=full_prompt,
        negative=negative,
        seed=s,
        width=w,
        height=h,
        checkpoint=DEFAULT_CHECKPOINT,
        loras=[],
        filename_prefix="bg",
    )
    paths = await _submit_and_wait(wf)
    return {"path": str(paths[0]) if paths else None, "seed": s, "size": [w, h]}


@mcp.tool()
async def generate_ui_panel(
    prompt: str,
    style: str = "ornate fantasy",
    seed: int | None = None,
) -> dict[str, Any]:
    """Generate a UI panel/frame/dialog-box element.

    Caveat: AI struggles with structural UI. Output usually needs hand cleanup.
    Best for stylistic reference, not ship-ready chrome.
    """
    s = _seed(seed)
    full_prompt = (
        f"game ui panel frame, {prompt}, {style} style, "
        "centered, symmetrical, dark background, high contrast, decorative border"
    )
    negative = "text, characters, blurry, asymmetric, low quality"
    wf = _build_workflow(
        prompt=full_prompt,
        negative=negative,
        seed=s,
        width=1024,
        height=768,
        checkpoint=DEFAULT_CHECKPOINT,
        loras=[],
        filename_prefix="ui",
    )
    paths = await _submit_and_wait(wf)
    return {"path": str(paths[0]) if paths else None, "seed": s}


@mcp.tool()
async def list_checkpoints() -> list[str]:
    """List SDXL/SD checkpoints available in the running ComfyUI."""
    async with httpx.AsyncClient(timeout=10.0) as http:
        r = await http.get(f"{COMFY_URL}/object_info/CheckpointLoaderSimple")
        r.raise_for_status()
        info = r.json()["CheckpointLoaderSimple"]["input"]["required"]["ckpt_name"][0]
        return list(info)


@mcp.tool()
async def list_loras() -> list[str]:
    """List LoRAs available in the running ComfyUI."""
    async with httpx.AsyncClient(timeout=10.0) as http:
        r = await http.get(f"{COMFY_URL}/object_info/LoraLoader")
        r.raise_for_status()
        info = r.json()["LoraLoader"]["input"]["required"]["lora_name"][0]
        return list(info)


def main() -> None:
    asyncio.run(mcp.run_stdio_async())


if __name__ == "__main__":
    main()
