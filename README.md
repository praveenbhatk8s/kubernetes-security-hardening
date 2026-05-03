# Kubernetes Security Hardening Lab

[![DevSecOps Pipeline](https://github.com/praveenbhatk8s/kubernetes-security-hardening/actions/workflows/security-scan.yml/badge.svg)](https://github.com/praveenbhatk8s/kubernetes-security-hardening/actions/workflows/security-scan.yml)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Security%20Hardening-326CE5?logo=kubernetes&logoColor=white)
![Kyverno](https://img.shields.io/badge/Kyverno-Policy%20as%20Code-2563EB)
![Falco](https://img.shields.io/badge/Falco-Runtime%20Detection-00AEC7)
![Trivy](https://img.shields.io/badge/Trivy-Cluster%20Scanning-1904DA)

Practical Kubernetes security hardening lab for proving admission control, runtime detection, network isolation, RBAC, and CI/CD security checks on a local kind cluster.

The goal is to make security controls visible and testable: apply a bad pod and watch it get denied, apply a good pod and watch it run, then validate the cluster with scanners.

It covers:

- Pod Security Standards on namespaces
- Least-privilege RBAC
- Default-deny NetworkPolicies
- Kyverno admission policies
- OPA Gatekeeper constraints
- Falco runtime detection
- Trivy, Kubescape, and kube-bench scanning
- Good and bad pod test manifests
- GitHub Actions CI security scanning

## Prerequisites

Install these tools before running the lab:

```bash
kubectl
helm
kind
docker
trivy
kubescape
```

The local Kubernetes context used by the scan script is:

```bash
kind-dev-cluster
```

Check your current context:

```bash
kubectl config current-context
```

## 1. Install Kyverno

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

Verify:

```bash
kubectl get pods -n kyverno
```

## 2. Install OPA Gatekeeper

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

Verify:

```bash
kubectl get pods -n gatekeeper-system
kubectl get constrainttemplates
```

## 3. Install Falco

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco -n falco --create-namespace
```

If Falco is already installed, check it instead of installing again:

```bash
helm status falco -n falco
kubectl get pods -n falco
```

## 4. Apply Base Kubernetes Security Resources

Run these commands from the repo root:

```bash
kubectl apply -f namespaces/
kubectl apply -f rbac/
kubectl apply -f network-policies/
kubectl apply -f pod-security/
```

Notes:

- `development` enforces Pod Security `baseline`.
- `production` enforces Pod Security `restricted`.
- `restricted` enforces Pod Security `restricted`.
- `network-policies/default-deny.yaml` denies ingress and egress in `development`.
- `network-policies/allow-ingress-nginx.yaml` allows ingress to pods labeled `app: nginx`.

## 5. Apply Admission Policies

The `policies/` directory contains subdirectories, so apply it recursively:

```bash
kubectl apply -R -f policies/
```

Expected policies:

- Kyverno `require-nonroot` requires pods to set `securityContext.runAsNonRoot: true`.
- Kyverno `block-latest-tag` blocks images using the `latest` tag.
- Gatekeeper `K8sBlockPrivileged` blocks privileged containers.

Verify:

```bash
kubectl get clusterpolicy
kubectl get constrainttemplate
kubectl get k8sblockprivileged.constraints.gatekeeper.sh
```

## 6. Test a Good Pod

Apply the hardened test pod:

```bash
kubectl apply -f test/good-pod.yaml
kubectl get pod good
```

Expected result:

```text
good   1/1   Running
```

The good pod uses:

- `nginxinc/nginx-unprivileged:1.25`
- non-root UID and GID `101`
- container port `8080`
- `allowPrivilegeEscalation: false`
- dropped Linux capabilities
- writable `emptyDir` mounts for nginx runtime paths

## 7. Test a Bad Pod

Apply the intentionally unsafe pod:

```bash
kubectl apply -f test/bad-pod.yaml
```

Expected result:

- Kyverno should reject `nginx:latest`.
- Gatekeeper should reject `securityContext.privileged: true`.

The bad pod is included only to prove that admission controls are working.

## 8. Run Security Scans

Run Trivy against the local cluster context:

```bash
./scanning/trivy.sh
```

The script runs:

```bash
trivy k8s kind-dev-cluster \
  --report summary \
  --severity HIGH,CRITICAL \
  --timeout 10m
```

Run Kubescape NSA framework scan:

```bash
./scanning/kubescape.sh
```

Run kube-bench:

```bash
./scanning/kube-bench.sh
```

## 9. CI/CD Security

The GitHub Actions workflow is defined in:

```text
.github/workflows/security-scan.yml
```

On every push, it runs:

- Trivy config scan for `HIGH` and `CRITICAL` findings
- Kubescape NSA framework scan

## 10. Documentation

Additional documentation:

- `docs/hardening-checklist.md`
- `docs/incident-response.md`
- `docs/cks-notes.md`
- `docs/architecture.md`

## Known Gaps

The following files are currently empty and should be completed or removed:

- `pod-security/baseline-namespace.yaml`
- `network-policies/allow-monitoring.yaml`
- `policies/kyverno/require-resources.yaml`
- `runtime/audit-policy.yaml`
- `runtime/falco-values.yaml`

Kyverno currently warns that lowercase `validationFailureAction` values are deprecated. Newer Kyverno versions prefer `Enforce` and `Audit`.
