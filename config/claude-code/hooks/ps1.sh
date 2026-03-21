#!/usr/bin/env bash
# Claude Code hook: format and lint PowerShell scripts (.ps1)
set -uo pipefail

command -v jq &> /dev/null || exit 0
file_path=$(jq -r 'select(.tool_input.file_path | endswith(".ps1")) | .tool_input.file_path')
[[ -z "$file_path" ]] && exit 0

# Format
if command -v pwsh &> /dev/null; then
  pwsh -Command "Set-Content '$file_path' (Invoke-Formatter -ScriptDefinition (Get-Content '$file_path' -Raw))" 2> /dev/null || true
fi

# Lint
if command -v pwsh &> /dev/null; then
  pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path '$file_path' -EnableExit" 1>&2 || exit 2
fi
