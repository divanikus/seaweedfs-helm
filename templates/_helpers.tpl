{{/*
Expand the name of the chart.
*/}}
{{- define "seaweedfs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "seaweedfs.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "seaweedfs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "seaweedfs.labels" -}}
helm.sh/chart: {{ include "seaweedfs.chart" . }}
{{ include "seaweedfs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "seaweedfs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "seaweedfs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "seaweedfs.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "seaweedfs.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Return the proper imagePullSecrets */}}
{{- define "seaweedfs.imagePullSecrets" -}}
{{- if .Values.image.pullSecrets }}
{{- if kindIs "string" .Values.image.pullSecrets }}
imagePullSecrets:
  - name: {{ .Values.image.pullSecrets }}
{{- else -}}
imagePullSecrets:
{{- range .Values.image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/* Computes the container image name for all components (if they are not overridden) */}}
{{- define "common.image" -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag | toString -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}

{{/* check if any Master PVC exists */}}
{{- define "master.pvc_exists" -}}
{{- if or (and .Values.master.persistence.enabled (not .Values.master.persistence.existingClaim)) (and .Values.master.logs.persistence.enabled (not .Values.master.logs.persistence.existingClaim)) }}
{{- printf "true" -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{/* check if any Filer PVC exists */}}
{{- define "filer.pvc_exists" -}}
{{- if or (and .Values.filer.persistence.enabled (not .Values.filer.persistence.existingClaim)) (and .Values.filer.logs.persistence.enabled (not .Values.filer.logs.persistence.existingClaim)) }}
{{- printf "true" -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{/* check if any S3 PVC exists */}}
{{- define "s3.pvc_exists" -}}
{{- if and .Values.s3.logs.persistence.enabled (not .Values.s3.logs.persistence.existingClaim) }}
{{- printf "true" -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{/* check if any Volume PVC exists */}}
{{- define "volume.disks_pvc_exists" -}}
{{- if or (not .persistence) (not .persistence.enabled) -}}
{{- printf "" -}}
{{- else -}}
{{- $found := false -}}
{{- range .persistence.disks -}}
  {{- if eq .existingClaim "" -}}
    {{- $found = true -}}
  {{- end -}}
{{- end -}}
{{- $found }}
{{- end -}}
{{- end -}}

{{- define "volume.idx_pvc_exists" -}}
{{- if or (not .persistence) (not .persistence.enabled) -}}
{{- printf "" -}}
{{- else if and .persistence.idx (eq .persistence.idx.existingClaim "") -}}
{{- printf "true" -}}
{{- end -}}
{{- end -}}

{{- define "volume.logs_pvc_exists" -}}
{{- if and .persistence .persistence.enabled (not .persistence.existingClaim) -}}
{{- printf "true" -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{/* check if any Master PVC exists */}}
{{- define "server.pvc_exists" -}}
{{- if or (and .Values.server.persistence.enabled (not .Values.server.persistence.existingClaim)) (and .Values.server.logs.persistence.enabled (not .Values.server.logs.persistence.existingClaim)) }}
{{- printf "true" -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{- define "args.value.render" }}
{{- $kind := kindOf . }}
{{- if (eq $kind "bool") }}
{{- if empty . }}={{ . }}{{- end }}
{{- else -}}
={{ ternary (quote .) . (eq $kind "string") }}
{{- end }}
{{- end }}

{{/*
Renders a value that contains template perhaps with scope if the scope is present.
Usage:
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $ ) }}
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $ "scope" $app ) }}
*/}}
{{- define "common.tplvalues.render" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
{{- if contains "{{" (toJson .value) }}
  {{- if .scope }}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $value "{{- end }}") (merge (dict "RelativeScope" .scope) .context) }}
  {{- else }}
    {{- tpl $value .context }}
  {{- end }}
{{- else }}
    {{- $value }}
{{- end }}
{{- end -}}
