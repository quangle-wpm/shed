#!/usr/bin/env bash
# Claude Code hook: auto-sync config/claude-code files to ~/.claude/ after edits
set -uo pipefail

command -v jq &> /dev/null || exit 0
file_path=$(jq -r '.tool_input.file_path // empty')
[[ -z "$file_path" ]] && exit 0

# Only act on files under a config/claude-code/ directory
[[ "$file_path" == */config/claude-code/* ]] || exit 0

# Derive repo root and locate sync script
repo_root="${file_path%%/config/claude-code/*}"
sync_script="${repo_root}/scripts/linux/utils/sync-claude-code.sh"
[[ -x "$sync_script" ]] || exit 0

"$sync_script" "$file_path" 1>&2
