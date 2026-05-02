# Kubernetes Hardening Checklist

Use this checklist to validate the current lab state before demos or commits.

## Cluster Add-ons

- [ ] Kyverno is installed and healthy.
  - Check: `kubectl get pods -n kyverno`
- [ ] Gatekeeper is installed before applying `policies/opa-gatekeeper/`.
  - Install: `kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml`
- [ ] Falco is installed in the `falco` namespace.
  - Current install command: `helm install falco falcosecurity/falco -n falco --create-namespace`
  - Check: `helm status falco -n falco`

## Namespaces and Pod Security

- [x] `development` namespace enforces Pod Security `baseline`.
- [x] `production` namespace enforces Pod Security `restricted`.
- [x] `restricted` namespace enforces Pod Security `restricted`.
- [ ] `pod-security/baseline-namespace.yaml` is currently empty and should be completed or removed.

## RBAC

- [x] `developer` Role exists in `development`.
  - Allows `get`, `list`, `create`, and `delete` on pods and deployments.
- [x] `readonly` Role exists in `development`.
  - Allows `get` and `list` on pods.
- [x] `dev-binding` binds user `dev-user` to the `developer` Role.
- [ ] Add a RoleBinding for `readonly` if a read-only user demo is needed.

## Network Policies

- [x] `default-deny` denies ingress and egress for all pods in `development`.
- [x] `allow-nginx` allows ingress to pods labeled `app: nginx` in `development`.
- [ ] `allow-monitoring.yaml` is currently empty and should be completed before claiming monitoring traffic is allowed.

## Admission Policies

- [x] Kyverno `require-nonroot` enforces `securityContext.runAsNonRoot: true` on pods.
  - Excludes `kube-system`, `kyverno`, `trivy-temp`, and `falco`.
- [x] Kyverno `block-latest-tag` blocks images using the `latest` tag.
- [ ] `require-resources.yaml` is currently empty. Add CPU and memory request/limit enforcement if required.
- [x] Gatekeeper `K8sBlockPrivileged` blocks containers with `securityContext.privileged: true`.

## Test Manifests

- [x] `test/good-pod.yaml` runs as non-root using `nginxinc/nginx-unprivileged:1.25` on port `8080`.
- [x] `test/bad-pod.yaml` uses `nginx:latest` and `privileged: true`; it should be denied by the current policies.

## Scanning

- [x] `scanning/trivy.sh` scans Kubernetes context `kind-dev-cluster` and reports `HIGH` and `CRITICAL` findings.
- [x] `scanning/kubescape.sh` runs the Kubescape NSA framework scan.
- [x] `scanning/kube-bench.sh` runs kube-bench with Docker host PID mode.
- [x] GitHub Actions workflow `.github/workflows/security-scan.yml` runs Trivy config scanning and Kubescape on push.

## Known Gaps

- Empty files should be completed or removed: `pod-security/baseline-namespace.yaml`, `network-policies/allow-monitoring.yaml`, `policies/kyverno/require-resources.yaml`, `runtime/audit-policy.yaml`, and `runtime/falco-values.yaml`.
- Kyverno uses deprecated lowercase `validationFailureAction` values. Newer Kyverno versions prefer `Enforce` and `Audit`.
- `test/` is currently untracked unless committed after creating the good and bad pod manifests.
