#!/usr/bin/env bash
set -euo pipefail

# Expects environment variables:
#   BACKUP_DB_HOST
#   BACKUP_DB_PORT
#   BACKUP_DB_NAME
#   BACKUP_DB_USER
#   BACKUP_DB_PASSWORD

if [[ -z "${BACKUP_DB_HOST:-}" || -z "${BACKUP_DB_NAME:-}" || -z "${BACKUP_DB_USER:-}" || -z "${BACKUP_DB_PASSWORD:-}" ]]; then
  echo "Missing required database connection environment variables for Postgres dump" >&2
  exit 1
fi

export PGPASSWORD="${BACKUP_DB_PASSWORD}"

pg_dump \
  -h "${BACKUP_DB_HOST}" \
  -p "${BACKUP_DB_PORT:-5432}" \
  -U "${BACKUP_DB_USER}" \
  --format=plain \
  --no-owner \
  --no-privileges \
  "${BACKUP_DB_NAME}"
