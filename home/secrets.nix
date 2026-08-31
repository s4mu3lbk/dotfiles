# sops-nix secrets configuration for Home Manager
{config, ...}: {
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      openai_api_key = {};
      gemini_api_key = {};
      kimi_api_key = {};
      figma_api_key = {};
      bw_session = {};
      stitch_api_key = {};
      bitbucket_api_token = {};
    };
  };

}
