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

{{- define "dotcms.serviceaccount" -}}
{{- .Values.serviceAccountName | default (printf "%s-sa" .Values.customerName) -}}
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
Jobs helpers
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

{{/*
###########################################################
# dotCMS container specification helpers
###########################################################
*/}}
{{- define "dotcms.container.spec.resources" -}}
resources:
  requests:
    cpu: '{{ .Values.resources.requests.cpu }}'
    memory: {{ .Values.resources.requests.memory }}
  limits:
    cpu: '{{ .Values.resources.limits.cpu }}'
    memory: {{ .Values.resources.limits.memory }}
{{- end }}


{{- define "dotcms.container.spec" -}}
image: {{ include "dotcms.image" . }}
imagePullPolicy: {{ .Values.imagePullPolicy }}
serviceAccountName: {{ include "dotcms.serviceaccount" . }}
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
  {{- if $.Values.telemetry.enabled }}
  - name: DOT_FEATURE_FLAG_TELEMETRY
    value: 'true'
  - name: DOT_TELEMETRY_SAVE_SCHEDULE
    value: 0 0 */8 * * ?
  - name: DOT_TELEMETRY_CLIENT_CATEGORY
    value: {{ .Values.telemetry.telemetryClient | quote }}
  {{- end }}
volumeMounts:
  - name: dotcms-shared
    mountPath: /data/shared
  {{- if .IsUpgradeJob }}
  - name: shared-skip
    mountPath: /tmp
  {{- end }}
  {{- if .Values.secrets.useSecretsStoreCSI }}
  - mountPath: /mnt/{{ include "dotcms.secret.provider.className" .  }}
    name: {{ include "dotcms.secret.provider.className" .  }}
    readOnly: true
  {{- end }}
ports:
  - containerPort: 8080
    name: api
  - containerPort: 8081
    name: web-insecure
  - containerPort: 8082
    name: web-secure
  - containerPort: 5701
    name: hazelcast
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
lifecycle:
  postStart:
    {{- if .Values.useLicense }}
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
        - '20'

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