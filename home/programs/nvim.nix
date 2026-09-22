{ pkgs, lib, ... }:
let
  nvim = import ../../packages/nvim { inherit pkgs; };
  # In-store copy: the nvim config is snapshotted at build time.
  # Edit packages/nvim, then rebuild to apply changes.
  nvimConfig = lib.cleanSourceWith {
    src = ../../packages/nvim;
    filter = path: _: baseNameOf path != ".git";
  };
in {
  xdg.configFile.nvim.source = nvimConfig;

  xdg.desktopEntries."nvim" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    name = "NeoVim";
    comment = "Edit text files";
    icon = "nvim";
    exec = "xterm -e ${nvim}/bin/nvim %F";
    categories = [ "TerminalEmulator" ];
    terminal = false;
    mimeType = [ "text/plain" ];
  };

  xdg.mimeApps.defaultApplications."text/plain" = "nvim.desktop";

  xdg.desktopEntries."vim" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    name = "Vim";
    noDisplay = true;
  };

  home.sessionVariables = {
    EDITOR = "nvr --remote-wait +'set bufhidden=delete'";
    VISUAL = "nvr --remote-wait +'set bufhidden=delete'";
  };

  home.packages = [ nvim pkgs.neovim-remote ];
}
