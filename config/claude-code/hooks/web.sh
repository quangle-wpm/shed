#!/usr/bin/env bash
# Claude Code hook: format web files (.astro, .ts, .tsx, .jsx, .js, .css)
set -uo pipefail

command -v jq &> /dev/null || exit 0
file_path=$(jq -r 'select(.tool_input.file_path? // "" | test("\\.astro$|\\.ts$|\\.tsx$|\\.jsx$|\\.js$|\\.css$")) | .tool_input.file_path')
[[ -z "$file_path" ]] && exit 0

# Format
if command -v npx &> /dev/null; then
  npx prettier --write "$file_path" 2> /dev/null || true
fi
