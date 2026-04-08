{ config, pkgs, ... }:

{
  home.stateVersion = "25.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Packages you want available
  home.packages = with pkgs; [
    git
    curl
    ripgrep
    rustc
    cargo
    rustfmt
    clippy
    rainfrog
    pandoc
    fzf
    trivy
  ];

  home.file.".local/bin/git-lb" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      branch="$(
        git reflog --pretty='%gs' \
          | sed -nE \
              -e "s/^checkout: moving from .* to (.+)$/\1/p" \
              -e "s/^switch: (.+) -> (.+)$/\2/p" \
              -e "s/^switch: created branch '(.+)'$/\1/p" \
          | awk '!seen[$0]++' \
          | head -n 10 \
          | fzf
      )"

      if [ -n "''${branch:-}" ]; then
        git checkout "$branch"
      fi
    '';
    executable = true;
  };

  # --- Direnv ---
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Example program config
  programs.git = {
    enable = true;
    settings = {
      user.name = "Danny";

      core.editor = "vi";
      rerere.enabled = true;
    };
  };

  programs.atuin.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
