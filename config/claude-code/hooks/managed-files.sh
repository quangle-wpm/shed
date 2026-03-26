#!/usr/bin/env bash
# Claude Code hook: block direct edits to managed files in ~/.claude/
set -uo pipefail

command -v jq &> /dev/null || exit 0
file_path=$(jq -r '.tool_input.file_path // empty')
[[ -z "$file_path" ]] && exit 0

# Resolve to absolute path for reliable comparison
file_path=$(realpath -m "$file_path" 2> /dev/null) || exit 0

# Block edits to user-level Claude config (managed via sync-claude-code.sh)
if [[ "$file_path" == "$HOME/.claude/"* ]]; then
  echo "BLOCK: ${file_path#"$HOME/"} is managed by config/claude-code/. Edit the source there, then run sync-claude-code.sh." 1>&2
  exit 2
fi
