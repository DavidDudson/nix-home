_:

{
  home.file = {
    ".config/hypr/hypridle.conf".source = ./hypridle.conf;
    ".config/hypr/screensaver-start" = {
      source = ./screensaver-start.sh;
      executable = true;
    };
    ".config/hypr/screensaver-stop" = {
      source = ./screensaver-stop.sh;
      executable = true;
    };
  };
}
