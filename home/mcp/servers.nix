{ pkgs, mcp-servers-nix, ... }:

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

  # Status line configuration for Claude Code
  statusLineConfig = {
    statusLine = {
      type = "command";
      command = "nu ~/.claude/statusline.nu";
      padding = 0;
    };
  };

  # MCP servers not supported by mcp-servers-nix (HTTP + custom stdio).
  httpServersConfig = {
    mcpServers = {
      pixellab = {
        type = "http";
        url = "https://api.pixellab.ai/mcp";
        headers = {
          Authorization = "Bearer \${PIXELLAB_API_KEY}";
        };
      };

      # Game-art wrapper: tuned ComfyUI workflows exposed as discrete tools
      # (generate_icon, generate_sprite, generate_background, generate_ui_panel).
      # Requires `comfyui` launcher running on :8188 and SDXL + LoRAs installed.
      # See home/local-ai/gameart-mcp for the implementation.
      gameart = {
        command = "gameart-mcp";
        env = {
          COMFY_URL = "http://127.0.0.1:8188";
          GAMEART_OUTPUT_DIR = "\${HOME}/.local/share/gameart-mcp/output";
          # Civitai's game-icon-institute LoRA is geo-blocked in AU. Substitute
          # an HF-hosted 3d-icon SDXL LoRA (8glabs/3d-icon-sdxl-lora).
          GAMEART_ICON_LORA = "3d-icon-sdxl-lora.safetensors";
        };
      };
    };
  };

  # Permission rules for Claude Code
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

  # Merge MCP config with statusLine
  mergedConfig =
    pkgs.runCommand "claude-settings.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        ${pkgs.jq}/bin/jq -s '.[0] * .[1] * .[2] * .[3]' \
          ${mcpConfig} \
          ${pkgs.writeText "statusline.json" (builtins.toJSON statusLineConfig)} \
          ${pkgs.writeText "http-servers.json" (builtins.toJSON httpServersConfig)} \
          ${pkgs.writeText "permissions.json" (builtins.toJSON permissionsConfig)} \
          > $out
      '';

in
{
  # Write the merged configuration to Claude Code settings
  home.file.".config/claude/settings.json".source = mergedConfig;
}
