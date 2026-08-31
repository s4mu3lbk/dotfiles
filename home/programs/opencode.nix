{
  config,
  pkgs,
  lib,
  ...
}:
{
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [
      "opencode-agent-skills"
      "opencode-mem"
      "opencode-claude-auth@latest"
      "opencode-pty"
      "superpowers@git+https://github.com/obra/superpowers.git"
    ];
    default_agent = "plan";
    permission = {
      edit = "allow";
      bash = "ask";
    };
    compaction = {
      auto = true;
      prune = false;
      reserved = 10000;
    };
    mcp = {
      "Framelink MCP for Figma" = {
        type = "local";
        command = [
          "npx"
          "-y"
          "figma-developer-mcp"
          "--stdio"
        ];
        enabled = true;
        timeout = 10000;
      };
      "Stitch" = {
        type = "remote";
        url = "https://stitch.googleapis.com/mcp";
        enabled = true;
        headers = {
          "X-Goog-Api-Key" = "__STITCH_API_KEY_PLACEHOLDER__";
        };
      };
      "Playwright" = {
        type = "local";
        command = [
          "npx"
          "-y"
          "@playwright/mcp@latest"
        ];
        enabled = true;
      };
    };
  };

  home.activation.patchOpencodeSecret = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_file="$HOME/.config/opencode/opencode.json"
    tmp_file="$config_file.tmp.$$"
    $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
      '.mcp.Stitch.headers."X-Goog-Api-Key" = $secret' \
      --arg secret "$(cat ${config.sops.secrets.stitch_api_key.path})" \
      "$config_file" > "$tmp_file"
    $DRY_RUN_CMD mv "$tmp_file" "$config_file"
  '';
}
