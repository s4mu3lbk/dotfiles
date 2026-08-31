# Minimal Home Manager profile for the headless server (user: samuel).
# Excludes GUI apps, theming, and the full package set from home.nix.
# secrets.nix is required: shell/sh.nix reads sops secret paths.
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Shell
    ./shell/sh.nix
    ./shell/starship.nix
    ./shell/direnv.nix
    ./shell/lf.nix

    # Programs
    ./programs/git.nix
    ./programs/tmux
    ./programs/nvim.nix

    # Secrets (sops-nix)
    ./secrets.nix
  ];

  news.display = "show";

  home.packages = with pkgs; [
    bat
    eza
    lsd
    fd
    ripgrep
    fzf
    btop
    jq
    tldr
    lazygit
    lazydocker
    entr
    fastfetch
    statix
    deadnix
  ];

  home = {
    sessionVariables = {
      NIXPKGS_ALLOW_UNFREE = "1";
      BAT_THEME = "base16";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
    ];
  };

  programs.home-manager.enable = true;
  home.stateVersion = "26.05";
}
