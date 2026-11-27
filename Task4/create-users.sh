#!/usr/bin/env bash
set -euo pipefail
umask 077
CONTEXT="${KUBE_CONTEXT:-propdevelopment}"
OUT="$(mktemp -d "${TMPDIR:-/tmp}/propdevelopment-users.XXXXXX")"
k() { kubectl --context "$CONTEXT" "$@"; }
k get namespaces >/dev/null
server="$(kubectl config view --minify --context "$CONTEXT" -o jsonpath='{.clusters[0].cluster.server}')"
kubectl config view --raw --flatten --minify --context "$CONTEXT" \
  -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$OUT/ca.crt"
[[ -s "$OUT/ca.crt" ]] || { echo 'CA certificate not found' >&2; exit 1; }

while read -r user group; do
  # Ключи и kubeconfig остаются во временной папке, вне репозитория.
  MSYS2_ARG_CONV_EXCL=/CN= openssl req -new -newkey rsa:2048 -nodes \
    -keyout "$OUT/$user.key" -out "$OUT/$user.csr" -subj "/CN=$user/O=$group" 2>/dev/null
  request="$(base64 < "$OUT/$user.csr" | tr -d '\r\n')"
  csr="pd-$user-$(date +%s)"
  k apply -f - >/dev/null <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $csr
spec:
  request: $request
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: [client auth]
EOF
  k certificate approve "$csr" >/dev/null
  k wait --for=jsonpath='{.status.certificate}' "csr/$csr" --timeout=60s >/dev/null
  k get csr "$csr" -o jsonpath='{.status.certificate}' | base64 -d > "$OUT/$user.crt"
  config="$OUT/$user.conf"
  kubectl --kubeconfig "$config" config set-cluster "$CONTEXT" --server="$server" \
    --certificate-authority="$OUT/ca.crt" --embed-certs=true >/dev/null
  kubectl --kubeconfig "$config" config set-credentials "$user" \
    --client-key="$OUT/$user.key" --client-certificate="$OUT/$user.crt" --embed-certs=true >/dev/null
  kubectl --kubeconfig "$config" config set-context "$user" --cluster="$CONTEXT" --user="$user" >/dev/null
  kubectl --kubeconfig "$config" config use-context "$user" >/dev/null
  k delete csr "$csr" >/dev/null
done <<'EOF'
pd-auditor pd-observers
pd-sales-operator pd-sales-ops
pd-security-officer pd-security
pd-platform-engineer pd-platform-ops
EOF
printf '%s\n' "$OUT"
