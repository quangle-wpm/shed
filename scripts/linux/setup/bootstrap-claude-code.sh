#!/usr/bin/env bash
set -euo pipefail

# Description: Bootstrap installer — clone repo and run install-claude-code.sh.
# Usage: curl -fsSL https://raw.githubusercontent.com/quangle-wpm/shed/main/scripts/linux/setup/bootstrap-claude-code.sh | bash

REPO_URL="https://github.com/quangle-wpm/shed.git"
INSTALL_SCRIPT="scripts/linux/setup/install-claude-code.sh"

main() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' EXIT

  echo "Cloning shed repo..."
  git clone --depth 1 "${REPO_URL}" "${tmpdir}" --quiet
  echo ""

  bash "${tmpdir}/${INSTALL_SCRIPT}"
}

main "$@"
