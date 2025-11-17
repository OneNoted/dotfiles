if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Fastfetch Greeting
set fish_greeting

##### Inits #####

# Television
tv init fish | source

# Starship
starship init fish | source

# Zoxide
zoxide init fish | source

# Atuin 
atuin init fish --disable-up-arrow | source

# Carapace
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense' # optional
carapace _carapace | source

# fzf
fzf --fish | FZF_CTRL_R_COMMAND= FZF_CTRL_T_COMMAND= source

##### Aliases #####

alias yay paru
alias pamcan pacman
alias clear "printf '\033[2J\033[3J\033[1;1H'"
alias cd z
alias find fd
alias vim nvim
alias vi nvim

# back aliases 
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# eza aliases
alias ls='eza -al --color=always --group-directories-first --icons' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons' # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons' # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a | grep -e '^\.'" # show only dotfiles

# Grep aliases
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias gitpkg='pacman -Q | grep -i "\-git" | wc -l' # count git packages

# Get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# Recent installed packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

##### Variables #####
set -gx VISUAL /usr/bin/nvim
set -gx EDITOR /usr/bin/nvim
set -gx SUDO_EDITOR /usr/bin/nvim

# Yazi Shell Wrapper
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
