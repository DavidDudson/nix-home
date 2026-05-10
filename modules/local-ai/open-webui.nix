_:

{
  # ChatGPT-style frontend for Ollama, served at http://127.0.0.1:8080.
  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;

    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      # Local single-user box: skip auth wall.
      WEBUI_AUTH = "False";
      # Disable phone-home/usage telemetry.
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
    };
  };
}
