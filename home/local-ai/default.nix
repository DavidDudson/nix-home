_:

{
  imports = [
    ./comfyui.nix
    ./gameart-mcp
    ./lora-train
  ];

  # aider-chat (CLI pair programmer, points at Ollama via OPENAI_API_BASE) is
  # dropped from home.packages: nixpkgs 2026-11-07 marks python3.14-posthog
  # broken (mcp >= 2), and tree-sitter-language-pack 1.4.1 fails to build.
  # Re-add once both build again.

  # Default any OpenAI-compatible client (llm, etc.) at local Ollama.
  home.sessionVariables = {
    OPENAI_API_BASE = "http://127.0.0.1:11434/v1";
    OPENAI_API_KEY = "ollama"; # Ollama ignores the value but tools require non-empty
  };
}
