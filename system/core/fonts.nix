{ pkgs, ... }: {
  # System-level font configuration
  fonts = {
    # Enable fontconfig
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" "Liberation Serif" ];
        sansSerif = [ "Ubuntu" "Noto Sans" "Liberation Sans" ];
        monospace = [ "CaskaydiaCove Nerd Font Mono" "Ubuntu Mono" "Liberation Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
      # Improve font rendering
      subpixel.rgba = "rgb";
      hinting = {
        enable = true;
        style = "slight";
      };
      antialias = true;
    };

    # System font packages
    packages = with pkgs; [
      # Core fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      
      # Liberation fonts (good fallbacks)
      liberation_ttf
      
      # Ubuntu fonts
      ubuntu-classic
      
      # Nerd Fonts for terminal and development
      nerd-fonts.ubuntu
      nerd-fonts.caskaydia-cove
      nerd-fonts.fira-code
      
      # Additional useful fonts
      dejavu_fonts
      source-code-pro
      source-sans-pro
      source-serif-pro
      
      # Font tools
      font-manager
      fontconfig
    ];
  };
}
