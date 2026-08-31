{ config, ... }: {
  imports = [
    # Shell
    ./shell/sh.nix
    ./shell/starship.nix
    ./shell/direnv.nix
    ./shell/lf.nix

    # Programs
    ./programs/nvim.nix
    ./programs/browser.nix
    ./programs/git.nix
    ./programs/tmux
    ./programs/tmuxai.nix
    ./programs/ghostty.nix
    ./programs/distrobox.nix
    ./programs/opencode.nix
    ./programs/cosmic.nix

    # Theme
    ./theme/theme.nix
    ./theme/dconf.nix

    # Packages
    ./packages.nix

    # Secrets (sops-nix)
    ./secrets.nix
  ];

  news.display = "show";

  home = {
    sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      QT_XCB_GL_INTEGRATION = "none"; # kde-connect
      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_INSECURE = "1";
      BAT_THEME = "base16";
      GOPATH = "${config.home.homeDirectory}/.local/share/go";
      GOMODCACHE = "${config.home.homeDirectory}/.cache/go/pkg/mod";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.npm-global/bin"
    ];
  };

  xdg.configFile."gtk-3.0/bookmarks".text =
    let
      home = config.home.homeDirectory;
    in
    ''
      "file://${home}/Documents"
      "file://${home}/Music"
      "file://${home}/Pictures"
      "file://${home}/Videos"
      "file://${home}/Downloads"
      "file://${home}/Desktop"
      "file://${home}/Work"
      "file://${home}/Projects"
      "file://${home}/Vault"
      "file://${home}/School"
      "file://${home}/.config Config"
    '';

  programs.home-manager.enable = true;
  home.stateVersion = "26.05";
}
