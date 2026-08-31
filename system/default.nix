# System module aggregator — imports all core modules
{...}: {
  imports = [
    ./core/nix.nix
    ./core/boot.nix
    ./core/networking.nix
    ./core/services.nix
    ./core/howdy.nix
    ./core/virtualisation.nix
    ./core/packages.nix
    ./core/bluetooth.nix
    ./core/audio.nix
    ./core/locale.nix
    ./core/fonts.nix
    ./core/windscribe.nix
    ./core/ollama.nix
  ];
}
