{ config, lib, pkgs, ... }:

{
  imports = [
    # future: split config into modules here
    # ./hardware.nix
    # ./packages.nix
    # ./services.nix
  ];

  # --- WSL ---
  wsl.enable = true;
  wsl.defaultUser = "danny";
  wsl.docker-desktop.enable = true;

  wsl.extraBin = [
    {
      name = "whoami";
      src = "${pkgs.coreutils}/bin/whoami";
    }
  ];

  # --- User ---
  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  # --- Nix ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- System packages ---
  environment.systemPackages = with pkgs; [
    git
  ];

  # --- System version ---
  system.stateVersion = "25.11";

  programs.zsh.enable = true;
}
