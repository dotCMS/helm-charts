{{- define "dotcms.backupRestoreScript" -}}
#!/bin/bash
set -e

echo "Operation: ${OPERATION}"
BACKUP_DIR=/mnt/backup
RESTORE_TMP_DIR=${BACKUP_DIR}/restore-temp
DOTCMS_DATA_DIR=/data/shared

if [[ "${OPERATION}" == "backup" ]]; then
  echo "Starting backup process..."
  DB_DUMP=${BACKUP_DIR}/db-dump.sql
  DOTCMS_DATA=${BACKUP_DIR}/dotcms-data.tar.gz
  FINAL_BACKUP=${BACKUP_DIR}/{{ .Values.fileName | default "backup" }}-$(date +%Y%m%d%H%M%S).tar.gz

  echo "Dumping database..."
  PGPASSWORD=${DB_PASSWORD} pg_dump -h ${DB_HOST} -U ${DB_USERNAME} -d ${DB_NAME} -Fp -f ${DB_DUMP}

  echo "Archiving DotCMS data..."
  tar czf ${DOTCMS_DATA} -C ${DOTCMS_DATA_DIR} .

  echo "Creating final backup..."
  tar czf ${FINAL_BACKUP} -C ${BACKUP_DIR} db-dump.sql dotcms-data.tar.gz

  echo "Backup completed successfully: ${FINAL_BACKUP}"

elif [[ "${OPERATION}" == "restore" ]]; then
  echo "Starting restore process..."
  mkdir -p ${RESTORE_TMP_DIR}

  echo "Extracting backup..."
  tar xzf ${BACKUP_DIR}/{{ .Values.fileName | default "backup" }}.tar.gz -C ${RESTORE_TMP_DIR}

  echo "Restoring database..."
  PGPASSWORD=${DB_PASSWORD} psql -h ${DB_HOST} -U ${DB_USERNAME} -d ${DB_NAME} -f ${RESTORE_TMP_DIR}/db-dump.sql

  echo "Restoring DotCMS data..."
  tar xzf ${RESTORE_TMP_DIR}/dotcms-data.tar.gz -C ${DOTCMS_DATA_DIR}

  echo "Restore completed successfully."

else
  echo "No valid operation specified. Exiting."
fi
{{- end -}}