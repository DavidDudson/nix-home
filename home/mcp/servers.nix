{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Status line configuration for Claude Code. The script itself is installed by
  # home/home.nix as `.claude/statusline.sh`; keep the two in step.
  statusLineConfig = {
    statusLine = {
      type = "command";
      command = "bash ${config.home.homeDirectory}/.claude/statusline.sh";
      padding = 0;
    };
  };

  # User-scope MCP servers, loaded in every session. Deliberately empty: each
  # server's tool names and instructions cost context in every session, and the
  # old set only duplicated built-ins (gh/git via Bash, Read/Edit, WebFetch,
  # file memory, extended thinking, claude-in-chrome). Add one only for a
  # capability Claude Code lacks, and prefer `optInServers`.
  userServers = { };

  # Opt-in servers, each written to ~/.claude/mcp/<name>.json and loaded only
  # where needed: `claude --mcp-config ~/.claude/mcp/gameart.json`. Kept out of
  # user scope so their tools cost nothing in sessions that never use them.
  optInServers = {
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

  # Plugins Nix guarantees. Merged into settings.json, so plugins installed at
  # runtime via /plugin survive; Claude Code fetches the marketplace on start.
  pluginsConfig = {
    extraKnownMarketplaces.humanizer.source = {
      source = "github";
      repo = "blader/humanizer";
    };
    enabledPlugins = {
      "humanizer@humanizer" = true;
      # Off: duplicates of built-ins (/code-review, /simplify, gh via Bash) or
      # unused, and each lists its skills and agents in every session.
      "github@claude-plugins-official" = false;
      "context7@claude-plugins-official" = false;
      "code-review@claude-plugins-official" = false;
      "code-simplifier@claude-plugins-official" = false;
      "feature-dev@claude-plugins-official" = false;
    };
  };

  # Usage: Opus plans, Sonnet executes. claude.ai connectors (Gmail, Drive,
  # Calendar, Docs) stay on claude.ai and out of Claude Code sessions.
  usageConfig = {
    model = "opusplan";
    env.ENABLE_CLAUDEAI_MCP_SERVERS = "false";
  };

  # Remind Claude to hand off and reset once context passes the threshold. The
  # status line records the session's context % for the hook to read.
  hooksConfig = {
    hooks.UserPromptSubmit = [
      {
        hooks = [
          {
            type = "command";
            command = "bash ${config.home.homeDirectory}/.claude/context-reset.sh";
          }
        ];
      }
    ];
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

  mcpServersJson = pkgs.writeText "claude-mcp-servers.json" (
    builtins.toJSON { mcpServers = userServers; }
  );

  # The keys that genuinely belong in settings.json.
  settingsJson = pkgs.runCommand "claude-settings.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq -s 'reduce .[] as $part ({}; . * $part)' \
      ${pkgs.writeText "statusline.json" (builtins.toJSON statusLineConfig)} \
      ${pkgs.writeText "permissions.json" (builtins.toJSON permissionsConfig)} \
      ${pkgs.writeText "plugins.json" (builtins.toJSON pluginsConfig)} \
      ${pkgs.writeText "usage.json" (builtins.toJSON usageConfig)} \
      ${pkgs.writeText "hooks.json" (builtins.toJSON hooksConfig)} \
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

  home.file = lib.mapAttrs' (
    name: server:
    lib.nameValuePair ".claude/mcp/${name}.json" {
      source = pkgs.writeText "claude-mcp-${name}.json" (
        builtins.toJSON { mcpServers.${name} = server; }
      );
    }
  ) optInServers;
}
