#!/usr/bin/env bash
set -euo pipefail

# Description: what this script does
# Usage: ./script-name.sh [args]

main() {
  echo "Hello from $(basename "$0")"
}

main "$@"
