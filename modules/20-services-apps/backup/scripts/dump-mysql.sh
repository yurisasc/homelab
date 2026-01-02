#!/usr/bin/env bash
set -euo pipefail

# Expects environment variables:
#   BACKUP_DB_HOST
#   BACKUP_DB_PORT
#   BACKUP_DB_NAME
#   BACKUP_DB_USER
#   BACKUP_DB_PASSWORD

if [[ -z "${BACKUP_DB_HOST:-}" || -z "${BACKUP_DB_NAME:-}" || -z "${BACKUP_DB_USER:-}" || -z "${BACKUP_DB_PASSWORD:-}" ]]; then
  echo "Missing required database connection environment variables for MySQL dump" >&2
  exit 1
fi

mysqldump \
  -h "${BACKUP_DB_HOST}" \
  -P "${BACKUP_DB_PORT:-3306}" \
  -u "${BACKUP_DB_USER}" \
  -p"${BACKUP_DB_PASSWORD}" \
  --single-transaction \
  "${BACKUP_DB_NAME}"
