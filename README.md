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
# Linux — replace CATEGORY with setup or utils, SLUG with script name
cp templates/linux.sh scripts/linux/CATEGORY/SLUG.sh
chmod +x scripts/linux/CATEGORY/SLUG.sh

# Windows
cp templates/windows.ps1 scripts/windows/CATEGORY/SLUG.ps1
```

## Adding a Config File

Drop the file into `config/<category>/` named as it would be deployed (e.g. `.gitconfig`, `.zshrc`). Add a new subdirectory for a new tool/context.

## Linting

```bash
find scripts/linux -name '*.sh' -exec shellcheck {} +                            # lint bash scripts
npx markdownlint-cli2 '**/*.md'                                                  # lint markdown
pwsh -Command "Invoke-ScriptAnalyzer -Path scripts/windows -Recurse -EnableExit" # lint PowerShell
```

Pre-commit hooks run all three automatically:

```bash
uv tool install pre-commit
pre-commit install
```

Requires `pwsh` and PSScriptAnalyzer (`Install-Module PSScriptAnalyzer`) for the PowerShell hook.
