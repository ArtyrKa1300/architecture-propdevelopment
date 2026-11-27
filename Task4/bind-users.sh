#!/usr/bin/env bash
set -euo pipefail
CONTEXT="${KUBE_CONTEXT:-propdevelopment}"
k() { kubectl --context "$CONTEXT" "$@"; }

k apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pd-observers
subjects:
- kind: Group
  name: pd-observers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pd-cluster-observer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pd-platform-ops
subjects:
- kind: Group
  name: pd-platform-ops
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pd-infrastructure-configurator
  apiGroup: rbac.authorization.k8s.io
EOF

for domain in sales housing finance data; do
  k apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pd-domain-ops
  namespace: pd-$domain
subjects:
- kind: Group
  name: pd-$domain-ops
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: pd-platform-ops
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pd-domain-configurator
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pd-security
  namespace: pd-$domain
subjects:
- kind: Group
  name: pd-security
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pd-secret-reader
  apiGroup: rbac.authorization.k8s.io
EOF
done
