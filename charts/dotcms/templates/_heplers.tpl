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
  {{- $secretName := .secretName -}}
  {{- $overridePath := .overridePath | default "" -}}
  {{- $overrideValue := "" -}}
  {{- if ne $overridePath "" -}}
    {{- $overrideValue = get .Values (splitList "." $overridePath) | default "" -}}
  {{- end -}}
  {{- if and $overrideValue (ne (trim $overrideValue) "") -}}
    {{- printf "%s" $overrideValue -}}
  {{- else -}}
    {{- printf "%s-%s-%ssecret-%s-%s" .Values.hostType .Values.customerName .Values.cloudProvider .Values.environment $secretName -}}
  {{- end -}}
{{- end -}}

{{- define "dotcms.secret.shared.name" -}}
  {{- $secretName := .secretName -}}
  {{- $overridePath := .overridePath | default "" -}}
  {{- $overrideValue := "" -}}
  {{- if ne $overridePath "" -}}
    {{- $overrideValue = get .Values (splitList "." $overridePath) | default "" -}}
  {{- end -}}
  {{- if and $overrideValue (ne (trim $overrideValue) "") -}}
    {{- printf "%s" $overrideValue -}}
  {{- else -}}
    {{- printf "%s-%s-%ssecret-%s" .Values.hostType .Values.customerName .Values.cloudProvider $secretName -}}
  {{- end -}}
{{- end -}}

{{- define "dotcms.secret.provider.className" -}}
{{- printf "%s-%s-%ssecret" .Values.hostType .Values.cloudProvider .Values.customerName -}}
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
{{- define "dotcms.container.spec" -}}
{{- $envName := .envName }}
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
  {{- include "dotcms.container.spec.envVars" . }}
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
# Helper: dotcms.container.spec.envVars
###########################################################
# This helper generates the container environment variables block by merging
# the default environment variables and any custom overrides.
#
# Usage:
# - It reads default values from `.Values.envVarsDefaults`.
# - It reads custom override values from `.Values.envVarsOverrides`.
# - It also includes additional variables from the features helper.
# - The helper uses `mergeOverwrite` to combine these maps, with overrides taking
#   precedence over defaults.
# - Each merged key-value pair is first evaluated with the `tpl` function to
#   resolve dynamic expressions.
# - If the evaluated value begins with "SECRET:" and has the format 
#   "SECRET:secretName:key" (i.e. splits into exactly three parts),
#   the helper calls the sub-helper `dotcms.container.spec.renderSecret` to render
#   the variable using a `valueFrom.secretKeyRef` block.
# - Otherwise, the variable is rendered normally using a `value:` block.
#
# This design ensures that secret references are handled correctly while allowing
# standard environment variables to be defined in a centralized way.
#
# Example usage in a container spec:
#   env:
#     {{ include "dotcms.container.spec.envVars" . | nindent 2 }}
###########################################################
*/}}
{{- define "dotcms.container.spec.envVars" -}}
  {{- $context := . -}}
  {{- $defaultEnv := .Values.envVarsDefaults | default dict }}
  {{- $customEnv := .Values.envVarsOverrides | default dict }}
  {{- $featuresEnv := fromYaml (include "dotcms.envVars.features" .) | default dict }}
  {{- $mergedEnv := mergeOverwrite $defaultEnv $customEnv $featuresEnv }}
  {{- range $key, $value := $mergedEnv }}
  {{- $evaluatedValue := tpl $value $context }}
  {{- if contains "SECRET:" $evaluatedValue }}
  {{- $parts := splitList ":" $evaluatedValue -}}
  {{- if ne (len $parts) 3 -}}
    {{- fail (printf "Invalid secret format for env var %s: expected SECRET:secretName:key" .envName) -}}
  {{- end -}}  
  {{- $secretArgs := rest $parts }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ first $secretArgs | quote }}
      key: {{ $secretArgs | last | quote }}
  {{- else }}
- name: {{ $key }}
  value: {{ $evaluatedValue | quote }}
  {{- end }}
  {{- end }}
{{- end -}}

{{/*
###########################################################
# Helper: dotcms.envVars.features
###########################################################
# This helper generates additional environment variable mappings 
# based on enabled feature flags. It conditionally adds blocks for 
# features such as Analytics, Mail, Glowroot, and Redis Sessions.
# Each block is rendered only if its corresponding feature flag is true.
###########################################################
*/}}
{{- define "dotcms.envVars.features" -}}
{{- $feat := .Values.feature | default dict }}
{{- $redis := index $feat "redisSessions" | default dict }}

