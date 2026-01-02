#!/usr/bin/env bash
set -euo pipefail

log_info() {
  echo "[INFO] $(date --iso-8601=seconds) - $*"
}

log_error() {
  echo "[ERROR] $(date --iso-8601=seconds) - $*" >&2
}

run_db_dumps() {
  if [[ -z "${BACKUP_DB_REGISTRY:-}" ]]; then
    log_info "No BACKUP_DB_REGISTRY configured, skipping DB dumps"
    return 0
  fi

  local dump_dir="${BACKUP_DUMP_DIR:-/dumps}"

  echo "${BACKUP_DB_REGISTRY}" | jq -c '.[]' | while read -r entry; do
    local name type host port database username password_env password ts target_dir

    name=$(echo "$entry" | jq -r '.name')
    type=$(echo "$entry" | jq -r '.type')
    host=$(echo "$entry" | jq -r '.host')
    port=$(echo "$entry" | jq -r '.port // empty')
    database=$(echo "$entry" | jq -r '.database')
    username=$(echo "$entry" | jq -r '.username')
    password_env=$(echo "$entry" | jq -r '.password_env')

    password="${!password_env:-}"
    if [[ -z "$password" ]]; then
      log_error "Password env var '$password_env' for DB '$name' is empty, skipping"
      continue
    fi

    ts=$(date +%Y-%m-%d_%H-%M-%S)
    target_dir="${dump_dir}/${type}/${name}"
    mkdir -p "$target_dir"

    log_info "Dumping $type database '$name' from host '$host'"

    if [[ "$type" == "postgres" ]]; then
      local dump_cmd="BACKUP_DB_PORT=${port:-5432} BACKUP_DB_HOST=$host BACKUP_DB_NAME=$database BACKUP_DB_USER=$username BACKUP_DB_PASSWORD=$password /scripts/dump-postgres.sh"
      if [[ "${BACKUP_DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Dumping $name to /dev/null"
        eval "$dump_cmd" | pv -f > /dev/null || log_error "Postgres dry-run dump failed for $name"
      else
        eval "$dump_cmd" | pv -f | gzip >"${target_dir}/${ts}.sql.gz" || log_error "Postgres dump failed for $name"
      fi
    elif [[ "$type" == "mysql" ]]; then
      local dump_cmd="BACKUP_DB_PORT=${port:-3306} BACKUP_DB_HOST=$host BACKUP_DB_NAME=$database BACKUP_DB_USER=$username BACKUP_DB_PASSWORD=$password /scripts/dump-mysql.sh"
      if [[ "${BACKUP_DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Dumping $name to /dev/null"
        eval "$dump_cmd" | pv -f > /dev/null || log_error "MySQL dry-run dump failed for $name"
      else
        eval "$dump_cmd" | pv -f | gzip >"${target_dir}/${ts}.sql.gz" || log_error "MySQL dump failed for $name"
      fi
    else
      log_error "Unknown DB type '$type' for '$name', skipping"
      continue
    fi
  done

  # Retention for local dumps
  local days="${BACKUP_DUMP_RETENTION_DAYS:-7}"
  if [[ "$days" =~ ^[0-9]+$ ]]; then
    log_info "Pruning local dumps older than $days days"
    find "${dump_dir}" -type f -name '*.sql.gz' -mtime "+${days}" -print -delete || true
  fi
}

should_run_set() {
  local frequency="$1"
  local dow dom
  dow=$(date +%u)  # 1=Mon..7=Sun
  dom=$(date +%d)  # Day of month (01-31)

  case "$frequency" in
    daily)   return 0 ;;
    weekly)  [[ "$dow" -eq 7 ]] && return 0 || return 1 ;;  # Sundays
    monthly) [[ "$dom" == "01" ]] && return 0 || return 1 ;;  # 1st of month
    *)       return 0 ;;  # Default to daily
  esac
}

run_restic_backup() {
  # Graceful skip when B2 is not yet configured
  if [[ -z "${B2_ACCOUNT_ID:-}" || -z "${B2_ACCOUNT_KEY:-}" ]]; then
    log_info "B2 credentials not set, skipping Restic backup"
    return 0
  fi

  if [[ -z "${RESTIC_REPOSITORY:-}" || -z "${RESTIC_PASSWORD:-}" ]]; then
    log_error "RESTIC_REPOSITORY or RESTIC_PASSWORD not set, cannot run Restic backup"
    return 1
  fi

  # Initialize repo if needed
  if ! restic snapshots >/dev/null 2>&1; then
    log_info "Initializing Restic repository at ${RESTIC_REPOSITORY}"
    restic init
  fi

  # Check if BACKUP_SETS_JSON is configured
  if [[ -n "${BACKUP_SETS_JSON:-}" ]]; then
    run_backup_sets
  else
    log_info "No BACKUP_SETS_JSON configured, skipping Restic backup"
  fi
}

