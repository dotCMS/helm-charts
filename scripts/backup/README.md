# Backup and Restore 

## Overview

This script automates the **backup**, **restore**, and **cleanup** of persistent volumes in a dotCMS Kubernetes cluster. It interacts with Helm charts and Kubernetes resources to ensure smooth backup and restore processes, including scaling down services to ensure data consistency.

---

## Features

- **Backup**: Creates a `.tar.gz` archive of persistent data.
- **Restore**: Restores data from a backup archive.
- **Cleanup**: Removes Helm releases for backup and restore Jobs.
- **Service Management**: Automatically scales down and up `dotcms`, `db`, and `opensearch` services during restore operations.

---

## Prerequisites

Before using the script, ensure the following tools are installed:

1. **kubectl**: For interacting with the Kubernetes cluster.
2. **helm**: To manage Helm charts.
3. A **Kubernetes cluster** running dotCMS services.
4. A valid **Helm chart** for backup and restore operations.

---

## Usage

```bash
./backup_restore.sh --operation <backup|restore|cleanup> [--hostpath <path>] [--filename <name>] [--namespace <namespace>] [--help]
```

## Parameters

| Parameter     | Description                                                                 | Default Value       |
|---------------|-----------------------------------------------------------------------------|---------------------|
| `--operation` | Operation to perform (`backup`, `restore`, `cleanup`). **Required**.        | -                   |
| `--hostpath`  | Path for backup/restore files. Required for `restore`.                      | `/private/tmp`      |
| `--filename`  | Backup file name (without extension). Required for `restore`.               | `backup-<timestamp>`|
| `--namespace` | Kubernetes namespace where the services are deployed.                       | `dotcms-dev`        |
| `--help`      | Displays usage information and exits.                                       | -                   |


## Examples

### Backup

Performs a backup of dotCMS persistent data into a .tar.gz file.

```bash
./backup_restore.sh --operation backup --hostpath /path/to/backup --filename my-backup
```
> **Note**: If `filename` is not provided, it defaults to `backup-<timestamp>`. If `hostpath` is not provided, it defaults to `/private/tmp`.

Steps:

1. Creates a Helm release dotcms-backup.
2. Backs up persistent data to the specified hostpath.
3. The resulting backup file is named as specified (e.g., my-backup.tar.gz).


### Restore

Restores data from a specified backup file.

```bash
./backup_restore.sh --operation restore --hostpath /path/to/backup --filename my-backup
```

> **Note**: The provided file (my-backup.tar.gz) must exist in the specified `hostpath`.

Steps:

1. Validates that the backup file exists.
2. Scales down dotCMS services (dotcms, db, and opensearch).
3. Waits for a grace period to ensure the services are fully stopped.
4. Creates a Helm release dotcms-restore to restore data.
5. Scales up dotCMS services in the correct order:
    - db
    - opensearch
    - dotcms


### Cleanup

Removes Helm releases related to the backup and restore operations.


```bash
./backup_restore.sh --operation cleanup
```

Steps:

1. Uninstalls the dotcms-backup Helm release.
2. Uninstalls the dotcms-restore Helm release.

## Error handling

| **Error**                                 | **Cause**                                  | **Solution**                                      |
|-------------------------------------------|-------------------------------------------|--------------------------------------------------|
| `kubectl is not installed.`               | `kubectl` command is not found.            | Install `kubectl` and add it to the system PATH. |
| `helm is not installed.`                  | `helm` command is not found.               | Install `helm` and add it to the system PATH.    |
| `Backup file not found.`                  | Specified file does not exist in hostPath. | Verify the file path and name.                  |
| `Kubernetes cluster is not running.`      | No active Kubernetes cluster detected.     | Start the cluster and verify with `kubectl`.    |
| `Invalid operation '<operation>'`         | Incorrect operation specified.             | Use `backup`, `restore`, or `cleanup`.          |


## Notes

- Ensure the `hostpath` provided exists in the `Docker Desktop` shared directories (for local clusters).
- Backup and restore operations require Helm charts for backup and restore.
- During the restore process:
    - dotCMS services are scaled down to prevent data inconsistencies.
    - Services are restarted in the correct order to ensure dependency resolution.