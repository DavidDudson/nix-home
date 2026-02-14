_:

{
  programs.nushell = {
    enable = true;

    envFile.source = ./env.nu;
    configFile.source = ./config.nu;
  };

  home.file = {
    ".config/nushell/theme.nu".source = ./theme.nu;
    ".config/nushell/menus.nu".source = ./menus.nu;
    ".config/nushell/keybindings.nu".source = ./keybindings.nu;
  };
}