run_backup_sets() {
  local sets_run=0

  log_info "Processing backup sets"

  echo "${BACKUP_SETS_JSON}" | jq -c '.[]' | while read -r set_entry; do
    local name frequency keep_daily keep_weekly keep_monthly
    name=$(echo "$set_entry" | jq -r '.name')
    frequency=$(echo "$set_entry" | jq -r '.frequency // "daily"')
    keep_daily=$(echo "$set_entry" | jq -r '.keep_daily // 7')
    keep_weekly=$(echo "$set_entry" | jq -r '.keep_weekly // 4')
    keep_monthly=$(echo "$set_entry" | jq -r '.keep_monthly // 6')

    # Read paths into array
    local paths=()
    while IFS= read -r p; do
      [[ -n "$p" ]] && paths+=("$p")
    done < <(echo "$set_entry" | jq -r '.paths[]')

    # Read per-set excludes into array
    local excludes=()
    while IFS= read -r e; do
      [[ -n "$e" ]] && excludes+=("--exclude" "$e")
    done < <(echo "$set_entry" | jq -r '.excludes // [] | .[]')

    # Check if this set should run today based on frequency
    if ! should_run_set "$frequency"; then
      log_info "Skipping set '$name' (frequency=$frequency, not scheduled today)"
      continue
    fi

    log_info "Starting Restic backup for set '$name' (frequency=$frequency)"

    # Build backup command with paths + per-set excludes + tag
    local backup_args=("${paths[@]}")
    [[ ${#excludes[@]} -gt 0 ]] && backup_args+=("${excludes[@]}")
    backup_args+=("--tag" "backup-set:${name}")

    if [[ "${BACKUP_DRY_RUN:-false}" == "true" ]]; then
      log_info "[DRY-RUN] Would run: restic backup ${backup_args[*]}"
      backup_args+=("--dry-run")
    fi

    if restic backup "${backup_args[@]}"; then
      log_info "Backup completed for set '$name'"
    else
      log_error "Backup failed for set '$name'"
      # Try to unlock if it failed due to a lock issue
      restic unlock || true
      continue
    fi

    # Apply per-set retention policy
    log_info "Applying retention for set '$name' (daily=$keep_daily, weekly=$keep_weekly, monthly=$keep_monthly)"
    
    local forget_args=(
      "--tag" "backup-set:${name}"
      "--keep-daily" "$keep_daily"
      "--keep-weekly" "$keep_weekly"
      "--keep-monthly" "$keep_monthly"
      "--prune"
    )

    if [[ "${BACKUP_DRY_RUN:-false}" == "true" ]]; then
      log_info "[DRY-RUN] Would run: restic forget ${forget_args[*]}"
      forget_args+=("--dry-run")
    fi

    # Retry forget/prune a few times if locked, as B2 can be slow to release locks
    local retry_count=0
    local max_retries=3
    while (( retry_count < max_retries )); do
      if restic forget "${forget_args[@]}"; then
        break
      else
        retry_count=$((retry_count + 1))
        if (( retry_count < max_retries )); then
          log_info "Retention failed (likely locked), retrying in 10s... ($retry_count/$max_retries)"
          sleep 10
          restic unlock || true
        else
          log_error "Retention failed for set '$name' after $max_retries attempts"
        fi
      fi
    done

    ((sets_run++)) || true
  done

  log_info "Backup sets processing complete"
}


run_integrity_check() {
  if [[ "${BACKUP_VERIFY:-false}" != "true" ]]; then
    return 0
  fi

  log_info "Running Restic integrity check"
  /scripts/check-integrity.sh || log_error "Restic integrity check failed"
}

run_backup_once() {
  local start_ts end_ts
  start_ts=$(date +%s)

  log_info "Starting backup run"
  run_db_dumps
  run_restic_backup
  run_integrity_check

  end_ts=$(date +%s)
  local duration=$((end_ts - start_ts))

  # Summary (DB count and .env files discovered)
  local db_count env_file_count
  db_count=$(echo "${BACKUP_DB_REGISTRY:-[]}" | jq 'length' 2>/dev/null || echo 0)
  if [[ -n "${BACKUP_HOMELAB_PATH:-}" && -d "${BACKUP_HOMELAB_PATH}" ]]; then
    env_file_count=$(find "${BACKUP_HOMELAB_PATH}" -name ".env" -type f | wc -l || echo 0)
  else
    env_file_count=0
  fi

  log_info "Backup run completed in ${duration}s (databases=${db_count}, env_files=${env_file_count})"
}

sleep_until_schedule() {
  local hour="${BACKUP_SCHEDULE_HOUR:-}"
  if [[ -z "$hour" ]]; then
    # No schedule configured - run once and exit
    run_backup_once
    return 0
  fi

  while true; do
    local now_ts target_ts
    local today

    today=$(date +%Y-%m-%d)
    now_ts=$(date +%s)
    target_ts=$(date -d "${today} ${hour}:00:00" +%s)

    if (( target_ts <= now_ts )); then
      target_ts=$(date -d "tomorrow ${hour}:00:00" +%s)
    fi

    local sleep_secs=$((target_ts - now_ts))
    log_info "Sleeping ${sleep_secs}s until next scheduled backup at ${hour}:00"
    sleep "$sleep_secs" || true

    run_backup_once
  done
}

sleep_until_schedule
