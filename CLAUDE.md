# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A digital shed — personal scripts and config files only. No applications, no notes. No symlinking/installation logic, no build system, no test framework.

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

## Script Categories

- `setup/` — one-time environment setup scripts (install tools, configure system)
- `utils/` — recurring utility scripts (helpers, sync tools)

## Adding a Script

Copy the relevant template and fill in description and body:

```bash
# Linux — replace CATEGORY with setup or utils, SLUG with script name
cp templates/linux.sh scripts/linux/CATEGORY/SLUG.sh
chmod +x scripts/linux/CATEGORY/SLUG.sh

# Windows
cp templates/windows.ps1 scripts/windows/CATEGORY/SLUG.ps1
```

## Adding a Config File

Drop the file into `config/<category>/` named as it would be deployed (e.g. `.gitconfig`, `.zshrc`). Add a new subdirectory for a new tool/context.
