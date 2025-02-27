{{/*
###########################################################
# Common Name Components
###########################################################
*/}}

{{- define "dotcms.name.customer" -}}
{{- .Values.customerName -}}
{{- end -}}

{{- define "dotcms.image" -}}
{{- $repository := .Values.repository -}}
{{- $tag := .Values.tag -}}
{{- if and (not $repository) .Values.image -}}
{{- $repository = splitList ":" .Values.image | first -}}
{{- end -}}
{{- if and (not $tag) .Values.image -}}
{{- $tag = splitList ":" .Values.image | rest | first | default "latest" -}}
{{- end -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}

{{- define "dotcms.env.fullName" -}}
{{- printf "%s-%s-%s" .Values.app .Values.customerName .Values.environment -}}
{{- end -}}

{{- define "dotcms.env.serviceName" -}}
{{- printf "%s-%s-svc" .Values.customerName .Values.environment -}}
{{- end -}}

{{- define "dotcms.env.serviceName.pp" -}}
{{- printf "%s-%s-pp" .Values.customerName .Values.environment -}}
{{- end -}}

{{- define "dotcms.opensearch.fullName" -}}
{{- "opensearch" -}}
{{- end -}}

{{/*
###########################################################
# OpenSearch Related Helpers
###########################################################
*/}}

{{- define "dotcms.opensearch.cluster" -}}
{{- printf "%s-%s" .Values.customerName .Values.environment -}}
{{- end -}}

{{- define "dotcms.opensearch.endpoints" -}}
{{- if $.Values.opensearch.local.enabled -}}
{{- $host  := include "dotcms.opensearch.fullName" .  -}}
{{- $protocol  := $.Values.opensearch.protocol  -}}
{{- $port  := $.Values.opensearch.port  -}}
{{- printf "%s://%s:%d" $protocol $host (int $port) -}}
{{- else -}}
{{- tpl ( .Values.opensearch.endpointUrl ) . -}}
{{- end -}}
{{- end -}}

{{/*
###########################################################
# Secret Naming Helpers
###########################################################
*/}}

{{- define "dotcms.secret.env.name" -}}
{{- printf "%s-%s-awssecret-%s-%s" $.Values.hostType .Values.customerName .Values.environment .secretName -}}
{{- end -}}

{{- define "dotcms.secret.shared.name" -}}
{{- printf "%s-%s-awssecret-%s" .Values.hostType .Values.customerName .secretName -}}
{{- end -}}

{{- define "dotcms.secret.provider.className" -}}
{{- printf "%s-%s-awssecret" .Values.hostType .Values.customerName -}}
{{- end -}}

{{/*
###########################################################
# Volume and Storage Naming Helpers
###########################################################
*/}}

{{- define "dotcms.volume.shared.pvc" -}}
{{- printf "%s-%s-efs-pvc" .Values.customerName .Values.environment -}}
{{- end -}}

{{- define "dotcms.volume.shared.pv" -}}
{{- printf "%s-%s-efs-pv" .Values.customerName .Values.environment -}}
{{- end -}}

{{- define "dotcms.storageClassName" -}}
{{- if .Values.storageClassName -}}
{{- .Values.storageClassName -}}
{{- else -}}
{{- $defaultStorageClasses := dict "aws" "efs-sc" "azure" "azurefile" "gcp" "standard" "default" "hostpath" -}}
{{- $provider := .Values.cloudProvider | default "default" -}}
{{- get $defaultStorageClasses $provider | default "hostpath" -}}
{{- end -}}
{{- end -}}

{{- define "dotcms.volume.shared.local" -}}
{{- $type := .type -}}
{{- printf "%s-%s-local-pvc" .Values.customerName $type -}}
{{- end -}}

{{- define "dotcms.volume.env.local" -}}
{{- $type := .type -}}
{{- printf "%s-%s-%s-local-pvc" .Values.customerName .Values.environment $type -}}
{{- end -}}

{{- define "dotcms.pvc.env.name" -}}
{{- printf "%s-%s-efs-pvc" .Values.customerName .Values.environment -}}
{{- end -}}

{{/*
###########################################################
# Service Account Helpers
###########################################################
*/}}

{{- define "dotcms.serviceaccount.app" -}}
{{- .Values.serviceAccountName | default (printf "%s-app-sa" .Values.customerName) -}}
{{- end -}}

{{- define "dotcms.serviceaccount.admin" -}}
{{- .Values.serviceAccountName | default (printf "%s-admin-sa" .Values.customerName) -}}
{{- end -}}

{{/*
###########################################################
# Ingress Helpers
###########################################################
*/}}

{{- define "dotcms.ingress.externalHost" -}}
{{- if .Values.customExternalHost -}}
{{- .Values.customExternalHost -}}
{{- else if $.Values.mapToTopLevelDomain -}}
{{- .Values.ingress.hostSuffix -}}
{{- else -}}
{{- printf "%s-%s.%s" .Values.customerName .Values.environment .Values.ingress.hostSuffix -}}
{{- end -}}
{{- end -}}

{{/*
###########################################################
# Database Naming Helpers
###########################################################
*/}}

{{- define "dotcms.db.name" -}}
{{- printf "%s_%s_db" .Values.customerName .Values.environment | lower | replace "-" "_" -}}
{{- end -}}

{{/*
###########################################################
# Job Naming Helpers
###########################################################
*/}}
{{- define "dotcms.preUpgradeJobName" -}}
{{- printf "%s-%s-pre-upgrade" .Values.customerName .Values.environment -}}
{{- end }}

{{- define "dotcms.postUpgradeJobName" -}}
{{- printf "%s-%s-post-upgrade" .Values.customerName .Values.environment -}}
{{- end }}

{{- define "dotcms.dbUpgradeJobName" -}}
{{- printf "%s-%s-db-upgrade" .Values.customerName .Values.environment -}}
{{- end }}

{{- define "dotcms.backupRestoreJobName" -}}
{{- printf "%s-%s-backup-restore" .Values.customerName .Values.environment -}}
{{- end }}

{{/*
###########################################################
# dotcms.container.spec - Container specification helper
#
# Parameters:
# - IsUpgradeJob (bool): true for db-upgrade Job, false for StatefulSet.
# - EnableProbes (bool): Enables (true) or disables (false) probes.
# - ShutdownOnStartupValue (bool): Sets DOT_SHUTDOWN_ON_STARTUP env var.
#
# Usage in StatefulSet:
# {{ include "dotcms.container.spec" (merge (dict "IsUpgradeJob" false "EnableProbes" true "ShutdownOnStartupValue" false) .) | nindent 10 }}
#
# Usage in db-upgrade Job:
# {{ include "dotcms.container.spec" (merge (dict "IsUpgradeJob" true "EnableProbes" false "ShutdownOnStartupValue" true) .) | nindent 10 }}
###########################################################
*/}}
}
{{- define "dotcms.container.spec" -}}
image: {{ include "dotcms.image" . }}
imagePullPolicy: {{ .Values.imagePullPolicy }}
resources:
  requests:
    cpu: '{{ .Values.resources.requests.cpu }}'
    memory: {{ .Values.resources.requests.memory }}
  limits:
    cpu: '{{ .Values.resources.limits.cpu }}'
    memory: {{ .Values.resources.limits.memory }}
