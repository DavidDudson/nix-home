[
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
