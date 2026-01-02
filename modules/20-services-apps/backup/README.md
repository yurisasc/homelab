# Homelab Backup Module

This module provides a robust, automated backup system for the homelab, leveraging **Restic** for file-level backups to Backblaze B2 and automated **Database Dumps** for PostgreSQL and MySQL/MariaDB.

## Features

- **Automated Database Dumps**: Automatically dumps PostgreSQL and MySQL databases from their respective containers.
- **Restic Backups**: Incremental, encrypted, and deduplicated backups to Backblaze B2.
- **Backup Sets**: Flexible configuration for multiple backup sets with individual frequencies, retention policies, and exclude patterns.
- **Dry-Run Mode**: Test the entire backup pipeline without writing any data or modifying the Restic repository.
- **Progress Monitoring**: Real-time throughput reporting for database dumps (via `pv`) and detailed upload progress for Restic.
- **Automated Retention**: Per-set retention policies (daily, weekly, monthly snapshots).
- **Lock Management**: Automatic retry and unlocking mechanism for Restic repository locks.

## Architecture

The system runs as a single Ubuntu-based Docker container (`homelab-backup`) that:
1. Installs the latest Restic binary, database clients, and monitoring tools.
2. Mounts service data volumes as read-only.
3. Connects to a dedicated `backup-network` to reach database containers.
4. Executes a scheduler script that runs daily and decides which backup sets to process.

## How Database Backups Work

The system uses a decentralized configuration where each service defines its own backup requirements, and the backup module aggregates them.

### 1. Service-Level Definition
Each service module (e.g., Immich, Dify) is responsible for:
- Exposing its database container to the `backup-network`.
- Outputting a `db_backup_config` object.

Example from `immich/main.tf`:
```hcl
output "db_backup_config" {
  value = {
    name         = "immich"
    type         = "postgres"
    host         = "immich-postgres"
    port         = 5432
    database     = "immich"
    username     = "postgres"
    password_env = "DB_PASSWORD" # Key in the service's .env file
    env_file     = "${path.module}/.env"
  }
}
```

### 2. Aggregation (Root Module)
The root `services/main.tf` collects these outputs and passes them to the backup module:
```hcl
module "backup" {
  source     = "./modules/20-services-apps/backup"
  db_configs = [
    module.immich.db_backup_config,
    module.dify.db_backup_config,
    # ... other services
  ]
}
```

### 3. Password Mapping & Security
The backup module performs "Environment Variable Mapping" to securely pass passwords without hardcoding them:
1. **Source**: It reads the password from the service's private `.env` file during the Terraform/OpenTofu plan stage.
2. **Internal Name**: It assigns a unique environment variable name for the backup container, e.g., `BACKUP_DB_PASSWORD_immich`.
3. **Registry**: It creates a JSON registry (`BACKUP_DB_REGISTRY`) that tells the backup script which host/user to use and which environment variable holds that database's password.

### 4. Execution Pipeline
When `backup.sh` runs:
1. It iterates through the `BACKUP_DB_REGISTRY` JSON.
2. It extracts the connection details and the name of the environment variable holding the password.
3. It calls `dump-postgres.sh` or `dump-mysql.sh`, which uses these variables to perform the dump.
4. The dump is either saved to `BACKUP_DUMP_DIR` (normal mode) or piped to `/dev/null` (dry-run mode).

## Configuration

### 1. Environment Variables (`.env`)
Create a `.env` file in this directory based on `.env.example`:

| Variable | Description | Default |
|----------|-------------|---------|
| `RESTIC_REPOSITORY` | B2 repository path (e.g., `b2:bucket-name:repo`) | - |
| `RESTIC_PASSWORD` | Encryption password for the repository | - |
| `B2_ACCOUNT_ID` | Backblaze B2 Application Key ID | - |
| `B2_ACCOUNT_KEY` | Backblaze B2 Application Key | - |
| `BACKUP_DUMP_DIR` | Absolute path *inside the container* for local DB dumps | `/data/appdata/_backup/db_dumps` |
| `BACKUP_SCHEDULE_HOUR` | Hour of the day to run the backup (0-23) | `3` |
| `BACKUP_DRY_RUN` | Set to `true` to test without saving data | `false` |

### 2. Backup Sets (`backup-sets.json`)
Define your backup groups in `backup-sets.json`. This file is ignored by git.

```json
[
  {
    "name": "appdata",
    "paths": ["/data/appdata"],
    "frequency": "daily",
    "keep_daily": 7,
    "keep_weekly": 4,
    "keep_monthly": 6,
    "excludes": [
      "**/cache/**",
      "**/tmp/**",
      "**/*.log"
    ]
  }
]
```

## Usage

### Deployment
Apply the module via Terraform/OpenTofu:
```bash
tofu apply -target=module.services.module.backup
```

### Manual Trigger
You can trigger a backup manually at any time:
```bash
docker exec -it -e BACKUP_SCHEDULE_HOUR= -e BACKUP_DRY_RUN=false homelab-backup /scripts/backup.sh
```

### Dry-Run Testing
To test your configuration and see exactly what would be backed up:
```bash
docker exec -it -e BACKUP_SCHEDULE_HOUR= -e BACKUP_DRY_RUN=true homelab-backup /scripts/backup.sh
```

## Monitoring & Logs

- **Database Dumps**: Logs show real-time throughput in MiB/s using `pv`.
- **Restic**: Detailed file-by-file changes and upload progress are shown via `-vv` flags.
- **Healthcheck**: The container is considered healthy if database dumps have been successfully created within the last 48 hours (if DBs are configured).
