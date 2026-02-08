{ config, lib, pkgs, ... }:

{
  programs.nushell = {
    enable = true;

    envFile.text = ''
      $env.EDITOR = "hx"
      $env.PATH = ($env.PATH | split row (char esep) | prepend /home/ddudson/.apps | append /usr/bin/env)
    '';

    configFile.text = ''
      let darculaTheme = {
          binary: '#cc7832'
          block: '#9876aa'
          cell-path: '#a9b7c6'
          closure: '#629755'
          custom: '#ffffff'
          duration: '#bbb529'
          float: '#4eade5'
          glob: '#ffffff'
          int: '#cc7832'
          list: '#629755'
          nothing: '#4eade5'
          range: '#bbb529'
          record: '#629755'
          string: '#6a8759'

          bool: {|| if $in { '#629755' } else { '#bbb529' } }

          datetime: {|| (date now) - $in |
              if $in < 1hr {
                  { fg: '#4eade5' attr: 'b' }
              } else if $in < 6hr {
                  '#4eade5'
              } else if $in < 1day {
                  '#bbb529'
              } else if $in < 3day {
                  '#6a8759'
              } else if $in < 1wk {
                  { fg: '#6a8759' attr: 'b' }
              } else if $in < 6wk {
                  '#629755'
              } else if $in < 52wk {
                  '#9876aa'
              } else { 'dark_gray' }
          }

          filesize: {|e|
              if $e == 0b {
                  '#a9b7c6'
              } else if $e < 1mb {
                  '#629755'
              } else {{ fg: '#9876aa' }}
          }

          shape_and: { fg: '#cc7832' attr: 'b' }
          shape_binary: { fg: '#cc7832' attr: 'b' }
          shape_block: { fg: '#9876aa' attr: 'b' }
          shape_bool: '#629755'
          shape_closure: { fg: '#629755' attr: 'b' }
          shape_custom: '#6a8759'
          shape_datetime: { fg: '#629755' attr: 'b' }
          shape_directory: '#629755'
          shape_external: '#629755'
          shape_external_resolved: '#629755'
          shape_externalarg: { fg: '#6a8759' attr: 'b' }
          shape_filepath: '#629755'
          shape_flag: { fg: '#9876aa' attr: 'b' }
          shape_float: { fg: '#4eade5' attr: 'b' }
          shape_garbage: { fg: '#FFFFFF' bg: '#FF0000' attr: 'b' }
          shape_glob_interpolation: { fg: '#629755' attr: 'b' }
          shape_globpattern: { fg: '#629755' attr: 'b' }
          shape_int: { fg: '#cc7832' attr: 'b' }
          shape_internalcall: { fg: '#629755' attr: 'b' }
          shape_keyword: { fg: '#cc7832' attr: 'b' }
          shape_list: { fg: '#629755' attr: 'b' }
          shape_literal: '#9876aa'
          shape_match_pattern: '#6a8759'
          shape_matching_brackets: { attr: 'u' }
          shape_nothing: '#4eade5'
          shape_operator: '#bbb529'
          shape_or: { fg: '#cc7832' attr: 'b' }
          shape_pipe: { fg: '#cc7832' attr: 'b' }
          shape_range: { fg: '#bbb529' attr: 'b' }
          shape_raw_string: { fg: '#ffffff' attr: 'b' }
          shape_record: { fg: '#629755' attr: 'b' }
          shape_redirection: { fg: '#cc7832' attr: 'b' }
          shape_signature: { fg: '#6a8759' attr: 'b' }
          shape_string: '#6a8759'
          shape_string_interpolation: { fg: '#629755' attr: 'b' }
          shape_table: { fg: '#9876aa' attr: 'b' }
          shape_vardecl: { fg: '#9876aa' attr: 'u' }
          shape_variable: '#cc7832'

          foreground: '#a9b7c6'
          background: '#2b2b2b'
          cursor: '#a9b7c6'

          empty: '#9876aa'
          header: { fg: '#6a8759' attr: 'b' }
          hints: '#606366'
          leading_trailing_space_bg: { attr: 'n' }
          row_index: { fg: '#6a8759' attr: 'b' }
          search_result: { fg: '#4eade5' bg: '#a9b7c6' }
          separator: '#a9b7c6'
      }

      let carapace_completer = {|spans|
          carapace $spans.0 nushell ...$spans | from json
      }

      $env.config = {
          show_banner: false

          ls: {
              use_ls_colors: true
              clickable_links: true
          }

          rm: {
              always_trash: false
          }

          table: {
              mode: rounded
              index_mode: always
              show_empty: true
              padding: { left: 1, right: 1 }
              trim: {
                  methodology: wrapping
                  wrapping_try_keep_words: true
                  truncating_suffix: "..."
              }
              header_on_separator: false
              footer_inheritance: false
          }

          error_style: "fancy"

          display_errors: {
              exit_code: false
              termination_signal: true
          }

          history: {
              max_size: 100_000
              sync_on_enter: true
              file_format: "plaintext"
              isolation: false
          }

          completions: {
              case_sensitive: false
              quick: true
              partial: true
              algorithm: "fuzzy"
              sort: "smart"
              external: {
                  enable: true
                  max_results: 100
                  completer: $carapace_completer
              }
              use_ls_colors: true
          }

          cursor_shape: {
              emacs: line
              vi_insert: block
              vi_normal: underscore
          }

          color_config: $darculaTheme
          footer_mode: 25
          float_precision: 2
          buffer_editor: null
          use_ansi_coloring: true
          bracketed_paste: true
          edit_mode: vi

          shell_integration: {
              osc2: true
              osc7: true
              osc8: true
              osc9_9: false
              osc133: true
              osc633: true
              reset_application_mode: true
          }

          render_right_prompt_on_last_line: false
          use_kitty_protocol: true
          highlight_resolved_externals: false
          recursion_limit: 50

          plugins: {}

          plugin_gc: {
              default: {
                  enabled: true
                  stop_after: 10sec
              }
              plugins: {}
          }

          hooks: {
              pre_prompt: [{ null }]
              pre_execution: [{ null }]
              env_change: {
                  PWD: [{|before, after| null }]
              }
              display_output: "if (term size).columns >= 100 { table -e } else { table }"
              command_not_found: { null }
          }

          menus: [
              {
                  name: completion_menu
                  only_buffer_difference: false
                  marker: "| "
                  type: {
                      layout: columnar
                      columns: 4
                      col_width: 20
                      col_padding: 2
                  }
                  style: {
                      text: green
                      selected_text: { attr: r }
                      description_text: yellow
                      match_text: { attr: u }
                      selected_match_text: { attr: ur }
                  }
              }
              {
                  name: ide_completion_menu
                  only_buffer_difference: false
                  marker: "| "
                  type: {
                      layout: ide
                      min_completion_width: 0,
                      max_completion_width: 50,
                      max_completion_height: 10,
                      padding: 0,
                      border: true,
                      cursor_offset: 0,
                      description_mode: "prefer_right"
                      min_description_width: 0
                      max_description_width: 50
                      max_description_height: 10
                      description_offset: 1
                      correct_cursor_pos: false
                  }
                  style: {
                      text: green
                      selected_text: { attr: r }
                      description_text: yellow
                      match_text: { attr: u }
                      selected_match_text: { attr: ur }
                  }
              }
              {
                  name: history_menu
                  only_buffer_difference: true
                  marker: "? "
                  type: {
                      layout: list
                      page_size: 10
                  }
                  style: {
                      text: green
                      selected_text: green_reverse
                      description_text: yellow
                  }
              }
              {
                  name: help_menu
                  only_buffer_difference: true
                  marker: "? "
                  type: {
                      layout: description
                      columns: 4
                      col_width: 20
                      selection_rows: 4
                      description_rows: 10
                  }
                  style: {
                      text: green
                      selected_text: green_reverse
                      description_text: yellow
                  }
              }
          ]

          keybindings: [
              {
                  name: completion_menu
                  modifier: none
                  keycode: tab
                  mode: [emacs vi_normal vi_insert]
                  event: {
                      until: [
                          { send: menu name: completion_menu }
                          { send: menunext }
                          { edit: complete }
                      ]
                  }
              }
              {
                  name: ide_completion_menu
                  modifier: control
                  keycode: space
                  mode: [emacs vi_normal vi_insert]
                  event: {
                      until: [
                          { send: menu name: ide_completion_menu }
                          { send: menunext }
                          { edit: complete }
                      ]
                  }
              }
              {
                  name: history_menu
                  modifier: control
                  keycode: char_r
                  mode: [emacs, vi_insert, vi_normal]
                  event: { send: menu name: history_menu }
              }
              {
                  name: help_menu
                  modifier: none
                  keycode: f1
                  mode: [emacs, vi_insert, vi_normal]
                  event: { send: menu name: help_menu }
              }
              {
                  name: escape
                  modifier: none
                  keycode: escape
                  mode: [emacs, vi_normal, vi_insert]
                  event: { send: esc }
              }
              {
                  name: cancel_command
                  modifier: control
                  keycode: char_c
                  mode: [emacs, vi_normal, vi_insert]
                  event: { send: ctrlc }
              }
              {
                  name: quit_shell
                  modifier: control
                  keycode: char_d
                  mode: [emacs, vi_normal, vi_insert]
                  event: { send: ctrld }
              }
              {
                  name: clear_screen
                  modifier: control
                  keycode: char_l
                  mode: [emacs, vi_normal, vi_insert]
                  event: { send: clearscreen }
              }
              {
                  name: open_command_editor
                  modifier: control
                  keycode: char_o
                  mode: [emacs, vi_normal, vi_insert]
                  event: { send: openeditor }
              }
              {
                  name: move_up
                  modifier: none
                  keycode: up
                  mode: [emacs, vi_normal, vi_insert]
                  event: {
                      until: [
                          { send: menuup }
                          { send: up }
                      ]
                  }
              }
              {
                  name: move_down
                  modifier: none
                  keycode: down
                  mode: [emacs, vi_normal, vi_insert]
                  event: {
                      until: [
                          { send: menudown }
                          { send: down }
                      ]
                  }
              }
              {
                  name: move_right_or_take_history_hint
                  modifier: none
                  keycode: right
                  mode: [emacs, vi_normal, vi_insert]
                  event: {
                      until: [
                          { send: historyhintcomplete }
                          { send: menuright }
                          { send: right }
                      ]
                  }
              }
              {
                  name: move_to_line_end_or_take_history_hint
                  modifier: none
                  keycode: end
                  mode: [emacs, vi_normal, vi_insert]
                  event: {
                      until: [
                          { send: historyhintcomplete }
                          { edit: movetolineend }
                      ]
                  }
              }
          ]
      }

      mkdir ($nu.data-dir | path join "vendor/autoload")
      starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
    '';
  };
}