env:
  - name: DOT_SHUTDOWN_ON_STARTUP
    value: "{{ .ShutdownOnStartupValue }}"
  - name: CMS_JAVA_OPTS
    value: "-Xmx{{ .Values.javaHeapMax }} {{ .Values.defaultJavaOpts }} {{ .Values.additionalJavaOpts }}"
  - name: DOT_ES_ENDPOINTS
    value: "{{ include "dotcms.opensearch.endpoints" . }}"
  - name: DOT_ES_AUTH_TYPE
    value: {{ $.Values.opensearch.auth.type }}
  - name: DOT_ES_AUTH_BASIC_USER
    valueFrom:
      secretKeyRef:
        name: {{ include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "elasticsearch") }}
        key: username
  - name: DOT_ES_AUTH_BASIC_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "elasticsearch") }}
        key: password        
  - name: DOT_ES_AUTH_BASIC_USER
    valueFrom:
      secretKeyRef:
        name: {{ include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "elasticsearch") }}
        key: username
  - name: DOT_ES_AUTH_BASIC_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "elasticsearch") }}
        key: password        
  - name: DB_DNSNAME
    value: {{ $.Values.database.host }}
  - name: DB_BASE_URL
    value: "{{ printf "jdbc:postgresql://%s:%v/%s?sslmode=prefer" .Values.database.host (int .Values.database.port) (include "dotcms.db.name" .) }}"
  - name: DB_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ include "dotcms.secret.env.name" (dict "Values" .Values "secretName" "database") }}
        key: username
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "dotcms.secret.env.name" (dict "Values" .Values "secretName" "database") }}
        key: password
  {{- if .UseLicense }}
  - name: LICENSE
    valueFrom:
      secretKeyRef:
        name: {{ include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "license") }}
        key: license
  {{- end }}
  - name: DOT_ARCHIVE_IMPORTED_LICENSE_PACKS
    value: 'false'
  - name: DOT_REINDEX_THREAD_MINIMUM_RUNTIME_IN_SEC
    value: '120'
  - name: DOT_DOTGENERATED_DEFAULT_PATH
    value: shared
  - name: DOT_DOTCMS_CLUSTER_ID
    value: {{ include "dotcms.opensearch.cluster" . }}
  - name: DOT_REINDEX_THREAD_ELASTICSEARCH_BULK_SIZE
    value: '5'
  - name: DOT_REINDEX_THREAD_ELASTICSEARCH_BULK_ACTIONS
    value: '1'
  - name: DOT_REINDEX_RECORDS_TO_FETCH
    value: '10'
  - name: DOT_SYSTEM_STATUS_API_IP_ACL
    value: 0.0.0.0/0
  {{- if eq $.Values.cloud_provider "aws" }}
  - name: DOT_REMOTE_CALL_SUBNET_BLACKLIST
    value: {{ .Values.remoteCallSubnetBlacklist }}
  {{- end }}
  - name: DOT_REMOTE_CALL_ALLOW_REDIRECTS
    value: 'true'
  - name: DOT_URI_NORMALIZATION_FORBIDDEN_REGEX
    value: \/\/html\/.*
  - name: DOT_COOKIES_HTTP_ONLY
    value: 'true'
  - name: COOKIES_SECURE_FLAG
    value: always
  - name: CACHE_CATEGORYPARENTSCACHE_SIZE
    value: '25000'
  - name: CACHE_CONTENTLETCACHE_SIZE
    value: '15000'
  - name: CACHE_H22_RECOVER_IF_RESTARTED_IN_MILLISECONDS
    value: '60000'
  - name: DOT_CACHE_GRAPHQLQUERYCACHE_SECONDS
    value: '1200'
  - name: DOT_ENABLE_SYSTEM_TABLE_CONFIG_SOURCE
    value: 'false'  
  {{- if $.Values.telemetry.enabled }}
  - name: DOT_FEATURE_FLAG_TELEMETRY
    value: 'true'
  - name: DOT_TELEMETRY_SAVE_SCHEDULE
    value: 0 0 */8 * * ?
  - name: DOT_TELEMETRY_CLIENT_CATEGORY
    value: {{ .Values.telemetry.telemetryClient | quote }}
  {{- end }}
  - name: TOMCAT_REDIS_SESSION_ENABLED
    value: '{{ .Values.redisSessions.enabled }}'
  {{- if .Values.redisSessions.enabled }}
  - name: TOMCAT_REDIS_SESSION_HOST
    value: '{{ $.Values.redis.sessionHost }}'
  - name: TOMCAT_REDIS_SESSION_PORT
    value: '{{ $.Values.redis.port }}'
  - name: TOMCAT_REDIS_SESSION_PASSWORD
    value: '{{ $.Values.redis.password }}'
  - name: TOMCAT_REDIS_SESSION_SSL_ENABLED
    value: '{{ $.Values.redis.sslEnabled }}'
  - name: TOMCAT_REDIS_SESSION_PERSISTENT_POLICIES
    value: '{{ $.Values.redis.sessionPersistentPolicies }}'
  {{- end }}
  {{- if .Values.mail.enabled }}
  - name: DOT_MAIL_SMTP_HOST
    value: '{{ $.Values.mail.host }}'
  - name: DOT_MAIL_SMTP_USER
    valueFrom:
      secretKeyRef:
        name: {{ include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "ses") }}
        key: username
  - name: DOT_MAIL_SMTP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "ses") }}
        key: password
  {{- end }}
  # Custom environment variables
  {{- range $key, $value := .Values.customEnvVars }}
  - name: {{ $key }}
    value: {{ $value | quote }}
  {{- end }}  
