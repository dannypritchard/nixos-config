{ pkgs, lib, ... }:
{
  imports = [ ../home.nix ];

  home.username = "danny";
  home.homeDirectory = "/Users/danny";

  targets.darwin.copyApps.enableChecks = false;

  # Optional: Darwin-only package tweaks go here
  home.packages = with pkgs; [
    # add terminal tools that exist on Darwin
    php84
    php84Packages.composer
  ];

  services.ollama.acceleration = false;

  programs.git.settings.user.email = "danny.pritchard@synchtank.net";
}
