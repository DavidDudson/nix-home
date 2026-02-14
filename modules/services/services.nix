_:

{
  time.timeZone = "Australia/Brisbane";

  services = {
    printing.enable = true;
    upower.enable = true;

    # Secret service (org.freedesktop.secrets) for app credential storage
    gnome.gnome-keyring.enable = true;
  };
}
