_:

{
  programs.helix = {
    enable = true;

    settings = {
      theme = "darcula";

      editor = {
        line-number = "relative";
        mouse = false;
        true-color = true;
        color-modes = true;
        bufferline = "multiple";

        indent-guides = {
          render = true;
        };

        lsp = {
          display-inlay-hints = true;
        };

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker = {
          hidden = false;
        };
      };
    };
  };
}
