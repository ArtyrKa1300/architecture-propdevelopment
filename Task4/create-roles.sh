#!/usr/bin/env bash
set -euo pipefail
CONTEXT="${KUBE_CONTEXT:-propdevelopment}"
k() { kubectl --context "$CONTEXT" "$@"; }

k apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd-cluster-observer
rules:
- apiGroups: [""]
  resources: [pods, services, endpoints, namespaces, nodes, resourcequotas, limitranges]
  verbs: [get, list, watch]
- apiGroups: [apps]
  resources: [deployments, replicasets, statefulsets, daemonsets]
  verbs: [get, list, watch]
- apiGroups: [networking.k8s.io]
  resources: [networkpolicies, ingresses]
  verbs: [get, list, watch]
- apiGroups: [rbac.authorization.k8s.io]
  resources: [roles, rolebindings, clusterroles, clusterrolebindings]
  verbs: [get, list, watch]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd-infrastructure-configurator
rules:
- apiGroups: [""]
  resources: [nodes]
  verbs: [get, list, watch, update, patch]
- apiGroups: [""]
  resources: [namespaces]
  verbs: [get, list, watch, create, update, patch]
EOF

for domain in sales housing finance data; do
  ns="pd-$domain"
  k create namespace "$ns" --dry-run=client -o yaml | k apply -f -
  k apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pd-domain-configurator
  namespace: $ns
rules:
- apiGroups: [""]
  resources: [services, resourcequotas, limitranges]
  verbs: [get, list, watch, create, update, patch, delete]
- apiGroups: [networking.k8s.io]
  resources: [networkpolicies, ingresses]
  verbs: [get, list, watch, create, update, patch, delete]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pd-secret-reader
  namespace: $ns
rules:
- apiGroups: [""]
  resources: [secrets]
  verbs: [get, list]
EOF
done
