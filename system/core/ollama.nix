{pkgs, ...}: {
  services.ollama = {
    enable = true;
    package = pkgs.ollama;
  };

  services.open-webui = {
    enable = false;
    port = 8085;
  };
}
