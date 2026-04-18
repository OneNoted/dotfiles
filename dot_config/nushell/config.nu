# config.nu
#
# Installed by:
# version = "0.107.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# General

$env.config.buffer_editor = "nvim"
$env.config.edit_mode = "vi"

# Appearance
source ~/.config/nushell/themes/catppuccin_mocha.nu
$env.config.show_banner = false

# Shared shell aliases/env vars from chezmoi data
source ~/.config/shared/shell-core.nu

# Initialize
mkdir ($nu.data-dir | path join "vendor/autoload")
tv init nu | save -f ($nu.data-dir | path join "vendor/autoload/tv.nu")

def --env tv_sesh [] {
    if (which tv | is-empty) {
        return
    }

    if not $nu.is-interactive {
        ^tv sesh
        return
    }

    let command_buffer = (commandline)
    commandline edit --replace ""
    ^tv sesh
    commandline edit --replace $command_buffer
    commandline set-cursor --end
}

def --env tv_atuin_shell_history [] {
    if (which tv | is-empty) or (which atuin | is-empty) {
        return
    }

    let line = (commandline)
    let cursor = (commandline get-cursor)
    let prompt = ($line | str substring 0..$cursor)
    let output = (tv atuin-history --no-status-bar --inline --input $prompt | str trim)

    if ($output | is-not-empty) {
        commandline edit --replace $output
        commandline set-cursor --end
    }
}

$env.config.keybindings = ($env.config.keybindings | append [
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
])

# Zoxide
source ~/.config/nushell/inits/.zoxide.nu
# Starship
source ~/.config/nushell/inits/starship.nu
# Carapace
source ~/.config/nushell/inits/carapace.nu
# Atuin
source ~/.config/nushell/inits/atuin.nu

$env.config.keybindings = (
    $env.config.keybindings
    | where {|binding| ($binding.name? | default "") not-in ["tv_history", "atuin"] }
    | append [
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
)
