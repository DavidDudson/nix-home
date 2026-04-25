_:

{
  users.users.ddudson = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # Passwordless rebuild via nh / nixos-rebuild. nh invokes two privileged
  # commands during activation:
  #   1. `nix build --no-link --profile /nix/var/nix/profiles/system <path>`
  #   2. `<store>/bin/switch-to-configuration {switch,boot,test}`
  # Rules use globs because store paths change every generation.
  security.sudo.extraRules = [
    {
      users = [ "ddudson" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild *";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix build --no-link --profile /nix/var/nix/profiles/system *";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/nix/store/*/bin/nix build --no-link --profile /nix/var/nix/profiles/system *";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/nix/store/*/bin/switch-to-configuration *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
