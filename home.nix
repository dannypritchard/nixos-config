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
    fnm
    ffmpeg
    opencode
  ];

  home.file.".local/bin/git-lb" = {
    source = ./scripts/git-lb.sh;
    executable = true;
  };

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
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
