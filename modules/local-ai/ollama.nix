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
    # Sized for the 4090's 24 GB: one ~19 GB model resident at a time, plus
    # room for the small sidecars. `loadModels` only pulls — superseded tags
    # (qwen2.5-*, deepseek-r1) must be removed by hand with `ollama rm`.
    loadModels = [
      "qwen3-coder:30b" # Primary coder. 30B MoE, 3.3B active → 32b-class
      # quality at ~2x the tokens/s, 256K ctx, ~19GB Q4_K_M
      "qwen3.6:27b" # General chat + agentic work, ~16GB Q4_K_M
      "qwen2.5-coder:7b" # Autocomplete sidecar: still the best small FIM
      # model, qwen3-coder has no sub-30B release
      "qwen3-vl:8b" # Vision. Captions/critiques ComfyUI output so the
      # game-art loop can self-review renders. Bump to :32b (~20GB) if
      # the root partition ever has the headroom

      "qwen3-embedding:0.6b" # RAG embeddings; replaces nomic-embed-text
      # (better MTEB, 32K ctx, half the size)
    ];

    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_KEEP_ALIVE = "30m";
    };
  };
}
