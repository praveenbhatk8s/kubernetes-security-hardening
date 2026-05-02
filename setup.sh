#!/usr/bin/env bash

set -e

echo "Creating folders..."

mkdir -p \
.github/workflows \
namespaces \
rbac \
network-policies \
pod-security \
policies/kyverno \
policies/opa-gatekeeper \
scanning \
secrets \
runtime \
docs

echo "Creating files..."

touch README.md

touch .github/workflows/security-scan.yml
touch .github/workflows/kube-lint.yml

touch namespaces/production.yaml
touch namespaces/development.yaml

touch rbac/readonly-role.yaml
touch rbac/developer-role.yaml
touch rbac/bindings.yaml

touch network-policies/default-deny.yaml
touch network-policies/allow-ingress-nginx.yaml
touch network-policies/allow-monitoring.yaml

touch pod-security/restricted-namespace.yaml
touch pod-security/baseline-namespace.yaml

touch policies/kyverno/require-resources.yaml
touch policies/kyverno/block-latest-tag.yaml
touch policies/kyverno/require-nonroot.yaml

touch scanning/kubescape.sh
touch scanning/trivy.sh
touch scanning/kube-bench.sh

touch secrets/sealed-secrets-example.yaml
touch secrets/external-secrets-example.yaml

touch runtime/falco-values.yaml
touch runtime/audit-policy.yaml

touch docs/hardening-checklist.md
touch docs/cks-notes.md
touch docs/incident-response.md

echo "Done ✅"

# Optional: show structure
command -v tree >/dev/null && tree || find .