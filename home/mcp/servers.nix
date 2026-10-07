{
  config,
  lib,
  pkgs,
  mcp-servers-nix,
  ...
}:

let
  # Build MCP server configuration
  mcpConfig = (import mcp-servers-nix { inherit pkgs; }).lib.mkConfig pkgs {
    format = "json";
    flavor = "claude-code";

    programs = {
      # Documentation and search
      context7.enable = true;

      # Development tools
      github.enable = true;
      git.enable = true;
      fetch.enable = true;
      time.enable = true;
      filesystem.enable = true;

      # AI capabilities
      memory.enable = true;
      playwright.enable = true;
      sequential-thinking.enable = true;

      # Temporarily disabled: aioboto3 test failures in current nixpkgs.
      nixos.enable = false;
    };
  };

  # Status line configuration for Claude Code. The script itself is installed by
  # home/home.nix as `.claude/statusline.sh`; keep the two in step.
  statusLineConfig = {
    statusLine = {
      type = "command";
      command = "bash ${config.home.homeDirectory}/.claude/statusline.sh";
      padding = 0;
    };
  };

  # MCP servers not supported by mcp-servers-nix (HTTP + custom stdio).
  httpServersConfig = {
    mcpServers = {
      # Game-art wrapper: tuned ComfyUI workflows exposed as discrete tools.
      # Backgrounds/panels run Z-Image-Turbo (8 steps, ~3s), sprites and icons
      # stay on SDXL where the style LoRAs are, generate_layered emits real RGBA
      # layers via Qwen-Image-Layered, generate_text_art runs Ideogram 4 for
      # legible in-image text, and generate_best/critique let qwen3-vl pick the
      # winner out of a batch. Requires the `comfyui` launcher on :8188 and, for
      # the judge, ollama on :11434. `health` reports which weights are present.
      # See home/local-ai/gameart-mcp for the implementation.
      gameart = {
        command = "gameart-mcp";
        env = {
          COMFY_URL = "http://127.0.0.1:8188";
          GAMEART_OUTPUT_DIR = "\${HOME}/.local/share/gameart-mcp/output";
          # Civitai's game-icon-institute LoRA is geo-blocked in AU. Substitute
          # an HF-hosted 3d-icon SDXL LoRA (8glabs/3d-icon-sdxl-lora).
          GAMEART_ICON_LORA = "3d-icon-sdxl-lora.safetensors";
          # Comfy-Org/BiRefNet in models/background_removal/ -- gives icons and
          # sprites a real alpha channel instead of a keyed dark backdrop.
          GAMEART_BG_REMOVAL_MODEL = "birefnet.safetensors";
          # Local vision model that scores candidate renders (generate_best).
          GAMEART_VLM_MODEL = "qwen3-vl:8b";
          OLLAMA_URL = "http://127.0.0.1:11434";
        };
      };
    };
  };

  # Plugins Nix guarantees. Merged into settings.json, so plugins installed at
  # runtime via /plugin survive; Claude Code fetches the marketplace on start.
  pluginsConfig = {
    extraKnownMarketplaces.humanizer.source = {
      source = "github";
      repo = "blader/humanizer";
    };
    enabledPlugins."humanizer@humanizer" = true;
  };

  # Top-level ~/.claude.json keys (besides mcpServers) that Nix owns.
  claudeJsonConfig = {
    claudeInChromeDefaultEnabled = true;
  };

  # Permission rules for Claude Code.
  permissionsConfig = {
    permissions = {
      allow = [
        "Bash(sudo nixos-rebuild switch)"
        "Bash(sudo nixos-rebuild switch --upgrade)"
      ];
      deny = [
        "Bash(sudo *)"
      ];
    };
  };

  # Claude Code splits its configuration across two files, and which key belongs
  # where is not negotiable:
  #
  #   ~/.claude.json           user-scope `mcpServers` (plus project state)
  #   ~/.claude/settings.json  statusLine, permissions, model, plugins, ...
  #
  # `mcpServers` is not a settings.json key at all -- writing it there is
  # silently ignored, which is exactly how this config sat inert.

  # Every MCP server, from both sources, as a bare { mcpServers: { ... } }.
  mcpServersJson = pkgs.runCommand "claude-mcp-servers.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq -s '{ mcpServers: ((.[0].mcpServers // {}) * (.[1].mcpServers // {})) }' \
      ${mcpConfig} \
      ${pkgs.writeText "http-servers.json" (builtins.toJSON httpServersConfig)} \
      > $out
  '';

  # The keys that genuinely belong in settings.json.
  settingsJson = pkgs.runCommand "claude-settings.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq -s '.[0] * .[1] * .[2]' \
      ${pkgs.writeText "statusline.json" (builtins.toJSON statusLineConfig)} \
      ${pkgs.writeText "permissions.json" (builtins.toJSON permissionsConfig)} \
      ${pkgs.writeText "plugins.json" (builtins.toJSON pluginsConfig)} \
      > $out
  '';

  claudeJsonExtra = pkgs.writeText "claude-json-extra.json" (builtins.toJSON claudeJsonConfig);

  mergeScript = pkgs.writeShellApplication {
    name = "claude-config-merge";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = builtins.readFile ./claude-config-merge.sh;
  };

in
{
  # Merge rather than symlink: Claude Code writes to both target files at
  # runtime, so a read-only store symlink would break it. See the script for the
  # ownership rules and how servers removed from Nix get cleaned up.
  home.activation.claudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${lib.getExe mergeScript} ${mcpServersJson} ${settingsJson} ${claudeJsonExtra}
  '';
}
