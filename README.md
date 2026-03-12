# Digital Shed

A collection of personal scripts and config files.

## Structure

| Path                     | Purpose                                         |
| ------------------------ | ----------------------------------------------- |
| `scripts/linux/setup/`   | Linux environment bootstrap scripts             |
| `scripts/linux/utils/`   | Linux day-to-day utility scripts                |
| `scripts/windows/setup/` | Windows bootstrap scripts (Scoop, services)     |
| `scripts/windows/utils/` | Windows utility scripts                         |
| `config/`                | Dotfiles and config snippets, named as deployed |
| `templates/`             | Starter templates for new scripts               |

## Adding a Script

```bash
# Linux
cp templates/linux.sh scripts/linux/ < setup | utils > /my-script.sh
chmod +x scripts/linux/ < setup | utils > /my-script.sh

# Windows
cp templates/windows.ps1 scripts/windows/ < setup | utils > /my-script.ps1
```

## Adding a Config File

Drop the file into `config/` named exactly as it would be deployed
(e.g. `.gitconfig`, `.zshrc`, `starship.toml`).

## Linting

```bash
find scripts/linux -name '*.sh' -exec shellcheck {} + # lint all bash scripts
npx markdownlint-cli2 '**/*.md'                       # lint all markdown files
```

Pre-commit hooks run both automatically:

```bash
uv tool install pre-commit
pre-commit install
```
