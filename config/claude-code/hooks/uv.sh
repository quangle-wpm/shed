#!/usr/bin/env bash
# Claude Code hook: enforce uv instead of python/pip
set -uo pipefail

command -v jq &> /dev/null || exit 0
cmd=$(jq -r '.tool_input.command // empty')
[[ -z "$cmd" ]] && exit 0

if [[ "$cmd" =~ ^(python|python3|pip|pip3)([[:space:]]|$) ]]; then
  echo "BLOCK: Use 'uv' instead. Examples: 'uv run python ...', 'uv pip install ...'." 1>&2
  exit 2
fi
