{ config, pkgs, ... }:

{
  home.username = "danny";
  home.homeDirectory = "/home/danny";

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
    fnm
    bind
    postgresql
    bubblewrap
  ];

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
        user.email = "danny@loxley.digital";
    };
  };

  programs.atuin = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;

    initContent = ''
      eval "$(fnm env --use-on-cd --shell zsh)"
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
