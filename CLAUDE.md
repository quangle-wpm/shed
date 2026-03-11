# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## What This Repo Is

A digital shed — personal scripts and config files only. No applications, no notes.

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
