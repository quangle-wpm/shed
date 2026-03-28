#!/usr/bin/env bash
# Description: Sync Claude Code config between config/claude-code/ and ~/.claude/.
#              Runs user→project (ask) then project→user (auto+conflict prompts).
# Usage: ./sync-claude-code.sh [FILE]
#        No args: full two-way sync (user→project then project→user).
#        FILE:    sync a single project file to ~/.claude/ (project→user only).

set -euo pipefail

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/config/claude-code"
USER_DIR="${HOME}/.claude"

# Print an indented status line.
log() { printf '  %s\n' "$1"; }

# Verify jq and GNU diff are present. Exits with error message if not.
check_deps() {
  local ok=true
  command -v jq > /dev/null 2>&1 \
    || {
      echo "ERROR: jq is required. Install: sudo apt install jq"
      ok=false
    }
  diff --version 2> /dev/null | grep -q GNU \
    || {
      echo "ERROR: GNU diff is required. Install: sudo apt install diffutils"
      ok=false
    }
  [[ "${ok}" == true ]] || exit 1
}

# Map a config/claude-code/<rel> path to its ~/.claude/<rel> counterpart.
user_path() { echo "${USER_DIR}/${1#"${PROJ_DIR}/"}"; }

# Prompt [y/N], reads from /dev/tty. Returns 0 for yes, 1 for no/non-interactive.
ask_yn() {
  local prompt="$1"
  [[ -t 2 ]] || return 1
  local answer
  read -r -p "${prompt} [y/N]: " answer < /dev/tty
  [[ "${answer,,}" == "y" ]]
}

# Prompt [p]roject/[u]ser for a JSON conflict. Reads from /dev/tty.
# Echoes the chosen JSON value. Defaults to project after 3 invalid inputs
# or when non-interactive.
ask_pu() {
  local proj_val="$1" user_val="$2"
  [[ -t 2 ]] || {
    echo "${proj_val}"
    return
  }
  local answer attempts=0
  while ((attempts < 3)); do
    read -r -p "  Keep [p]roject / [u]ser? (default: p): " answer < /dev/tty
    case "${answer,,}" in
      u)
        echo "${user_val}"
        return
        ;;
      p | "")
        echo "${proj_val}"
        return
        ;;
      *) : ;; # Continue looping on invalid input
    esac
    attempts=$((attempts + 1))
  done
  echo "${proj_val}"
}

# jq filter: array of leaf paths in the input object.
# "Leaf" = scalar or array (does not recurse into arrays).
# Example output for {"a":{"b":1},"c":[1,2]}: [["a","b"],["c"]]
export JQ_LEAF_PATHS
JQ_LEAF_PATHS=". as \$doc | [paths(type != \"object\") | select(. as \$p | all(range(length - 1); . as \$i | (\$doc | getpath(\$p[:\$i+1]) | type) != \"array\"))]"

