#!/usr/bin/env bash
# Claude Code hook: format markdown files (.md)
set -uo pipefail

command -v jq &> /dev/null || exit 0
file_path=$(jq -r 'select(.tool_input.file_path? // "" | endswith(".md")) | .tool_input.file_path')
[[ -z "$file_path" ]] && exit 0

# Format
if command -v npx &> /dev/null; then
  npx prettier --write "$file_path" 2> /dev/null || true
fi
