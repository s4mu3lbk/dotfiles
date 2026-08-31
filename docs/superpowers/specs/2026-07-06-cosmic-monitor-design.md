# cosmic-monitor installation design

## Goal

Install the `cosmic-monitor` package (COSMIC System Monitor) from nixpkgs so it is available when the COSMIC desktop environment is enabled.

## Placement

The installation belongs in the COSMIC desktop module at `system/de/cosmic.nix` because the tool is part of the COSMIC ecosystem and only makes sense when COSMIC is enabled.

## Design

Add a new toggle option `cosmic.monitor.enable` that defaults to `true`. When both `cosmic.enable` and `cosmic.monitor.enable` are true, include `pkgs.cosmic-monitor` in `environment.systemPackages`.

### Option definition

```nix
options.cosmic.monitor.enable = lib.mkOption {
  type = lib.types.bool;
  default = true;
  description = "Whether to install the COSMIC System Monitor.";
};
```

### Package installation

Inside the existing `config = lib.mkIf config.cosmic.enable { ... }` block, replace the empty `environment.systemPackages` list with a conditional installation:

```nix
environment.systemPackages = lib.mkIf config.cosmic.monitor.enable (with pkgs; [
  cosmic-monitor
]);
```

## Validation

- Run `nix flake check` to catch syntax and option errors.
- Run `nixos-rebuild build --flake .#nixos` to verify the configuration evaluates and the package is available in the system closure.

## Notes

- The package is only installed when the COSMIC desktop is enabled.
- Users can disable the monitor later by setting `cosmic.monitor.enable = false`.
