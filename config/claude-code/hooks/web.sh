#!/usr/bin/env bash
# Claude Code hook: format and lint web files (.astro, .ts, .tsx, .jsx, .js, .css)
set -uo pipefail

command -v jq &> /dev/null || exit 0
file_path=$(jq -r 'select(.tool_input.file_path? // "" | test("\\.astro$|\\.ts$|\\.tsx$|\\.jsx$|\\.js$|\\.css$")) | .tool_input.file_path')
[[ -z "$file_path" ]] && exit 0

# Format
if command -v npx &> /dev/null; then
  npx prettier --write "$file_path" 2> /dev/null || true
fi

# Lint (only if eslint config exists in project)
if [[ "$file_path" =~ \.(astro|ts|tsx|jsx|js)$ ]] && compgen -G "eslint.config.*" > /dev/null; then
  npx eslint --fix "$file_path" 1>&2 || exit 2
fi

# Type-check (only if astro config exists in project)
if [[ "$file_path" =~ \.(astro|ts)$ ]] && compgen -G "astro.config.*" > /dev/null; then
  npx astro check 1>&2 || exit 2
fi
