_:

{
  users.users.ddudson = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "ddudson" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild switch";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nixos-rebuild switch --upgrade";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
