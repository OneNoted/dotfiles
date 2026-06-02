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
$env.XDG_DATA_DIRS = ($env.XDG_DATA_DIRS? | default "/usr/local/share:/usr/share")
$env.XDG_CONFIG_DIRS = ($env.XDG_CONFIG_DIRS? | default "/etc/xdg")

for dir in [$env.XDG_CONFIG_HOME $env.XDG_DATA_HOME $env.XDG_STATE_HOME $env.XDG_CACHE_HOME $env.XDG_BIN_HOME] {
    if not ($dir | path exists) {
        mkdir $dir
    }
}

$env.BASH_ENV = ($env.BASH_ENV? | default ($env.XDG_CONFIG_HOME | path join "bash" "bashenv"))
$env.LESSHISTFILE = ($env.LESSHISTFILE? | default ($env.XDG_STATE_HOME | path join "less" "history"))
$env.CARGO_HOME = ($env.CARGO_HOME? | default ($env.XDG_DATA_HOME | path join "cargo"))
$env.RUSTUP_HOME = ($env.RUSTUP_HOME? | default ($env.XDG_DATA_HOME | path join "rustup"))
$env.GOPATH = ($env.GOPATH? | default ($env.XDG_DATA_HOME | path join "go"))
$env.GOBIN = ($env.GOBIN? | default $env.XDG_BIN_HOME)
$env.GOCACHE = ($env.GOCACHE? | default ($env.XDG_CACHE_HOME | path join "go-build"))
$env.GOMODCACHE = ($env.GOMODCACHE? | default ($env.XDG_CACHE_HOME | path join "go" "mod"))
$env.PYTHON_EGG_CACHE = ($env.PYTHON_EGG_CACHE? | default ($env.XDG_CACHE_HOME | path join "python-eggs"))
$env.PYTHON_HISTORY = ($env.PYTHON_HISTORY? | default ($env.XDG_STATE_HOME | path join "python" "history"))
$env.MYPY_CACHE_DIR = ($env.MYPY_CACHE_DIR? | default ($env.XDG_CACHE_HOME | path join "mypy"))
$env.RUFF_CACHE_DIR = ($env.RUFF_CACHE_DIR? | default ($env.XDG_CACHE_HOME | path join "ruff"))
$env.UV_CACHE_DIR = ($env.UV_CACHE_DIR? | default ($env.XDG_CACHE_HOME | path join "uv"))
$env.UV_PYTHON_CACHE_DIR = ($env.UV_PYTHON_CACHE_DIR? | default ($env.XDG_CACHE_HOME | path join "uv" "python"))
$env.UV_PYTHON_INSTALL_DIR = ($env.UV_PYTHON_INSTALL_DIR? | default ($env.XDG_DATA_HOME | path join "uv" "python"))
$env.UV_TOOL_DIR = ($env.UV_TOOL_DIR? | default ($env.XDG_DATA_HOME | path join "uv" "tools"))
$env.UV_TOOL_BIN_DIR = ($env.UV_TOOL_BIN_DIR? | default $env.XDG_BIN_HOME)
$env.PIPX_HOME = ($env.PIPX_HOME? | default ($env.XDG_DATA_HOME | path join "pipx"))
$env.PIPX_BIN_DIR = ($env.PIPX_BIN_DIR? | default $env.XDG_BIN_HOME)
$env.PYENV_ROOT = ($env.PYENV_ROOT? | default ($env.XDG_DATA_HOME | path join "pyenv"))
$env.POETRY_HOME = ($env.POETRY_HOME? | default ($env.XDG_DATA_HOME | path join "pypoetry"))
$env.POETRY_CONFIG_DIR = ($env.POETRY_CONFIG_DIR? | default ($env.XDG_CONFIG_HOME | path join "pypoetry"))
$env.POETRY_CACHE_DIR = ($env.POETRY_CACHE_DIR? | default ($env.XDG_CACHE_HOME | path join "pypoetry"))
$env.POETRY_DATA_DIR = ($env.POETRY_DATA_DIR? | default ($env.XDG_DATA_HOME | path join "pypoetry"))
$env.BUN_INSTALL = ($env.BUN_INSTALL? | default ($env.XDG_DATA_HOME | path join "bun"))
$env.BUN_INSTALL_CACHE_DIR = ($env.BUN_INSTALL_CACHE_DIR? | default ($env.XDG_CACHE_HOME | path join "bun" "install" "cache"))
$env.BUN_INSTALL_GLOBAL_DIR = ($env.BUN_INSTALL_GLOBAL_DIR? | default ($env.XDG_DATA_HOME | path join "bun" "install" "global"))
$env.BUN_INSTALL_BIN = ($env.BUN_INSTALL_BIN? | default $env.XDG_BIN_HOME)
$env.BUN_RUNTIME_TRANSPILER_CACHE_PATH = ($env.BUN_RUNTIME_TRANSPILER_CACHE_PATH? | default ($env.XDG_CACHE_HOME | path join "bun" "transpiler"))
$env.COREPACK_HOME = ($env.COREPACK_HOME? | default ($env.XDG_CACHE_HOME | path join "corepack"))
$env.NODE_REPL_HISTORY = ($env.NODE_REPL_HISTORY? | default ($env.XDG_STATE_HOME | path join "node" "repl_history"))
$env.GRADLE_USER_HOME = ($env.GRADLE_USER_HOME? | default ($env.XDG_DATA_HOME | path join "gradle"))
$env.MAVEN_OPTS = ($env.MAVEN_OPTS? | default ("-Dmaven.repo.local=" + ($env.XDG_CACHE_HOME | path join "maven" "repository")))
$env.NPM_CONFIG_USERCONFIG = ($env.NPM_CONFIG_USERCONFIG? | default ($env.XDG_CONFIG_HOME | path join "npm" "npmrc"))
$env.NPM_CONFIG_CACHE = ($env.NPM_CONFIG_CACHE? | default ($env.XDG_CACHE_HOME | path join "npm"))
$env.NPM_CONFIG_PREFIX = ($env.NPM_CONFIG_PREFIX? | default ($env.XDG_DATA_HOME | path join "npm"))
$env.NPM_CONFIG_LOGS_DIR = ($env.NPM_CONFIG_LOGS_DIR? | default ($env.XDG_STATE_HOME | path join "npm" "logs"))
$env.npm_config_devdir = ($env.npm_config_devdir? | default ($env.XDG_CACHE_HOME | path join "electron-gyp"))
$env.PNPM_HOME = ($env.PNPM_HOME? | default ($env.XDG_DATA_HOME | path join "pnpm"))
$env.NVM_DIR = ($env.NVM_DIR? | default ($env.XDG_DATA_HOME | path join "nvm"))
$env.NODENV_ROOT = ($env.NODENV_ROOT? | default ($env.XDG_DATA_HOME | path join "nodenv"))
$env.N_PREFIX = ($env.N_PREFIX? | default ($env.XDG_DATA_HOME | path join "n"))
$env.YARN_CACHE_FOLDER = ($env.YARN_CACHE_FOLDER? | default ($env.XDG_CACHE_HOME | path join "yarn"))
$env.PUB_CACHE = ($env.PUB_CACHE? | default ($env.XDG_DATA_HOME | path join "pub-cache"))
$env.DOCKER_CONFIG = ($env.DOCKER_CONFIG? | default ($env.XDG_CONFIG_HOME | path join "docker"))
$env.ANDROID_USER_HOME = ($env.ANDROID_USER_HOME? | default ($env.XDG_DATA_HOME | path join "android"))
$env.K9SCONFIG = ($env.K9SCONFIG? | default ($env.XDG_CONFIG_HOME | path join "k9s"))
$env.KUBECONFIG = ($env.KUBECONFIG? | default ($env.XDG_CONFIG_HOME | path join "kube" "config"))
$env.TALOSCONFIG = ($env.TALOSCONFIG? | default ($env.XDG_CONFIG_HOME | path join "talos" "config"))
$env.SIDEROV1_KEYS_DIR = ($env.SIDEROV1_KEYS_DIR? | default ($env.XDG_CONFIG_HOME | path join "talos" "keys"))
$env.OCI_CLI_CONFIG_FILE = ($env.OCI_CLI_CONFIG_FILE? | default ($env.XDG_CONFIG_HOME | path join "oci" "config"))
$env.OCI_CLI_RC_FILE = ($env.OCI_CLI_RC_FILE? | default ($env.XDG_CONFIG_HOME | path join "oci" "oci_cli_rc"))
$env.HELM_CACHE_HOME = ($env.HELM_CACHE_HOME? | default ($env.XDG_CACHE_HOME | path join "helm"))
$env.HELM_CONFIG_HOME = ($env.HELM_CONFIG_HOME? | default ($env.XDG_CONFIG_HOME | path join "helm"))
$env.HELM_DATA_HOME = ($env.HELM_DATA_HOME? | default ($env.XDG_DATA_HOME | path join "helm"))
$env.ANSIBLE_HOME = ($env.ANSIBLE_HOME? | default ($env.XDG_DATA_HOME | path join "ansible"))
$env.PARALLEL_HOME = ($env.PARALLEL_HOME? | default ($env.XDG_CONFIG_HOME | path join "parallel"))
$env.PLATFORMIO_CORE_DIR = ($env.PLATFORMIO_CORE_DIR? | default ($env.XDG_DATA_HOME | path join "platformio"))
$env.PLATFORMIO_CACHE_DIR = ($env.PLATFORMIO_CACHE_DIR? | default ($env.XDG_CACHE_HOME | path join "platformio"))
$env.CUDA_CACHE_PATH = ($env.CUDA_CACHE_PATH? | default ($env.XDG_CACHE_HOME | path join "nvidia" "ComputeCache"))
$env.__GL_SHADER_DISK_CACHE_PATH = ($env.__GL_SHADER_DISK_CACHE_PATH? | default ($env.XDG_CACHE_HOME | path join "nvidia" "GLCache"))
$env.FLY_CONFIG_DIR = ($env.FLY_CONFIG_DIR? | default ($env.XDG_CONFIG_HOME | path join "fly"))
$env.MITMPROXY_CONF_DIR = ($env.MITMPROXY_CONF_DIR? | default ($env.XDG_CONFIG_HOME | path join "mitmproxy"))
$env.TF_CLI_CONFIG_FILE = ($env.TF_CLI_CONFIG_FILE? | default ($env.XDG_CONFIG_HOME | path join "terraform" "terraformrc"))
$env.TF_PLUGIN_CACHE_DIR = ($env.TF_PLUGIN_CACHE_DIR? | default ($env.XDG_CACHE_HOME | path join "terraform" "plugin-cache"))
$env.WGETRC = ($env.WGETRC? | default ($env.XDG_CONFIG_HOME | path join "wget" "wgetrc"))
$env.MISE_CONFIG_DIR = ($env.MISE_CONFIG_DIR? | default ($env.XDG_CONFIG_HOME | path join "mise"))
$env.MISE_DATA_DIR = ($env.MISE_DATA_DIR? | default ($env.XDG_DATA_HOME | path join "mise"))
$env.MISE_CACHE_DIR = ($env.MISE_CACHE_DIR? | default ($env.XDG_CACHE_HOME | path join "mise"))
$env.MISE_STATE_DIR = ($env.MISE_STATE_DIR? | default ($env.XDG_STATE_HOME | path join "mise"))
$env.STARSHIP_CONFIG = ($env.STARSHIP_CONFIG? | default ($env.XDG_CONFIG_HOME | path join "starship.toml"))
$env.STARSHIP_CACHE = ($env.STARSHIP_CACHE? | default ($env.XDG_CACHE_HOME | path join "starship"))
$env.FORGE_CONFIG = ($env.FORGE_CONFIG? | default ($env.XDG_CONFIG_HOME | path join "forge"))
$env.AUDIBLE_CONFIG_DIR = ($env.AUDIBLE_CONFIG_DIR? | default ($env.XDG_CONFIG_HOME | path join "audible"))
$env.AUDIBLE_PLUGIN_DIR = ($env.AUDIBLE_PLUGIN_DIR? | default ($env.XDG_DATA_HOME | path join "audible" "plugins"))
$env.PI_CODING_AGENT_DIR = ($env.PI_CODING_AGENT_DIR? | default ($env.XDG_DATA_HOME | path join "pi" "agent"))
$env.EMACSDIR = ($env.EMACSDIR? | default ($env.XDG_CONFIG_HOME | path join "emacs"))
$env.DOOMDIR = ($env.DOOMDIR? | default ($env.XDG_CONFIG_HOME | path join "doom"))
$env.DOOMPROFILE = ($env.DOOMPROFILE? | default "default")
$env.GTK_USE_PORTAL = ($env.GTK_USE_PORTAL? | default "1")

