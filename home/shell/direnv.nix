{ pkgs, ... }: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      : ''${nix_direnv_watch_file=watch_file}
    '';
  };
}
