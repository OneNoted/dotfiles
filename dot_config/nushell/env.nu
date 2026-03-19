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

let home = $env.HOME

$env.XDG_CONFIG_HOME = ($env.XDG_CONFIG_HOME? | default ($home | path join ".config"))
$env.XDG_DATA_HOME = ($env.XDG_DATA_HOME? | default ($home | path join ".local" "share"))
$env.XDG_STATE_HOME = ($env.XDG_STATE_HOME? | default ($home | path join ".local" "state"))
$env.XDG_CACHE_HOME = ($env.XDG_CACHE_HOME? | default ($home | path join ".cache"))
$env.XDG_BIN_HOME = ($env.XDG_BIN_HOME? | default ($home | path join ".local" "bin"))
$env.EMACSDIR = ($env.EMACSDIR? | default ($env.XDG_CONFIG_HOME | path join "emacs"))
$env.DOOMDIR = ($env.DOOMDIR? | default ($env.XDG_CONFIG_HOME | path join "doom"))
$env.DOOMPROFILE = ($env.DOOMPROFILE? | default "default")

let xdg_bin = $env.XDG_BIN_HOME
if not ($env.PATH | any {|entry| $entry == $xdg_bin }) {
    $env.PATH = ($env.PATH | prepend $xdg_bin)
}

let emacs_bin = ($env.EMACSDIR | path join "bin")
if not ($env.PATH | any {|entry| $entry == $emacs_bin }) {
    $env.PATH = ($env.PATH | prepend $emacs_bin)
}

let inits_dir = ($env.XDG_CONFIG_HOME | path join "nushell" "inits")
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
