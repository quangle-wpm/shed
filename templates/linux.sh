#!/usr/bin/env bash
set -euo pipefail

# Description: what this script does
# Usage: ./script-name.sh [args]

cleanup() {
  : # TODO: remove temp files, release locks, etc.
}
trap cleanup EXIT

main() {
  echo "Hello from $(basename "$0")"
}

main "$@"
