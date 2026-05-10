{ pkgs, ... }:

{
  # Ollama LLM runtime with CUDA acceleration for the RTX 4090.
  # Hosts an OpenAI-compatible API at http://127.0.0.1:11434.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;

    host = "127.0.0.1";
    port = 11434;

    # Auto-pull on activation. Comment a line to skip a model.
    # Update tags as new releases land in the Ollama registry.
    loadModels = [
      "qwen2.5-coder:32b" # Primary coder, ~20GB Q4_K_M
      "qwen2.5-coder:7b" # Low-latency autocomplete sidecar
      "qwen2.5:32b" # General chat / instruct
      "deepseek-r1:32b" # Reasoning specialist
      "nomic-embed-text" # Embeddings for OpenWebUI RAG
    ];

    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_KEEP_ALIVE = "30m";
    };
  };
}
