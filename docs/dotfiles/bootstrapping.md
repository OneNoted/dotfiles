# Bootstrapping (Arch)

A package manifest and bootstrap helper are included for Arch hosts:

```sh
# print install plan (default mode)
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

## Validation

Run strict local checks before committing:

```sh
just check
```

To run all configured hooks:

```sh
pre-commit run --all-files
```