for dir in [
    $env.GOPATH
    ($env.PYTHON_HISTORY | path dirname)
    $env.ANSIBLE_HOME
    $env.PLATFORMIO_CACHE_DIR
    $env.npm_config_devdir
    $env.CUDA_CACHE_PATH
    $env.__GL_SHADER_DISK_CACHE_PATH
    $env.FLY_CONFIG_DIR
    $env.MITMPROXY_CONF_DIR
    $env.AUDIBLE_CONFIG_DIR
    $env.AUDIBLE_PLUGIN_DIR
    $env.PI_CODING_AGENT_DIR
    $env.TF_PLUGIN_CACHE_DIR
] {
    if not ($dir | path exists) {
        mkdir $dir
    }
}

for entry in [
    ($env.NPM_CONFIG_PREFIX | path join "bin")
    ($env.BUN_INSTALL | path join "bin")
    ($env.CARGO_HOME | path join "bin")
    $env.XDG_BIN_HOME
    ($env.EMACSDIR | path join "bin")
] {
    if not ($env.PATH | any {|path_entry| $path_entry == $entry }) {
        $env.PATH = ($env.PATH | prepend $entry)
    }
}

let inits_dir = ($env.XDG_CONFIG_HOME | path join "nushell" "inits")
if not ($inits_dir | path exists) {
    mkdir $inits_dir
}

for file in [".zoxide.nu", "starship.nu", "atuin.nu"] {
    let init_file = ($inits_dir | path join $file)
    if not ($init_file | path exists) {
        "" | save -f $init_file
    }
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
    atuin init nu --disable-up-arrow | save -f ($inits_dir | path join "atuin.nu")
}