volumeMounts:
  - name: dotcms-shared
    mountPath: /data/shared
  {{- if .IsUpgradeJob }}
  - name: admin-shared-{{ .Values.environment }}
    mountPath: /tmp
  {{- end }}
  {{- if .Values.secrets.useSecretsStoreCSI }}
  - mountPath: /mnt/{{ include "dotcms.secret.provider.className" .  }}
    name: {{ include "dotcms.secret.provider.className" .  }}
    readOnly: true
  {{- end }}
{{- if not .IsUpgradeJob }}
ports:
  - containerPort: 8080
    name: api
  - containerPort: 8081
    name: web-insecure
  - containerPort: 8082
    name: web-secure
  - containerPort: 5701
    name: hazelcast
{{- end }}
{{- if .EnableProbes }}
startupProbe:
  httpGet:
    path: {{ .Values.startupProbe.httpGet.path }}
    port: {{ .Values.startupProbe.httpGet.port }}
  initialDelaySeconds: {{ .Values.startupProbe.initialDelaySeconds }}
  periodSeconds: {{ .Values.startupProbe.periodSeconds }}
  successThreshold: {{ .Values.startupProbe.successThreshold }}
  failureThreshold: {{ .Values.startupProbe.failureThreshold }}
  timeoutSeconds: {{ .Values.startupProbe.timeoutSeconds }}
