#!/usr/bin/env bash
# Claude Code hook (Stop): lint all modified files before the agent finishes
set -uo pipefail

# Collect modified files (staged + unstaged + untracked)
mapfile -t files < <(
  {
    git diff --name-only 2> /dev/null
    git diff --cached --name-only 2> /dev/null
    git ls-files --others --exclude-standard 2> /dev/null
  } | sort -u
)

[[ ${#files[@]} -eq 0 ]] && exit 0

errors=0
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

# Shellcheck
if [[ ${#sh_files[@]} -gt 0 ]] && command -v shellcheck &> /dev/null; then
  shellcheck "${sh_files[@]}" 1>&2 || ((errors++))
fi

# Markdownlint
if [[ ${#md_files[@]} -gt 0 ]] && command -v npx &> /dev/null; then
  config_args=()
  if [[ -f .markdownlint.json ]]; then
    config_args=(--config .markdownlint.json)
  else
    _cfg=$(mktemp /tmp/mdl-XXXXXX.json) && printf '{"MD013":false}\n' > "$_cfg"
    config_args=(--config "$_cfg")
    trap 'rm -f "$_cfg"' EXIT
  fi
  npx markdownlint-cli2 "${config_args[@]}" "${md_files[@]}" 1>&2 || ((errors++))
fi

# PSScriptAnalyzer
if [[ ${#ps1_files[@]} -gt 0 ]] && command -v pwsh &> /dev/null; then
  for file in "${ps1_files[@]}"; do
    pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path '$file' -EnableExit" 1>&2 || ((errors++))
  done
fi

# ESLint (only if eslint config exists in project)
if [[ ${#eslint_files[@]} -gt 0 ]] && compgen -G "eslint.config.*" > /dev/null; then
  npx eslint --fix "${eslint_files[@]}" 1>&2 || ((errors++))
fi

# Astro type-check (only if astro config exists, run once for all files)
if $need_astro_check && compgen -G "astro.config.*" > /dev/null; then
  npx astro check 1>&2 || ((errors++))
fi

[[ $errors -gt 0 ]] && exit 2
exit 0
