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

   programs.git.settings.user.email = "danny.pritchard@synchtank.net";

   programs.zsh.initContent = lib.mkBefore ''
     export PATH="/etc/profiles/per-user/$USER/bin:$PATH"

      eval "$(fnm env --use-on-cd --shell zsh)"

      autoload -Uz select-word-style
      select-word-style bash
   '';
}