{{- $analytics := $feat.analytics | default (dict) }}
{{- if $analytics.enabled | default false }}
DOT_FEATURE_FLAG_EXPERIMENTS: "true"
DOT_ENABLE_EXPERIMENTS_AUTO_JS_INJECTION: {{ default false $analytics.autoInjection | quote }}
DOT_ANALYTICS_IDP_URL: {{ default "" $analytics.idpUrl | quote }}
{{- end }}

{{- if .Values.mail.enabled | default false }}
DOT_MAIL_SMTP_HOST: {{ default "" .Values.mail.smtp.host | quote }}
DOT_MAIL_SMTP_PORT: {{ default 587 .Values.mail.smtp.port | quote }}
DOT_MAIL_SMTP_STARTTLS_ENABLE: {{ default true .Values.mail.smtp.starttlsEnable | quote }}
DOT_MAIL_SMTP_AUTH: {{ default true .Values.mail.smtp.auth | quote }}
DOT_MAIL_SMTP_SSL_PROTOCOLS: {{ default "TLSv1.2" .Values.mail.smtp.sslProtocols | quote }}
{{- end }}

{{- $glow := $feat.glowroot | default (dict) }}
{{- if $glow.enabled | default false }}
GLOWROOT_ENABLED: "true"
GLOWROOT_AGENT_ID: {{ $glow.agentIdOverride | default (printf "%s::%s" .Values.customerName .envName) }}
GLOWROOT_COLLECTOR_ADDRESS: {{ $glow.collectorAddress | default "http://glowrootcentral.dotcmscloud.com:8181" }}
{{- end }}

{{- if default false (index $redis "enabled") }}
TOMCAT_REDIS_SESSION_ENABLED: "true"
TOMCAT_REDIS_SESSION_HOST: {{ default "" (index $redis "redisHost") | quote }}
TOMCAT_REDIS_SESSION_PORT: {{ default 6379 (index $redis "port") | quote }}
TOMCAT_REDIS_SESSION_PASSWORD: {{ default "" (index $redis "password") | quote }}
TOMCAT_REDIS_SESSION_SSL_ENABLED: {{ default false (index $redis "sslEnabled") | quote }}
TOMCAT_REDIS_SESSION_PERSISTENT_POLICIES: {{ default "DEFAULT" (index $redis "sessionPersistentPolicies") | quote }}
{{- end }}

{{- end }}

  {{/*
###########################################################
# dotcms.ingress.alb.annotations
###########################################################
# This helper generates the ALB Ingress annotations required for configuring
# an AWS Application Load Balancer (ALB). It outputs several key annotations:
#
# 1. Target Group Attributes
# 2. Load Balancer Attributes
# 3. SSL Policy
# 4. Security Groups
# 5. Certificate ARN
#
# Example usage:
#   {{ include "dotcms.ingress.alb.annotations" . }}
###########################################################
*/}}
{{- define "dotcms.ingress.alb.annotations" -}}
alb.ingress.kubernetes.io/target-group-attributes: {{- if "dotcms.ingress.alb.hosts.stickySessions.enabled" }} stickiness.enabled=true,stickiness.lb_cookie.duration_seconds={{ .Values.ingress.alb.hosts.stickySessions.duration }} {{- end }}
alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds={{ .Values.ingress.alb.hosts.idleTimeout }}{{- if .Values.ingress.alb.hosts.accessLogs.enabled }},access_logs.s3.enabled=true,access_logs.s3.bucket={{ .Values.ingress.alb.hosts.accessLogs.bucketOverride }},access_logs.s3.prefix={{ .Values.ingress.alb.hosts.accessLogs.prefixOverride }}{{- end }}
alb.ingress.kubernetes.io/ssl-policy: {{ required "ingress.alb.hosts.default.sslPolicy is required when ingress.type is 'alb'" .Values.ingress.alb.hosts.default.sslPolicy }}
alb.ingress.kubernetes.io/security-groups: {{ required "ingress.alb.securityGroups is required when ingress.type is 'alb'" (include "dotcms.ingress.alb.securityGroups" .) }}
alb.ingress.kubernetes.io/certificate-arn: {{ required "ingress.alb.hosts.default.certificateArn is required when ingress.type is 'alb'" (include "dotcms.ingress.alb.certificateArns" .) }}
{{- end }}

