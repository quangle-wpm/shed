#!/usr/bin/env bash
# Claude Code hook: format and lint shell scripts (.sh)
set -uo pipefail

command -v jq &> /dev/null || exit 0
file_path=$(jq -r 'select(.tool_input.file_path? // "" | endswith(".sh")) | .tool_input.file_path')
[[ -z "$file_path" ]] && exit 0

# Format
if command -v npx &> /dev/null; then
  plugin="$(npm root -g)/prettier-plugin-sh/lib/index.cjs"
  npx prettier --write --plugin "$plugin" "$file_path" 2> /dev/null || true
fi

# Lint
if command -v shellcheck &> /dev/null; then
  shellcheck "$file_path" 1>&2 || exit 2
fi
