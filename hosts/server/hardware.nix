# Placeholder — replace with the output of `nixos-generate-config` run on the
# server (fileSystems, boot.initrd modules, CPU microcode, etc.).
# Note: system/core/boot.nix forces systemd-boot + EFI; override with GRUB here
# or in configuration.nix if the server uses legacy/BIOS boot.
{...}: {
  nixpkgs.hostPlatform = "x86_64-linux";

  # TODO: replace with the real root device from nixos-generate-config
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
