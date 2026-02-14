_:

{
  programs.nushell = {
    enable = true;

    envFile.source = ../../files/nushell/env.nu;
    configFile.source = ../../files/nushell/config.nu;
  };
}