{{/*
###########################################################
# dotcms.ingress.alb.certificateArns
###########################################################
# This helper generates a list of certificate ARNs to be used in the ALB Ingress annotation.
#
# It takes into account:
# - The default certificate ARN defined in .Values.ingress.alb.hosts.default.certificateArn,
#   if .Values.ingress.alb.hosts.default.enabled is true.
#
# - Additional certificate ARNs defined in .Values.ingress.alb.hosts.additionalCertificateArns.
#
# The ARNs are joined into a single string, separated by commas and spaces,
# and the resulting string is wrapped in single quotes.
#
# Example usage:
#   {{ include "dotcms.ingress.alb.certificateArns" . }}
###########################################################
*/}}
{{- define "dotcms.ingress.alb.certificateArns" -}}
'{{- $allArns := list -}}
{{- if .Values.ingress.alb.hosts.default.enabled -}}
  {{- $defaultArn := .Values.ingress.alb.hosts.default.certificateArn | default "" -}}
  {{- if $defaultArn -}}
    {{- $allArns = append $allArns $defaultArn -}}
  {{- end -}}
{{- end -}}
{{- $additionalArns := .Values.ingress.alb.hosts.additionalCertificateArns | default list -}}
{{- range $arn := $additionalArns -}}
  {{- $allArns = append $allArns $arn -}}
{{- end -}}
{{ join ", " $allArns -}}'
{{- end -}}

{{/*
###########################################################
# dotcms.ingress.alb.securityGroups
###########################################################
# This helper generates the list of security groups to be applied to the ALB Ingress.
#
# It works as follows:
# - If .Values.ingress.alb.securityGroups.useDefaults is true, it includes:
#     * The default groups defined in .Values.ingress.alb.securityGroups.default.
#     * Additional groups defined in .Values.ingress.alb.securityGroups.additional.
#
# The groups are joined into a single string, separated by commas and spaces,
# and the resulting string is wrapped in single quotes.
#
# Example usage:
#   {{ include "dotcms.ingress.alb.securityGroups" . }}
###########################################################
*/}}
{{- define "dotcms.ingress.alb.securityGroups" -}}
'{{- $groups := list -}}
{{- if .Values.ingress.alb.securityGroups.useDefaults -}}
  {{- $defaultGroups := .Values.ingress.alb.securityGroups.default | default list -}}
  {{- $additionalGroups := .Values.ingress.alb.securityGroups.additional | default list -}}
  {{- range $index, $group := $defaultGroups -}}
    {{- $groups = append $groups $group -}}
  {{- end -}}
  {{- range $index, $group := $additionalGroups -}}
    {{- $groups = append $groups $group -}}
  {{- end -}}
{{- end -}}
{{- join ", " $groups -}}'
{{- end -}}

{{/*
###########################################################
# dotcms.ingress.alb.additionalHosts
###########################################################
# This helper renders the YAML block for additional hosts for an ALB Ingress.
#
# If the ingress type is "alb", it iterates over the list defined in
# .Values.ingress.alb.hosts.additionalHosts and renders each host as:
#
#   - host: "host_value"
#
# Example usage:
#   {{ include "dotcms.ingress.alb.additionalHosts" . }}
###########################################################
*/}}
{{- define "dotcms.ingress.alb.additionalHosts" -}}
{{- if eq .Values.ingress.type "alb" -}}
{{- $additionalHosts := .Values.ingress.alb.hosts.additionalHosts | default list -}}
{{ range $host := $additionalHosts -}}
- host: {{ $host | quote }}
{{ end }}
{{- end -}}
{{- end -}}

{{- define "dotcms.debug.context" -}}
{{ . | toYaml }}
{{- end }}


{{/*
###########################################################
# Helper: dotcms.customStarter.url
###########################################################
# This helper generates the URL for downloading the custom starter package
# based on the merged environment configuration.
#
# Usage:
# - If `starterUrlOverride` is provided in `.Values.customStarter`,
#   that value is returned directly.
# - Otherwise, if `repo`, `groupId`, `artifactId`, and `version` are defined in
#   `.Values.customStarter`, the helper constructs the URL dynamically in the format:
#   `{repo}/{groupId with dots replaced by '/'}/{artifactId}/{version}/{artifactId}-{version}.zip`
# - If neither condition is met, an empty string is returned.
#
# This ensures flexibility in defining custom starter package URLs, 
# allowing both direct overrides and dynamically constructed values.
###########################################################
*/}}
{{- define "dotcms.customStarter.url" -}}
  {{- $customStarter := .Values.customStarter | default dict }}
  {{- if $customStarter.starterUrlOverride }}
    {{- $customStarter.starterUrlOverride }}
  {{- else if and $customStarter.repo $customStarter.groupId $customStarter.artifactId $customStarter.version -}}
    {{ printf "%s/%s/%s/%s/%s-%s.zip" 
      $customStarter.repo 
      (replace "." "/" $customStarter.groupId) 
      $customStarter.artifactId 
      $customStarter.version 
      $customStarter.artifactId 
      $customStarter.version }}
  {{- else -}}
  {{- end -}}
{{- end }}

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