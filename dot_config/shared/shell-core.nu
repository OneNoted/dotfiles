# Shared shell aliases/env vars.
# Keep in sync with .chezmoidata/shell_core.yaml.

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.SUDO_EDITOR = "nvim"

alias cd = z
alias vim = nvim
alias vi = nvim
alias yay = paru
alias clear = printf '\033[2J\033[3J\033[1;1H'
alias pamcan = pacman
alias gitpkg = pacman -Q | grep -i "\\-git" | wc -l
alias jctl = journalctl -p 3 -xb
alias rip = expac --timefmt="%Y-%m-%d %T" "%l\t%n %v" | sort | tail -200 | nl
alias tree = eza --tree --all --icons --group-directories-first
alias cat = bat --paging=never --style=plain
