{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fullname" -}}
{{ .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "labels" -}}
helm.sh/chart: {{ include "chart" . }}
{{ include "selector_labels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "selector_labels" -}}
app.kubernetes.io/name: {{ include "name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
inputs:
template = tags|branches
depends = task to wait on
*/}}

{{- define "combine-manifest" }}
# only publish manifest on tags
- name: combine-manifest
  depends: {{ .depends }}
  templateRef:
    name: manifest-template
    template: main
  arguments:
    parameters:
      - name: repo_name
        value: "{{`{{inputs.parameters.repo_name}}`}}"
      # base tag to use ie
      # tag-upstream_upstreamtag
      - name: tag
        {{ if eq .template "tags" }}
        # tag-upstream_upstreamtag
        value: "{{`{{ inputs.parameters.git_version }}`}}-{{`{{=sprig.default(inputs.parameters.upstream_repo, inputs.parameters.upstream_repo_name_override)}}`}}_{{`{{ inputs.parameters.upstream_tag }}`}}"
        {{ else }}
        value: "latest-{{`{{=sprig.default(inputs.parameters.upstream_repo, inputs.parameters.upstream_repo_name_override)}}`}}_{{`{{ inputs.parameters.upstream_tag }}`}}"
        {{- end }}
      - name: runtime_platforms_json
        value: "{{`{{inputs.parameters.runtime_platforms}}`}}"

{{- end }}