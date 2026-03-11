# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A digital shed — personal scripts and config files only. No applications, no notes. No symlinking/installation logic, no build system, no test framework.

## Linting

```bash
find scripts/linux -name '*.sh' -exec shellcheck {} +   # lint bash scripts
markdownlint '**/*.md'                                   # lint markdown
```

Pre-commit hooks run linting automatically:

```bash
uv tool install pre-commit
pre-commit install
```

Note: PowerShell scripts are not linted automatically (PSScriptAnalyzer unavailable on Linux dev machine).

## Script Conventions

### Bash (`scripts/linux/`)

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail`
- Named `kebab-case.sh`, executable bit tracked in git (`chmod +x`)
- Entry point wrapped in `main()` function, called as `main "$@"`

### PowerShell (`scripts/windows/`)

- `#Requires -Version 5.1` + `Set-StrictMode -Version Latest` + `$ErrorActionPreference = 'Stop'`
- Named `kebab-case.ps1`
- Entry point wrapped in `Main` function

### Config files (`config/`)

- Named exactly as deployed (e.g. `.gitconfig`, `.zshrc`, `starship.toml`) — flat layout, no subdirectories
- Files are source references; linking/copying is done manually outside this repo

## Adding a Script

Copy the relevant template and fill in description and body:

```bash
# Linux
cp templates/linux.sh scripts/linux/<setup|utils>/<slug>.sh
chmod +x scripts/linux/<setup|utils>/<slug>.sh

# Windows
cp templates/windows.ps1 scripts/windows/<setup|utils>/<slug>.ps1
```

## Adding a Config File

Drop the file into `config/` named as it would be deployed (e.g. `.gitconfig`, `.zshrc`).
