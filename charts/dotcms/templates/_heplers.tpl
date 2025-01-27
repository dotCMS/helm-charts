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
{{ .Values.customer_name }}-{{ .Values.environment }}-pre-upgrade
{{- end }}

{{- define "dotcms.postUpgradeJobName" -}}
{{ .Values.customer_name }}-{{ .Values.environment }}-post-upgrade
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