{
  pkgs,
  ...
}:

{
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts-color-emoji # the top bar and sidebar use emoji icons
    font-awesome
  ];
}
