#!/usr/bin/env bash
# Claude Code hook: format and lint markdown files (.md)
set -uo pipefail

command -v jq &> /dev/null || exit 0
file_path=$(jq -r 'select(.tool_input.file_path? // "" | endswith(".md")) | .tool_input.file_path')
[[ -z "$file_path" ]] && exit 0

# Format
if command -v npx &> /dev/null; then
  npx prettier --write "$file_path" 2> /dev/null || true
fi

# Lint
if command -v npx &> /dev/null; then
  config_args=()
  [[ -f .markdownlint.json ]] && config_args=(--config .markdownlint.json)
  npx markdownlint-cli2 "${config_args[@]}" "$file_path" 1>&2 || exit 2
fi
