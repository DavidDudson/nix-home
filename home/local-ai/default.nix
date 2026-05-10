{ pkgs, ... }:

{
  imports = [
    ./comfyui.nix
    ./gameart-mcp
  ];

  # User-level local-AI CLI tools.
  home.packages = with pkgs; [
    aider-chat # CLI pair programmer, points at Ollama via OPENAI_API_BASE
  ];

  # Default any OpenAI-compatible client (aider, llm, etc.) at local Ollama.
  home.sessionVariables = {
    OPENAI_API_BASE = "http://127.0.0.1:11434/v1";
    OPENAI_API_KEY = "ollama"; # Ollama ignores the value but tools require non-empty
  };
}
