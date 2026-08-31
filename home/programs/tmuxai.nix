_: {
  xdg.configFile."tmuxai/config.yaml".text = ''
    default_model: kimi
    web_search.enabled: true

    models:
      kimi:
        provider: "openrouter"
        model: "kimi-k3"
        api_key: "''${KIMI_API_KEY}"
        base_url: https://api.kimi.com/coding/v1

      primary:
        provider: "openrouter"
        model: "kimi-for-coding-highspeed"
        api_key: "''${KIMI_API_KEY}"
        base_url: https://api.kimi.com/coding/v1

      local-llama:
        provider: "openrouter"
        model: "gemma4:latest"
        api_key: "ollama"
        base_url: http://localhost:11434/v1
  '';
}
