{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.danny = {
    home = "/Users/danny";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # Useful Darwin defaults you can grow into later:
  # services.nix-daemon.enable = true;
  # system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
  # homebrew.enable = true;

  system.stateVersion = 6;
}
