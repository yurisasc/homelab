#!/usr/bin/env bash
set -euo pipefail

# Simple wrapper around `restic check` for integrity verification

if [[ -z "${RESTIC_REPOSITORY:-}" || -z "${RESTIC_PASSWORD:-}" ]]; then
  echo "RESTIC_REPOSITORY or RESTIC_PASSWORD not set, cannot run integrity check" >&2
  exit 1
fi

restic check
