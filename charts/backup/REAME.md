# Helm Chart Documentation: dotCMS Backup & Restore

## Overview

This Helm chart facilitates the **backup** and **restore** of persistent data from a dotCMS cluster running on Kubernetes. It creates **Jobs** to handle both operations, ensuring data safety and consistency during the process.

---

## Structure

The Helm chart includes the following resources:

- **Backup Job**: Creates a tarball (`.tar.gz`) from specified Persistent Volume Claims (PVCs).
- **Restore Job**: Restores the backup tarball content into the PVCs.
- **Dynamic Configuration**: Configuration is managed via `values.yaml`, including host paths, file names, and operation modes.

---

## Installation

### Prerequisites

- Kubernetes cluster (local or remote).
- `kubectl` and `helm` installed.
- dotCMS cluster running in Kubernetes (with persistent volumes).

---

### Install the Chart

To install the chart and execute a **backup** operation:

```bash
helm upgrade --install dotcms-backup ./backup \
  --set operation=backup \
  --set hostPath=/path/to/backup \
  --set fileName=backup-complete.tar.gz
```

To perform a restore operation:

```bash
helm upgrade --install dotcms-restore ./backup \
  --set operation=restore \
  --set hostPath=/path/to/backup \
  --set fileName=backup-complete.tar.gz
```

To clean up the resources:

```bash
helm uninstall dotcms-backup --namespace dotcms-dev
helm uninstall dotcms-restore --namespace dotcms-dev
```

## Values
Below is the list of configurable parameters in values.yaml.

| **Key**                             | **Type**   | **Default**                   | **Description**                                                      |
|-------------------------------------|------------|-------------------------------|----------------------------------------------------------------------|
| `namespace`                         | `string`   | `dotcms-dev`                  | Kubernetes namespace where the Jobs are deployed.                   |
| `operation`                         | `string`   | `backup`                      | Operation to perform: `backup` or `restore`.                        |
| `retries`                           | `int`      | `3`                           | Number of retry attempts for the Job.                               |
| `ttlSecondsAfterFinished`           | `int`      | `900`                         | Time (in seconds) to retain the Job after completion.               |
| `hostPath`                          | `string`   | `/private/tmp/`               | Host path where the backup tarball will be stored or restore.       |
| `fileName`                          | `string`   | `backup-complete.tar.gz`      | Name of the backup tarball file.                                    |


## Usage Examples

**Backup Example**

To back up the data to /tmp/backup and name the file my-backup.tar.gz:

```bash
helm upgrade --install dotcms-backup ./backup \
  --set operation=backup \
  --set hostPath=/tmp/backup \
  --set fileName=my-backup.tar.gz
```

**Restore Example**

To restore the backup from /tmp/backup using the file my-backup.tar.gz:

```bash
helm upgrade --install dotcms-restore ./backup \
  --set operation=restore \
  --set hostPath=/tmp/backup \
  --set fileName=my-backup.tar.gz
```

### Notes

Ensure that the `hostPath` specified in the backup and restore operations is included in the Docker Desktop shared directories (if running locally).