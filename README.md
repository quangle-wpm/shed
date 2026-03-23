# Digital Shed

A collection of personal scripts and config files.

## Structure

| Path                   | Purpose                                 |
| ---------------------- | --------------------------------------- |
| `scripts/linux/utils/` | Linux day-to-day utility scripts        |
| `config/claude-code/`  | Claude Code hooks, settings, and skills |
| `config/wsl/`          | WSL configuration files                 |
| `templates/`           | Starter templates for new scripts       |

## Adding a Script

```bash
# Linux — replace CATEGORY with setup or utils, SLUG with script name
mkdir -p scripts/linux/CATEGORY
cp templates/linux.sh scripts/linux/CATEGORY/SLUG.sh
chmod +x scripts/linux/CATEGORY/SLUG.sh

# Windows
mkdir -p scripts/windows/CATEGORY
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
