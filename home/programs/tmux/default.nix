{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [ vim-tmux-navigator yank ];
    shell = "${pkgs.fish}/bin/fish";
    extraConfig = builtins.readFile ./tmux.conf;
  };

  xdg.configFile."tmux/tmux.conf.local".source = ./tmux.conf.local;
}