# jq filter: TSV of [path_json, path_str, proj_val, user_val] for leaf paths present
# in both $doc (positional input) and $u[0] (--slurpfile u) with differing values.
export JQ_CONFLICTS
JQ_CONFLICTS="${JQ_LEAF_PATHS} as \$lp |
  \$lp[] | . as \$p |
  {path: \$p, proj: (\$doc | getpath(\$p)), user: (\$u[0] | getpath(\$p))} |
  select(.user != null and (.user | tojson) != (.proj | tojson)) |
  [(\$p | tojson), (\$p | join(\".\")), (.proj | tojson), (.user | tojson)] | @tsv"

# Direction 2: sync a single non-JSON file from ~/.claude/ → project (ask).
d2_non_json() {
  local proj_file="$1"
  local user_file
  user_file="$(user_path "${proj_file}")"
  [[ -f "${user_file}" ]] || return 0                                # no user-side file, skip
  diff -q "${proj_file}" "${user_file}" > /dev/null 2>&1 && return 0 # identical
  printf '\n  %s differs from ~/.claude/ version:\n' "$(basename "${proj_file}")"
  diff --color=always "${proj_file}" "${user_file}" || true
  echo ""
  if ask_yn "  Pull this change into the project?"; then
    cp "${user_file}" "${proj_file}"
    log "$(basename "${proj_file}") — pulled from ~/.claude/"
  fi
}

# Direction 2: sync tracked JSON leaf paths from ~/.claude/ → project (ask per path).
d2_json() {
  local proj_file="$1"
  local user_file
  user_file="$(user_path "${proj_file}")"
  [[ -f "${user_file}" ]] || return 0 # no user-side file, skip
  local name
  name="$(basename "${proj_file}")"
  local updated changed
  updated="$(jq '.' "${proj_file}")"
  changed=false

  local _user_only _conflicts
  _user_only=$(jq -r --slurpfile proj "${proj_file}" \
    "${JQ_LEAF_PATHS}"' as $lp |
    $lp[] | . as $p |
    select(($proj[0] | getpath($p)) == null) |
    [($p | tojson), ($p | join(".")), ($doc | getpath($p) | tojson)] | @tsv
    ' "${user_file}")

  if [[ -n "${_user_only}" ]]; then
    while IFS=$'\t' read -r path_json path_str user_val; do
      printf '\n  %s — "%s" only exists in ~/.claude/:\n' "${name}" "${path_str}"
      printf '    ~/.claude/ : %s\n' "${user_val}"
      if ask_yn "  Add this key to the project?"; then
        updated="$(printf '%s' "${updated}" \
          | jq --argjson p "${path_json}" --argjson v "${user_val}" 'setpath($p; $v)')"
        changed=true
        log "${name} — \"${path_str}\" added from ~/.claude/"
      fi
    done <<< "${_user_only}"
  fi

  _conflicts=$(jq -r --slurpfile u "${user_file}" "${JQ_CONFLICTS}" "${proj_file}")

  if [[ -n "${_conflicts}" ]]; then
    while IFS=$'\t' read -r path_json path_str proj_val user_val; do
      printf '\n  %s — "%s" differs in ~/.claude/:\n' "${name}" "${path_str}"
      printf '    ~/.claude/ : %s\n' "${user_val}"
      printf '    project    : %s\n' "${proj_val}"
      if ask_yn "  Pull this value into the project?"; then
        updated="$(printf '%s' "${updated}" \
          | jq --argjson p "${path_json}" --argjson v "${user_val}" 'setpath($p; $v)')"
        changed=true
        log "${name} — \"${path_str}\" pulled from ~/.claude/"
      fi
    done <<< "${_conflicts}"
  fi

  if [[ "${changed}" == true ]]; then printf '%s' "${updated}" | jq '.' > "${proj_file}"; fi
}

# Direction 2: walk all project files, call per-file handler.
d2() {
  echo "Checking ~/.claude/ for local changes to pull into the project..."
  find "${PROJ_DIR}" -type f -print0 | while IFS= read -r -d '' proj_file; do
    if [[ "${proj_file}" == *.json ]]; then
      d2_json "${proj_file}"
    else
      d2_non_json "${proj_file}"
    fi
  done
}

# Direction 1: copy a single non-JSON project file → ~/.claude/ (auto).
d1_non_json() {
  local proj_file="$1"
  local user_file
  user_file="$(user_path "${proj_file}")"
  if [[ -f "${user_file}" ]] && diff -q "${proj_file}" "${user_file}" > /dev/null 2>&1; then
    log "$(basename "${proj_file}") — already up to date"
    return 0
  fi
  mkdir -p "$(dirname "${user_file}")"
  cp "${proj_file}" "${user_file}"
  log "$(basename "${proj_file}") — copied to ~/.claude/"
}

# Direction 1: deep-merge a single JSON project file → ~/.claude/ (auto, conflict prompts).
d1_json() {
  local proj_file="$1"
  local user_file
  user_file="$(user_path "${proj_file}")"
  local name
  name="$(basename "${proj_file}")"

  if [[ ! -f "${user_file}" ]]; then
    mkdir -p "$(dirname "${user_file}")"
    cp "${proj_file}" "${user_file}"
    log "${name} — copied to ~/.claude/ (new file)"
    return 0
  fi

  local merged orig_normalized
  merged="$(jq '.' "${user_file}")"
  orig_normalized="${merged}"

  # Add project-only leaf paths (keys in project not present in user file).
  local _proj_only
  _proj_only=$(jq -r --slurpfile u "${user_file}" \
    "${JQ_LEAF_PATHS}"' as $lp |
    $lp[] | . as $p |
    select(($u[0] | getpath($p)) == null) |
    [($p | tojson), ($p | join(".")), ($doc | getpath($p) | tojson)] | @tsv
    ' "${proj_file}")

  if [[ -n "${_proj_only}" ]]; then
    while IFS=$'\t' read -r path_json _ val_json; do
      merged="$(printf '%s' "${merged}" \
        | jq --argjson p "${path_json}" --argjson v "${val_json}" 'setpath($p; $v)')"
    done <<< "${_proj_only}"
  fi

  # Prompt for conflicting leaf paths (present in both with different values).
  local _d1_conflicts
  _d1_conflicts=$(jq -r --slurpfile u "${user_file}" "${JQ_CONFLICTS}" "${proj_file}")

  if [[ -n "${_d1_conflicts}" ]]; then
    while IFS=$'\t' read -r path_json path_str proj_val user_val; do
      printf '\n  Conflict in %s — "%s":\n' "${name}" "${path_str}"
      printf '    project    : %s\n' "${proj_val}"
      printf '    ~/.claude/ : %s\n' "${user_val}"
      local chosen
      chosen="$(ask_pu "${proj_val}" "${user_val}")"
      merged="$(printf '%s' "${merged}" \
        | jq --argjson p "${path_json}" --argjson v "${chosen}" 'setpath($p; $v)')"
    done <<< "${_d1_conflicts}"
  fi

  local final_out
  final_out="$(printf '%s' "${merged}" | jq '.')"
  if [[ "${final_out}" != "${orig_normalized}" ]]; then
    printf '%s' "${final_out}" > "${user_file}"
    log "${name} — merged into ~/.claude/"
  else
    log "${name} — already up to date"
  fi
}

# Direction 1: walk all project files, call per-file handler.
d1() {
  echo "Syncing project files to ~/.claude/..."
  find "${PROJ_DIR}" -type f -print0 | while IFS= read -r -d '' proj_file; do
    if [[ "${proj_file}" == *.json ]]; then
      d1_json "${proj_file}"
    else
      d1_non_json "${proj_file}"
    fi
  done
}

main() {
  check_deps
  if [[ $# -gt 0 ]]; then
    local proj_file
    proj_file="$(realpath "$1")"
    [[ -f "${proj_file}" ]] || {
      echo "ERROR: File not found: $1" >&2
      exit 1
    }
    [[ "${proj_file}" == "${PROJ_DIR}"/* ]] || {
      echo "ERROR: File not under ${PROJ_DIR}" >&2
      exit 1
    }
    echo "Syncing $(basename "${proj_file}") to ~/.claude/..."
    if [[ "${proj_file}" == *.json ]]; then
      d1_json "${proj_file}"
    else
      d1_non_json "${proj_file}"
    fi
  else
    d2
    d1
  fi
  echo ""
  echo "Done."
}

main "$@"
