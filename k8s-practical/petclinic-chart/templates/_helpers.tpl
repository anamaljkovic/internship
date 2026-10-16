{{/*
Chart name.
*/}}
{{- define "petclinic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Full resource name: <release>-<chart>, or just <release> if it already contains the chart name.
*/}}
{{- define "petclinic.fullname" -}}
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
Chart name and version, used in the helm.sh/chart label.
*/}}
{{- define "petclinic.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Labels that never change between upgrades (used in selectors).
The component label (app / mysql) is added in each template.
*/}}
{{- define "petclinic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "petclinic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "petclinic.labels" -}}
helm.sh/chart: {{ include "petclinic.chart" . }}
{{ include "petclinic.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Name used by the MySQL Deployment, Service and PVC.
*/}}
{{- define "petclinic.mysql.fullname" -}}
{{- printf "%s-mysql" (include "petclinic.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of the Secret with the database credentials (an existing one, or the one this chart creates).
*/}}
{{- define "petclinic.secretName" -}}
{{- if .Values.mysql.auth.existingSecret }}
{{- .Values.mysql.auth.existingSecret }}
{{- else }}
{{- printf "%s-db" (include "petclinic.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}