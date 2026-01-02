#!/usr/bin/env bash
set -euo pipefail

# Helper script for manual restore operations.
# Usage examples:
#   List snapshots:      ./restore.sh list
#   Restore entire snap: ./restore.sh restore <snapshot-id> <target-path>
#   Restore file/dir:    ./restore.sh restore <snapshot-id> <target-path> <include-pattern>

cmd="${1:-}" || true

if [[ -z "${RESTIC_REPOSITORY:-}" || -z "${RESTIC_PASSWORD:-}" ]]; then
  echo "RESTIC_REPOSITORY or RESTIC_PASSWORD not set, cannot perform restore" >&2
  exit 1
fi

case "$cmd" in
  list)
    restic snapshots
    ;;
  restore)
    snap="${2:-}"
    target="${3:-}"
    include="${4:-}"

    if [[ -z "$snap" || -z "$target" ]]; then
      echo "Usage: $0 restore <snapshot-id> <target-path> [include-pattern]" >&2
      exit 1
    fi

    mkdir -p "$target"

    if [[ -n "$include" ]]; then
      restic restore "$snap" --target "$target" --include "$include"
    else
      restic restore "$snap" --target "$target"
    fi
    ;;
  *)
    echo "Usage: $0 [list|restore ...]" >&2
    exit 1
    ;;
 esac
