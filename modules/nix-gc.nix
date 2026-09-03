{ ... }:

{
  # Shared GC retention policy. Platform-specific scheduling
  # (nix.gc.dates on NixOS, nix.gc.interval on nix-darwin) lives in
  # the respective host configuration.
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";
}
