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

{{- define "parameter.from.input" }}
- name: {{ . }}
  value: "{{ printf `{{ inputs.parameters.%s }}` . }}"
{{- end }}

{{- define "go.parameters" }}
inputs:
  parameters:
    - name: git_repo
    - name: git_version
    - name: upstream_repo
    - name: upstream_tag
    - name: platform
    # standard vault variables
    - name: vault_secrets_enabled
      value: false
    - name: vault_env_secrets_paths
      value: "[]"
    - name: vault_role
      value: "default"
    # issues token for the same role to use in terraform - good for vault provider
    - name: vault_issue_token
      value: false
{{- end }}

{{- define "ansible.parameters" }}
inputs:
  parameters:
  - name: git_repo
  - name: git_version
  - name: upstream_repo
  - name: upstream_tag
  # suffix to add to the end of our tag ie ${git_version}-${upstream_tag_suffix} which is usually platform or platform+version
  - name: tag_suffix
  - name: repo_name
  - name: platform
  - name: ansible_destroy
    value: 'true'
  - name: ansible_args
    value: |
      [{"platform": "linux/amd64", "ansible_extra_args": ""}]
{{- end }}

{{- define "vault.secret.import.script" }}
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_FORMAT=json
for i in {1..10}; do
  vault status 1>&- 2>&- # disable output
  status_code=$?
  if [ ${status_code} -eq 0 ]; then
    echo Vault Agent Sidecar Ready
  fi
  sleep 1
done

# ensure we have something to source no matter what
touch ./source.sh

# create a vault token for terraform to use if necessary - a subtoken of the current
if [ "{{`{{ inputs.parameters.vault_issue_token }}`}}" = true ]; then
  vault token create | jq -r '.auth.client_token | "export VAULT_TOKEN=\(.)"' > source.sh
fi

# take vault_env_secrets_paths and make each key and environment variable with its value
echo "{{`{{=sprig.join('\n', sprig.fromJson(inputs.parameters.vault_env_secrets_paths))}}`}}" > paths.txt
num_env_secrets=$(cat paths.txt | wc -l)
if [ "${num_env_secrets}" -gt "0" ]; then
  echo Importing ${num_env_secrets} Vault Secrets into ENV
  cat paths.txt
  # for each path and for each key in each path export the variable into source.sh
  cat paths.txt | xargs -I % vault kv get % | jq -r '.data.data | to_entries | .[] | "export \(.key)=\(.value)"' >> source.sh
fi

# source imported environment variables
. ./source.sh
rm source.sh # cleanup
{{- end }}

{{- define "combine-manifest" }}
{{- $platform_json       := default "{{`{{inputs.parameters.runtime_platforms}}`}}" .platform_json -}}
{{- $platform_json_pluck := default "" .platform_json_pluck -}}
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
        # tag-upstreamSuffix
        value: "{{`{{ inputs.parameters.git_version }}`}}{{`{{ inputs.parameters.tag_suffix }}`}}"
        {{ else }}
        value: "latest-{{`{{inputs.parameters.upstream_tag_suffix`}}"
        {{- end }}
      - name: runtime_platforms_json
        value: '{{ $platform_json }}'
      - name: runtime_platforms_json_pluck
        value: '{{ $platform_json_pluck }}'
{{- end }}
