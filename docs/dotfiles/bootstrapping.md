# Bootstrapping (Arch)

A package manifest and bootstrap helper are included for Arch hosts:

```sh
# print the install plan (default mode)
bash bootstrap/bootstrap.sh --plan

# install only the Neovim component
bash bootstrap/nvim.sh --plan

# include optional groups
bash bootstrap/bootstrap.sh --group wm --group nvim --plan

# install on Arch
bash bootstrap/bootstrap.sh --group wm --group nvim --install

# install only Neovim and its config dependencies
bash bootstrap/nvim.sh --install
```

Package data lives in `bootstrap/packages.toml`.

## Niri Under Greetd

Arch's packaged `/usr/bin/niri-session` currently calls
`systemctl --user import-environment` without a variable list. systemd
deprecated that form because it imports the entire shell environment, including
session-local noise like `PWD` and `TERM=linux`, into the user manager.

This repo ships a managed replacement at `~/.local/bin/niri-session` that keeps
the upstream startup flow but only forwards a curated set of session variables
to systemd and D-Bus.

If the host uses `greetd` with `tuigreet`, point the session command at the
managed wrapper instead of the packaged `/usr/bin/niri-session`, for example:

```toml
command = "tuigreet --cmd /home/<user>/.local/bin/niri-session"
```

If the host already points greetd at `/usr/local/bin/niri-session`, keep that
path stable but bridge it back to the managed wrapper:

```sh
sudo ~/.local/bin/niri-session-install-system-bridge
```

That installs a tiny `/usr/local/bin/niri-session` launcher that delegates to
the current user's `~/.local/bin/niri-session`, so session environment fixes in
chezmoi keep applying without hand-editing root-owned files after each change.

## Validation

Run strict local checks before committing:

```sh
just check
```

To run all configured hooks:

```sh
pre-commit run --all-files
```
