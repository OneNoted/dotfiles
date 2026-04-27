let custom_keybindings = [
    {
        name: open_tv_sesh
        modifier: control
        keycode: char_s
        mode: [emacs vi_insert vi_normal]
        event: {
            send: ExecuteHostCommand
            cmd: "tv_sesh"
        }
    }
    {
        name: tv_atuin_history
        modifier: control
        keycode: char_r
        mode: [emacs vi_insert vi_normal]
        event: {
            send: ExecuteHostCommand
            cmd: "tv_atuin_shell_history"
        }
    }
]

$env.config.keybindings = (
    $env.config.keybindings
    | where {|binding| ($binding.name? | default "") not-in ["tv_history", "atuin"] }
    | append $custom_keybindings
)
