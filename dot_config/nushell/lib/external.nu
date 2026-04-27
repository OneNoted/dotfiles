mkdir ($nu.data-dir | path join "vendor/autoload")
tv init nu | save -f ($nu.data-dir | path join "vendor/autoload/tv.nu")

source ~/.config/nushell/inits/.zoxide.nu
source ~/.config/nushell/inits/starship.nu
source ~/.config/nushell/inits/atuin.nu

source ~/.config/shared/shell-core.nu
