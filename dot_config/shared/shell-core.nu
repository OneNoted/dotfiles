# Shared shell aliases/env vars.
# Keep in sync with .chezmoidata/shell_core.yaml.

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.SUDO_EDITOR = "nvim"

alias cd = z
alias find = fd
alias vim = nvim
alias vi = nvim
alias yay = paru
alias clear = printf '\033[2J\033[3J\033[1;1H'
alias ls = eza --icons --all
