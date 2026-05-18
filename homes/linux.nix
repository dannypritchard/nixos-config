{ pkgs, ... }:
{
  imports = [ ../home.nix ];

  home.username = "danny";
  home.homeDirectory = "/home/danny";

  # Optional: Linux-only package tweaks go here
  home.packages = with pkgs; [
    bubblewrap
    obsidian
  ];

  programs.git.settings.user.email = "danny@loxley.digital";
}
