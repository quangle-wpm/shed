#!/usr/bin/env bash
set -euo pipefail

# Description: Install (or reinstall) Claude Code with config, hooks, skills, and plugins.
# Usage: ./install-claude-code.sh
#
# Safe to run on a fresh machine or over an existing installation.
# Steps performed:
#   1. Check prerequisites (curl, jq, GNU diff, Node.js)
#   2. Remove existing installation (if present, after confirmation)
#   3. Install Claude Code via native installer
#   4. Run sync-claude-code.sh to restore settings, hooks, and skills
#   5. Install official plugins
#   6. Install third-party skills (context7 find-docs)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SYNC_SCRIPT="${REPO_ROOT}/scripts/linux/utils/sync-claude-code.sh"
SETTINGS_JSON="${REPO_ROOT}/config/claude-code/settings.json"

log() { printf '  %s\n' "$1"; }

ask_yn() {
  local prompt="$1"
  [[ -t 2 ]] || return 1
  local answer
  read -r -p "${prompt} [y/N]: " answer < /dev/tty
  [[ "${answer,,}" == "y" ]]
}

check_deps() {
  local missing=()
  command -v curl > /dev/null 2>&1 || missing+=("curl")
  command -v jq > /dev/null 2>&1 || missing+=("jq")
  command -v node > /dev/null 2>&1 || missing+=("node (Node.js)")
  command -v npx > /dev/null 2>&1 || missing+=("npx (Node.js)")
  if ! diff --version 2> /dev/null | grep -q GNU; then
    missing+=("GNU diff (diffutils)")
  fi
  if ((${#missing[@]} > 0)); then
    echo "ERROR: Missing prerequisites:"
    for dep in "${missing[@]}"; do
      echo "  - ${dep}"
    done
    echo ""
    echo "Install them and re-run this script."
    exit 1
  fi
}

main() {
  echo "=== Claude Code Install ==="
  echo ""

  # Step 1: Check prerequisites
  echo "Step 1: Checking prerequisites..."
  check_deps
  log "All prerequisites found."

  # Step 2: Remove existing installation (if any)
  echo ""
  echo "Step 2: Checking for existing installation..."
  if command -v claude > /dev/null 2>&1; then
    log "Found Claude Code $(claude --version 2> /dev/null || echo '(unknown version)')."
    if ask_yn "  Remove existing installation?"; then
      rm -f "${HOME}/.local/bin/claude"
      rm -rf "${HOME}/.local/share/claude"
      rm -f "${HOME}/.claude.json"
      log "Removed binary, versions, and auth state."
    fi
  else
    log "No existing installation found."
  fi
  if [[ -d "${HOME}/.claude" ]]; then
    if ask_yn "  Remove ${HOME}/.claude/ (config/state)?"; then
      rm -rf "${HOME}/.claude"
      log "Removed config directory."
    else
      log "Keeping existing config (will be merged)."
    fi
  fi

  # Step 3: Install Claude Code
  echo ""
  echo "Step 3: Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | sh
  log "Installed: $(claude --version 2> /dev/null || echo 'unknown version')"

  # Step 4: Sync config
  echo ""
  echo "Step 4: Syncing settings, hooks, and skills..."
  if [[ -x "${SYNC_SCRIPT}" ]]; then
    bash "${SYNC_SCRIPT}"
  else
    echo "  WARNING: sync script not found at ${SYNC_SCRIPT}"
    echo "  Run it manually after fixing."
  fi

  # Step 5: Install plugins (read from settings.json enabledPlugins keys)
  echo ""
  echo "Step 5: Installing plugins..."
  local plugins
  plugins="$(jq -r '.enabledPlugins // {} | keys[]' "${SETTINGS_JSON}")"
  if [[ -n "${plugins}" ]]; then
    while IFS= read -r plugin; do
      log "Installing ${plugin}..."
      claude plugin install "${plugin}" || log "WARNING: failed to install ${plugin}"
    done <<< "${plugins}"
  else
    log "No plugins found in settings.json."
  fi

  # Step 6: Install third-party skills
  echo ""
  echo "Step 6: Installing third-party skills..."
  log "Installing find-docs from context7..."
  npx ctx7@latest skills install /upstash/context7 find-docs --claude \
    || log "WARNING: failed to install find-docs skill"

  echo ""
  echo "=== Done ==="
  echo ""
  echo "Next steps:"
  echo "  1. Run 'claude' to trigger authentication"
  echo "  2. Verify with 'claude --version'"
}

main "$@"
