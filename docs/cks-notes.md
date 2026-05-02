# CKS Notes

These notes map the current lab files to Certified Kubernetes Security Specialist practice areas.

## Cluster Setup and Hardening

Relevant files:

- `namespaces/development.yaml`
- `namespaces/production.yaml`
- `pod-security/restricted-namespace.yaml`

Current behavior:

- `development` enforces Pod Security `baseline`.
- `production` enforces Pod Security `restricted`.
- `restricted` enforces Pod Security `restricted`.

Practice commands:

```bash
kubectl get ns --show-labels
kubectl label ns development pod-security.kubernetes.io/enforce=baseline --overwrite
kubectl label ns production pod-security.kubernetes.io/enforce=restricted --overwrite
```

## RBAC and Least Privilege

Relevant files:

- `rbac/developer-role.yaml`
- `rbac/readonly-role.yaml`
- `rbac/bindings.yaml`

Current behavior:

- `developer` can `get`, `list`, `create`, and `delete` pods and deployments in `development`.
- `readonly` can `get` and `list` pods in `development`.
- `dev-binding` binds user `dev-user` to the `developer` Role.

Practice commands:

```bash
kubectl auth can-i create pods --as dev-user -n development
kubectl auth can-i delete deployments --as dev-user -n development
kubectl auth can-i create clusterrolebindings --as dev-user
```

## Network Policies

Relevant files:

- `network-policies/default-deny.yaml`
- `network-policies/allow-ingress-nginx.yaml`

Current behavior:

- `default-deny` blocks ingress and egress for all pods in `development`.
- `allow-nginx` allows ingress to pods labeled `app: nginx`.

Practice commands:

```bash
kubectl get networkpolicy -n development
kubectl describe networkpolicy default-deny -n development
```

Note: `network-policies/allow-monitoring.yaml` is currently empty.

## Supply Chain and Image Hygiene

Relevant files:

- `.github/workflows/security-scan.yml`
- `scanning/trivy.sh`
- `scanning/kubescape.sh`

Current behavior:

- GitHub Actions runs Trivy config scanning on push and fails on `HIGH` or `CRITICAL` findings.
- GitHub Actions installs Kubescape and runs the NSA framework scan.
- Local Trivy script scans Kubernetes context `kind-dev-cluster`.

Practice commands:

```bash
./scanning/trivy.sh
./scanning/kubescape.sh
```

## Admission Control

Relevant files:

- `policies/kyverno/require-nonroot.yaml`
- `policies/kyverno/block-latest-tag.yaml`
- `policies/opa-gatekeeper/template.yaml`
- `policies/opa-gatekeeper/constraint.yaml`
- `policies/opa-gatekeeper/no-privileged.yaml`

Current behavior:

- Kyverno requires pods to set `securityContext.runAsNonRoot: true`.
- Kyverno blocks images ending in `:latest`.
- Gatekeeper blocks containers where `securityContext.privileged == true`.

Practice commands:

```bash
kubectl get clusterpolicy
kubectl get constrainttemplate
kubectl get k8sblockprivileged.constraints.gatekeeper.sh
kubectl apply -f test/good-pod.yaml
kubectl apply -f test/bad-pod.yaml
```

Expected result:

- `test/good-pod.yaml` should run.
- `test/bad-pod.yaml` should be denied.

## Runtime Security

Relevant files:

- `runtime/falco-values.yaml`
- `runtime/audit-policy.yaml`

Current behavior:

- Falco is installed with Helm in the `falco` namespace.
- `runtime/falco-values.yaml` and `runtime/audit-policy.yaml` are currently empty.

Practice commands:

```bash
helm status falco -n falco
kubectl get pods -n falco
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100
```

## Secure Pod Example

`test/good-pod.yaml` demonstrates a non-root nginx pod:

- Uses `nginxinc/nginx-unprivileged:1.25`.
- Runs as UID and GID `101`.
- Exposes port `8080`.
- Sets `allowPrivilegeEscalation: false`.
- Drops all Linux capabilities.
- Uses `emptyDir` mounts for nginx writable paths.

## Unsafe Pod Example

`test/bad-pod.yaml` demonstrates what should be blocked:

- Uses `nginx:latest`.
- Sets `securityContext.privileged: true`.

## Known Lab Gaps

- Add resource request and limit policy in `policies/kyverno/require-resources.yaml`.
- Complete monitoring network policy in `network-policies/allow-monitoring.yaml`.
- Add explicit Falco values and Kubernetes audit policy under `runtime/`.
- Update Kyverno `validationFailureAction` values from lowercase `enforce` to `Enforce` for newer Kyverno versions.
