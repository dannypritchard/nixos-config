{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Packages you want available
  home.packages = with pkgs; [
    git
    curl
    ripgrep
    jq
    rustc
    cargo
    rustfmt
    clippy
    rainfrog
    pandoc
    atuin
    awscli2
    bind
    postgresql
    fzf
    trivy
    vulnix
    fnm
    ffmpeg
  ];

  home.file.".local/bin/git-lb" = {
    source = ./scripts/git-lb.sh;
    executable = true;
  };

  home.file.".local/bin/nix-flake-audit" = {
    source = ./scripts/nix-flake-audit.sh;
    executable = true;
  };

  home.file.".config/zsh/nix-flake-audit.zsh".source = ./scripts/nix-flake-audit.zsh;

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

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


    initContent = ''
      export PATH="/etc/profiles/per-user/$USER/bin:$PATH"

      export PATH="$HOME/.local/bin:$PATH"

      eval "$(fnm env --use-on-cd --shell zsh)"

      autoload -Uz select-word-style
      select-word-style bash

      # Audit flakes for CVEs
      source "$HOME/.config/zsh/nix-flake-audit.zsh"
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
