{{/*
Common name components
*/}}
{{- define "dotcms.name.customer" -}}
{{- .Values.customer_name -}}
{{- end -}}



{{- define "dotcms.env.fullName" -}}
{{- printf "%s-%s-%s" .Values.app .Values.customer_name .Values.environment -}}
{{- end -}}

{{- define "dotcms.env.serviceName" -}}
{{- printf "%s-%s-svc" .Values.customer_name .Values.environment -}}
{{- end -}}

{{- define "dotcms.env.serviceName.pp" -}}
{{- printf "%s-%s-pp" .Values.customer_name .Values.environment -}}
{{- end -}}

{{- define "dotcms.opensearch.fullName" -}}
{{- "opensearch" -}}
{{- end -}}


{{/*
OpenSearch related helpers
*/}}
{{- define "dotcms.opensearch.cluster" -}}
{{- printf "%s-%s" .Values.customer_name .Values.environment -}}
{{- end -}}

{{/*
Secret naming helpers
*/}}

{{- define "dotcms.secret.env.name" -}}
{{- printf "%s-%s-awssecret-%s-%s" .Values.host_type .Values.customer_name .Values.environment .secretName -}}
{{- end -}}

{{- define "dotcms.secret.shared.name" -}}
{{- printf "%s-%s-awssecret-%s" .Values.host_type .Values.customer_name .secretName -}}
{{- end -}}

{{- define "dotcms.secret.provider.className" -}}
{{- printf "%s-%s-awssecret" .Values.host_type .Values.customer_name -}}
{{- end -}}

{{/*
Volume naming helpers
*/}}
{{- define "dotcms.volume.shared" -}}
{{- printf "%s-%s-efs-pv" .Values.customer_name .Values.environment -}}
{{- end -}}

{{- define "dotcms.storageClassName" -}}
{{- if .Values.storageClassName -}}
{{- .Values.storageClassName -}}
{{- else -}}
{{- $defaultStorageClasses := dict "aws" "efs-sc" "azure" "azurefile" "gcp" "standard" "default" "hostpath" -}}
{{- $provider := .Values.cloud_provider | default "default" -}}
{{- get $defaultStorageClasses $provider | default "hostpath" -}}
{{- end -}}
{{- end -}}

{{- define "dotcms.volume.shared.local" -}}
{{- $type := .type -}}
{{- printf "%s-%s-local-pvc" .Values.customer_name $type -}}
{{- end -}}

{{- define "dotcms.volume.env.local" -}}
{{- $type := .type -}}
{{- printf "%s-%s-%s-local-pvc" .Values.customer_name .Values.environment $type -}}
{{- end -}}

{{/*
Service account helpers
*/}}
{{- define "dotcms.serviceaccount" -}}
{{- .Values.serviceAccountName | default (printf "%s-sa" .Values.customer_name) -}}
{{- end -}}




{{- define "dotcms.pvc.env.name" -}}
{{- printf "%s-%s-efs-pv" .Values.customer_name .Values.environment -}}
{{- end -}}



{{- define "dotcms.ingress.externalHost" -}}
{{- if and (hasKey .Values.dotcms "customExternalHost") .Values.dotcms.customExternalHost -}}
{{- .Values.dotcms.customExternalHost -}}
{{- else if and (hasKey .Values.dotcms "mapToTopLevelDomain") $.Values.dotcms.mapToTopLevelDomain -}}
{{- .Values.dotcms.ingress.hostSuffix -}}
{{- else -}}
{{- printf "%s-%s.%s" .Values.customer_name .Values.environment .Values.dotcms.ingress.hostSuffix -}}
{{- end -}}
{{- end -}}

{{- define "dotcms.db.name" -}}
{{- printf "%s_%s_db" .Values.customer_name .Values.environment | lower | replace "-" "_" -}}
{{- end -}}

{{/*
_mergeEnvironment is a helper template that deep merges environment-specific values
with base configuration.

Usage:
{{ include "dotcms.mergeEnvironment" (dict "Values" .Values "envName" "prod") }}
*/}}
{{- define "myapp.mergeEnvironment" -}}
{{- $envConfig := index $.Values.environments .envName -}}
{{- $overrides := dict "Values" $envConfig -}}
{{- $newRoot := mergeOverwrite . $overrides -}}
{{- $_ := set (index $newRoot "Values") "environment" .envName }}
{{- $newRoot | toYaml -}}
{{- end -}}


{{- define "dotcms.opensearch.endpoints" }}
{{- if $.Values.opensearch.local.enabled }}
{{- $host  := include "dotcms.opensearch.fullName" .  }}
{{- $protocol  := $.Values.opensearch.protocol  }}
{{- $port  := $.Values.opensearch.port  }}
{{- printf "%s://%s:%d" $protocol $host (int $port) }}
{{- else }}
{{- tpl ( .Values.dotcms.opensearch.endpointUrl ) . }}
{{- end }}
{{- end }}