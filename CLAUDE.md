# CLAUDE.md

## What This Repo Is

A digital shed — personal scripts and config files only. No applications, no notes. No symlinking/installation logic, no build system, no test framework.

## Linting

```bash
find scripts/linux -name '*.sh' -exec shellcheck {} +                            # lint bash scripts
npx markdownlint-cli2 '**/*.md'                                                  # lint markdown
pwsh -Command "Invoke-ScriptAnalyzer -Path scripts/windows -Recurse -EnableExit" # lint PowerShell
```

Pre-commit hooks run all three plus **prettier** (auto-formats `.sh`, `.md`, and `.ps1` files). Setup: `uv tool install pre-commit && pre-commit install`. Requires `pwsh` and PSScriptAnalyzer (`Install-Module PSScriptAnalyzer`) for the PowerShell hook.

## Adding a Script

Categories: `setup/` (one-time environment setup) | `utils/` (recurring helpers). Copy the relevant template and fill in description and body:

```bash
# Linux — replace CATEGORY with setup or utils, SLUG with script name
cp templates/linux.sh scripts/linux/CATEGORY/SLUG.sh
chmod +x scripts/linux/CATEGORY/SLUG.sh

# Windows (create scripts/windows/CATEGORY/ first if needed)
mkdir -p scripts/windows/CATEGORY
cp templates/windows.ps1 scripts/windows/CATEGORY/SLUG.ps1
```

## Adding a Config File

Drop the file into `config/<category>/` named as it would be deployed (e.g. `.gitconfig`, `.zshrc`). Add a new subdirectory for a new tool/context.

- `config/claude-code/` — Claude Code settings, hooks, and skills (synced to `~/.claude/` via `sync-claude-code.sh`)
- `config/wsl/` — WSL configuration

## Utilities

`scripts/linux/utils/sync-claude-code.sh` — two-way sync between `config/claude-code/` and `~/.claude/`. Requires `jq` and GNU `diff`. Pulls user-side changes first (interactive), then pushes project files (auto-merge with conflict prompts).
