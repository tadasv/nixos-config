{ config, pkgs, ... }:
{
  # programs.home-manager.enable = true;

  home.stateVersion = "22.11";
  home.username = "vptr";
  home.homeDirectory = "/home/vptr";

  home.packages = with pkgs; [
    vim
    git
    tmux
    htop
    tree
    watch
    jq
    chromium
    firefox
    alacritty
  ];

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "vim";
    PAGER = "less -FirSwX";
  };

  programs.git = {
    enable = true;
    userName = "Tadas Vilkeliskis";
    userEmail = "vilkeliskis.t@gmail.com";
  };

  home.file.".xinitrc".source = ./xinitrc;

  xdg.enable = true;
  xdg.configFile."i3/config".text = builtins.readFile ./i3;
}
