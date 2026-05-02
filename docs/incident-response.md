# Kubernetes Incident Response Runbook

This runbook is for the `kind-dev-cluster` security hardening lab.

## 1. Confirm Scope

Check the active context before running response commands:

```bash
kubectl config current-context
kubectl get ns
kubectl get pods -A
```

For this lab, the expected context is `kind-dev-cluster`.

## 2. Triage Suspicious Pods

List pods and identify failed, privileged, or unexpected workloads:

```bash
kubectl get pods -A -o wide
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
```

Useful examples from this repo:

- `test/good-pod.yaml` should run as non-root and use `nginxinc/nginx-unprivileged:1.25`.
- `test/bad-pod.yaml` is intentionally unsafe and should be denied because it uses `nginx:latest` and `privileged: true`.

## 3. Check Admission Controls

Verify Kyverno policies:

```bash
kubectl get clusterpolicy
kubectl describe clusterpolicy require-nonroot
kubectl describe clusterpolicy block-latest-tag
```

Verify Gatekeeper constraints:

```bash
kubectl get constrainttemplates
kubectl get k8sblockprivileged.constraints.gatekeeper.sh
kubectl describe k8sblockprivileged no-privileged
```

Expected controls:

- Pods must set `securityContext.runAsNonRoot: true`.
- Images using `:latest` should be blocked.
- Privileged containers should be blocked.

## 4. Check Runtime Detection

Falco should be installed in the `falco` namespace:

```bash
helm status falco -n falco
kubectl get pods -n falco
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100
```

Use Falco logs to look for unexpected shell access, sensitive file reads, privilege escalation, or suspicious process activity.

## 5. Contain the Workload

If a pod is suspicious, isolate or remove it:

```bash
kubectl delete pod <pod> -n <namespace>
kubectl scale deployment <deployment> -n <namespace> --replicas=0
```

For network containment in `development`, ensure the default-deny policy is present:

```bash
kubectl get networkpolicy -n development
kubectl describe networkpolicy default-deny -n development
```

## 6. Preserve Evidence

Before deleting resources in a real incident, capture state:

```bash
kubectl get pod <pod> -n <namespace> -o yaml > pod-evidence.yaml
kubectl describe pod <pod> -n <namespace> > pod-describe.txt
kubectl logs <pod> -n <namespace> > pod-current.log
kubectl logs <pod> -n <namespace> --previous > pod-previous.log
kubectl get events -n <namespace> --sort-by=.lastTimestamp > events.txt
```

For this lab, avoid committing evidence files unless they are intentionally sanitized examples.

## 7. Scan the Cluster

Run the bundled scanners:

```bash
./scanning/trivy.sh
./scanning/kubescape.sh
./scanning/kube-bench.sh
```

`trivy.sh` currently scans the `kind-dev-cluster` Kubernetes context and reports `HIGH` and `CRITICAL` findings.

## 8. Recover and Harden

After containment:

- Replace unsafe images with pinned, non-root images.
- Add `runAsNonRoot`, `runAsUser`, `allowPrivilegeEscalation: false`, and dropped capabilities.
- Avoid privileged containers.
- Avoid `latest` tags.
- Re-apply policies:

```bash
kubectl apply -f namespaces/
kubectl apply -f rbac/
kubectl apply -f network-policies/
kubectl apply -R -f policies/
```

## Current Documentation Gaps

The following files are empty and should be completed before using this repo as a full incident response demo:

- `runtime/audit-policy.yaml`
- `runtime/falco-values.yaml`
- `policies/kyverno/require-resources.yaml`
- `network-policies/allow-monitoring.yaml`
