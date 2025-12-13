{ config, lib, pkgs, ... }:

{
  time.timeZone = "Australia/Brisbane";

  services.printing.enable = true;
  services.upower.enable = true;
}