livenessProbe:
  httpGet:
    path: {{ .Values.livenessProbe.httpGet.path }}
    port: {{ .Values.livenessProbe.httpGet.port }}
  initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
  periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
  successThreshold: {{ .Values.livenessProbe.successThreshold }}
  failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
  timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
readinessProbe:
  httpGet:
    path: {{ .Values.readinessProbe.httpGet.path }}
    port: {{ .Values.readinessProbe.httpGet.port }}
  initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
  periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
  successThreshold: {{ .Values.readinessProbe.successThreshold }}
  failureThreshold: {{ .Values.readinessProbe.failureThreshold }}
  timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
{{- end }}
{{- if not .IsUpgradeJob }}
lifecycle:
  {{- if .Values.useLicense }}
  postStart:
    exec:
      command:
        - /bin/sh
        - -c
        - |
          mkdir -p /data/shared/assets
          echo "$LICENSE" | base64 -d > /data/shared/assets/license.zip
  {{- end }}
  preStop:
    exec:
      command:
        - sleep
        - '1'
{{- end }}
{{- end }}

{{/*
###########################################################
# dotcms.backupRestoreScript - Backup and Restore script
#
# Parameters:
# - fileName (string): Name of the backup file.
#
# Usage:
# {{ include "dotcms.backupRestoreScript" . | nindent 14 }}
###########################################################
*/}}
{{- define "dotcms.backupRestoreScript" -}}
#!/bin/bash
set -e

if [ -f /tmp/backupRestore ]; then
  echo "Backup/Restore operation detected. Launching original entrypoint..."
else
  echo "Backup/Restore operation not detected. Skipping container"
  OPERATION=none
fi

echo "Operation: ${OPERATION}"
BACKUP_DIR=/mnt/backup
DOTCMS_DATA_DIR=/data/shared
RESTORE_TMP_DIR=${BACKUP_DIR}/restore-temp

echo "Operation set to: $OPERATION"

if [[ "$OPERATION" == "none" ]]; then
  echo "No backup/restore required."
  exit 0
fi

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

  rm -rf ${DB_DUMP} ${DOTCMS_DATA}

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

{{/*
###########################################################
# Environment Configuration Merge Helper
###########################################################

_mergeEnvironment is a helper template that deep merges environment-specific values
with base configuration.

Usage:
{{ include "dotcms.mergeEnvironment" (dict "Values" .Values "envName" "prod") }}
*/}}

{{- define "myapp.mergeEnvironment" -}}
{{- $envConfig := index $.Values.environments .envName -}}
{{- $baseValues := omit $.Values "environments" -}}
{{- $mergedValues := mergeOverwrite (deepCopy $baseValues) $envConfig -}}
{{- $newRoot := deepCopy $ -}}
{{- $_ := set $newRoot "Values" $mergedValues -}}
{{- $_ := set $newRoot.Values "environment" .envName -}}
{{- $newRoot | toYaml -}}
{{- end -}}