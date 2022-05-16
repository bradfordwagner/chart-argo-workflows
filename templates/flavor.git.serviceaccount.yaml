## We are using a k8s resource trigger in events webhook repository
# there is no control for setting the service account of downstream
# which you usally set using `argo submit --serviceaccount ${sa}`
# therefore we are going to give the default the required permissions
{{ $service_account_name := "default" }}
{{ $role_name := "workflow-creator"}}

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $role_name }}
rules:
  - apiGroups: [argoproj.io]
    verbs: ["*"]
    resources: [workflows,workflowtemplates]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ $role_name }}
subjects:
  - kind: ServiceAccount
    name: {{ $service_account_name }}
    namespace: {{ .Release.Namespace }}
roleRef:
  kind: Role
  name: {{ $role_name }}
  apiGroup: rbac.authorization.k8s.io
