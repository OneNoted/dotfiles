# env.nu
#
# Installed by:
# version = "0.107.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

let inits_dir = ("~/.config/nushell/inits" | path expand)
if not ($inits_dir | path exists) {
    mkdir $inits_dir
}

for file in [".zoxide.nu", "starship.nu", "carapace.nu", "atuin.nu"] {
    let init_file = ($inits_dir | path join $file)
    if not ($init_file | path exists) {
        "" | save -f $init_file
    }
}

# Carapace
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
if (which carapace | length) > 0 {
    carapace _carapace nushell | save --force ($inits_dir | path join "carapace.nu")
}

# Zoxide
if (which zoxide | length) > 0 {
    zoxide init nushell | save -f ($inits_dir | path join ".zoxide.nu")
}

# Starship
if (which starship | length) > 0 {
    starship init nu | save -f ($inits_dir | path join "starship.nu")
}

# Atuin
if (which atuin | length) > 0 {
    atuin init nu | save -f ($inits_dir | path join "atuin.nu")
}
