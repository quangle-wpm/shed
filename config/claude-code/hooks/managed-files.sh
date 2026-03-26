#!/usr/bin/env bash
# Claude Code hook: block direct edits to files managed by quangle-wpm/config
set -uo pipefail

command -v jq &> /dev/null || exit 0
file_path=$(jq -r '.tool_input.file_path // empty')
[[ -z "$file_path" || ! -f "$file_path" ]] && exit 0

# Check first 3 lines for comment header or JSON _managed_by key
if head -3 "$file_path" | grep -qE '(//|#) This file is managed by|"_managed_by"'; then
  echo "BLOCK: $(basename "$file_path") is managed by quangle-wpm/config. Edit the template there instead." 1>&2
  exit 2
fi
