#!/usr/bin/env bash
# Claude Code hook (Stop): auto-fix and lint all modified files before the agent
# finishes. Remaining errors are reported with instructions to delegate to Sonnet.
set -uo pipefail

# If Claude is already continuing from a previous stop hook, let it stop
command -v jq &> /dev/null || exit 0
if [[ "$(jq -r '.stop_hook_active // false')" == "true" ]]; then
  exit 0
fi

# Collect modified files (staged + unstaged + untracked)
mapfile -t files < <(
  {
    git diff --name-only 2> /dev/null
    git diff --cached --name-only 2> /dev/null
    git ls-files --others --exclude-standard 2> /dev/null
  } | sort -u
)

[[ ${#files[@]} -eq 0 ]] && exit 0

sh_files=()
md_files=()
ps1_files=()
eslint_files=()
need_astro_check=false

for file in "${files[@]}"; do
  [[ -f "$file" ]] || continue
  case "$file" in
    *.sh) sh_files+=("$file") ;;
    *.md) md_files+=("$file") ;;
    *.ps1) ps1_files+=("$file") ;;
    *.astro | *.ts | *.tsx | *.jsx | *.js)
      eslint_files+=("$file")
      [[ "$file" =~ \.(astro|ts)$ ]] && need_astro_check=true
      ;;
  esac
done

# Set up markdownlint config (shared by auto-fix and lint phases)
md_config_args=()
if [[ ${#md_files[@]} -gt 0 ]] && command -v npx &> /dev/null; then
  if [[ -f .markdownlint.json ]]; then
    md_config_args=(--config .markdownlint.json)
  else
    _cfg=$(mktemp /tmp/mdl-XXXXXX.json) && printf '{"MD013":false}\n' > "$_cfg"
    md_config_args=(--config "$_cfg")
    trap 'rm -f "$_cfg"' EXIT
  fi
fi

# ── Phase 1: Auto-fix ────────────────────────────────────────────────────────

# Markdownlint auto-fix
if [[ ${#md_files[@]} -gt 0 && ${#md_config_args[@]} -gt 0 ]]; then
  npx markdownlint-cli2 --fix "${md_config_args[@]}" "${md_files[@]}" &> /dev/null || true
fi

# ESLint auto-fix (also reports remaining errors, but we re-check in phase 2)
if [[ ${#eslint_files[@]} -gt 0 ]] && compgen -G "eslint.config.*" > /dev/null; then
  npx eslint --fix "${eslint_files[@]}" &> /dev/null || true
fi

# ── Phase 2: Lint (check for remaining errors) ───────────────────────────────

lint_errors=""

# Shellcheck (no auto-fix available)
if [[ ${#sh_files[@]} -gt 0 ]] && command -v shellcheck &> /dev/null; then
  output=$(shellcheck "${sh_files[@]}" 2>&1) || lint_errors+="$output"$'\n'
fi

# Markdownlint (remaining after auto-fix)
if [[ ${#md_files[@]} -gt 0 && ${#md_config_args[@]} -gt 0 ]]; then
  output=$(npx markdownlint-cli2 "${md_config_args[@]}" "${md_files[@]}" 2>&1) || lint_errors+="$output"$'\n'
fi

# PSScriptAnalyzer (no reliable auto-fix)
if [[ ${#ps1_files[@]} -gt 0 ]] && command -v pwsh &> /dev/null; then
  for file in "${ps1_files[@]}"; do
    output=$(pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path '$file' -EnableExit" 2>&1) || lint_errors+="$output"$'\n'
  done
fi

# ESLint (remaining after auto-fix)
if [[ ${#eslint_files[@]} -gt 0 ]] && compgen -G "eslint.config.*" > /dev/null; then
  output=$(npx eslint "${eslint_files[@]}" 2>&1) || lint_errors+="$output"$'\n'
fi

# Astro type-check (run once for all files)
if $need_astro_check && compgen -G "astro.config.*" > /dev/null; then
  output=$(npx astro check 2>&1) || lint_errors+="$output"$'\n'
fi

# ── Report ────────────────────────────────────────────────────────────────────

if [[ -n "$lint_errors" ]]; then
  # JSON output with exit 0 for structured decision control.
  # Instructs Claude to delegate fixing to a Sonnet subagent.
  jq -n --arg errors "$lint_errors" \
    '{"decision":"block","reason":("Lint errors remain after auto-fix. Spawn a subagent (model: sonnet) to fix these errors:\n" + $errors)}'
fi
exit 0
