{ config, lib, pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    theme = {
      mgr = {
        cwd = { fg = "#ff9800"; bold = true; };
        find_keyword = { fg = "#ffb74d"; bold = true; italic = true; underline = true; };
        find_position = { fg = "#ff6600"; bg = "reset"; bold = true; italic = true; };
        marker_copied = { fg = "#50fa7b"; bg = "#50fa7b"; };
        marker_cut = { fg = "#ff5555"; bg = "#ff5555"; };
        marker_marked = { fg = "#ffb74d"; bg = "#ffb74d"; };
        marker_selected = { fg = "#ff9800"; bg = "#ff9800"; };
        count_copied = { fg = "#141414"; bg = "#50fa7b"; };
        count_cut = { fg = "#141414"; bg = "#ff5555"; };
        count_selected = { fg = "#141414"; bg = "#ff9800"; };
        border_symbol = "│";
        border_style = { fg = "#44475a"; };
      };
      tabs = {
        active = { fg = "#141414"; bg = "#ff9800"; bold = true; };
        inactive = { fg = "#ff9800"; bg = "#1a1a1a"; };
      };
      mode = {
        normal_main = { fg = "#141414"; bg = "#ff9800"; bold = true; };
        normal_alt = { fg = "#ff9800"; bg = "#1a1a1a"; };
        select_main = { fg = "#141414"; bg = "#ff5555"; bold = true; };
        select_alt = { fg = "#ff5555"; bg = "#1a1a1a"; };
        unset_main = { fg = "#141414"; bg = "#ff5555"; bold = true; };
        unset_alt = { fg = "#ff5555"; bg = "#1a1a1a"; };
      };
      status = {
        sep_left = { open = ""; close = ""; };
        sep_right = { open = ""; close = ""; };
        perm_sep = { fg = "#44475a"; };
        perm_type = { fg = "#50fa7b"; };
        perm_read = { fg = "#ffb74d"; };
        perm_write = { fg = "#ff5555"; };
        perm_exec = { fg = "#ff9800"; };
        progress_label = { bold = true; };
        progress_normal = { fg = "#ff9800"; bg = "#141414"; };
        progress_error = { fg = "#ffb74d"; bg = "#ff5555"; };
      };
      which = {
        cols = 3;
        mask = { bg = "#141414"; };
        cand = { fg = "#ffb74d"; };
        rest = { fg = "#44475a"; };
        desc = { fg = "#ff9800"; };
        separator = "  ";
        separator_style = { fg = "#44475a"; };
      };
      confirm = {
        border = { fg = "#ff9800"; };
        title = { fg = "#ff9800"; };
        btn_yes = { reversed = true; };
      };
      spot = {
        border = { fg = "#ff9800"; };
        title = { fg = "#ff9800"; };
      };
      notify = {
        title_info = { fg = "#50fa7b"; };
        title_warn = { fg = "#ffb74d"; };
        title_error = { fg = "#ff5555"; };
      };
      pick = {
        border = { fg = "#ff9800"; };
        active = { fg = "#ffb74d"; bold = true; };
      };
      input = {
        border = { fg = "#ff9800"; };
        selected = { reversed = true; };
      };
      cmp = {
        border = { fg = "#ff9800"; };
        active = { reversed = true; };
      };
      tasks = {
        border = { fg = "#ff9800"; };
        hovered = { fg = "#ffb74d"; bold = true; };
      };
      help = {
        on = { fg = "#ff9800"; };
        run = { fg = "#ffb74d"; };
        hovered = { reversed = true; bold = true; };
        footer = { fg = "#141414"; bg = "#ff9800"; };
      };
      filetype = {
        rules = [
          { mime = "image/*"; fg = "#f1fa8c"; }
          { mime = "{audio,video}/*"; fg = "#ff79c6"; }
          { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}"; fg = "#ff5555"; }
          { mime = "application/{pdf,doc,rtf}"; fg = "#8be9fd"; }
          { name = "*/"; fg = "#ff9800"; }
        ];
      };
    };
  };
}
