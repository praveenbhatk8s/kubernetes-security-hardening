# Lab Architecture

This lab models a compact DevSecOps path for Kubernetes: secure manifests enter the cluster through admission control, runtime activity is monitored by Falco, and scanners validate both repository configuration and live cluster state.

## High-Level View

```mermaid
flowchart TB
  subgraph Workstation["Developer Workstation"]
    Repo["kubernetes-security-hardening repo"]
    Kubectl["kubectl"]
    Helm["helm"]
    Scanners["Local scans<br/>Trivy, Kubescape, kube-bench"]
  end

  subgraph CICD["GitHub Actions"]
    Checkout["Checkout"]
    TrivyCI["Trivy config scan<br/>HIGH / CRITICAL fail"]
    KubescapeCI["Kubescape NSA scan"]
  end

  subgraph Cluster["kind-dev-cluster"]
    subgraph Admission["Admission Control"]
      PSS["Pod Security Standards<br/>baseline / restricted"]
      Kyverno["Kyverno<br/>non-root, no latest tags"]
      Gatekeeper["OPA Gatekeeper<br/>no privileged containers"]
    end

    subgraph Namespaces["Application Namespaces"]
      Dev["development<br/>baseline"]
      Prod["production<br/>restricted"]
      Restricted["restricted<br/>restricted"]
    end

    subgraph Controls["Cluster Security Controls"]
      RBAC["RBAC<br/>developer and readonly roles"]
      NetPol["NetworkPolicies<br/>default deny, allow nginx"]
      Falco["Falco DaemonSet<br/>runtime detection"]
    end

    subgraph Tests["Policy Test Pods"]
      Good["good pod<br/>non-root nginx on 8080"]
      Bad["bad pod<br/>latest tag + privileged"]
    end
  end

  Repo --> Checkout --> TrivyCI --> KubescapeCI
  Repo --> Kubectl
  Repo --> Helm
  Kubectl --> Admission
  Helm --> Kyverno
  Helm --> Falco
  Scanners --> Cluster
  Admission --> Namespaces
  PSS --> Dev
  PSS --> Prod
  PSS --> Restricted
  Kyverno --> Good
  Kyverno -. rejects .-> Bad
  Gatekeeper -. rejects .-> Bad
  RBAC --> Dev
  NetPol --> Dev
  Falco --> Tests
```

## Request Flow

```mermaid
sequenceDiagram
  participant Dev as Developer
  participant API as Kubernetes API Server
  participant PSS as Pod Security Standards
  participant K as Kyverno
  participant G as Gatekeeper
  participant Node as Worker Node
  participant F as Falco

  Dev->>API: kubectl apply -f test/good-pod.yaml
  API->>PSS: namespace security check
  API->>K: require non-root and block latest tag
  API->>G: block privileged containers
  G-->>API: allow
  K-->>API: allow
  PSS-->>API: allow
  API->>Node: schedule pod
  Node->>F: runtime activity visible
  F-->>Dev: events available in Falco logs

  Dev->>API: kubectl apply -f test/bad-pod.yaml
  API->>K: image tag check
  K-->>API: deny nginx:latest
  API-->>Dev: admission denied
```

## Components

| Area | Component | Purpose | Repo Path |
| --- | --- | --- | --- |
| Namespace security | Pod Security Standards | Enforce baseline or restricted behavior at namespace level | `namespaces/`, `pod-security/` |
| Access control | RBAC | Limit what users can do in `development` | `rbac/` |
| Traffic control | NetworkPolicy | Default-deny traffic and selectively allow nginx ingress | `network-policies/` |
| Admission control | Kyverno | Require non-root pods and block `latest` image tags | `policies/kyverno/` |
| Admission control | Gatekeeper | Block privileged containers | `policies/opa-gatekeeper/` |
| Runtime detection | Falco | Detect suspicious container activity on nodes | `runtime/` |
| Scanning | Trivy | Scan `kind-dev-cluster` for high and critical findings | `scanning/trivy.sh` |
| Scanning | Kubescape | Run NSA framework checks | `scanning/kubescape.sh` |
| Scanning | kube-bench | Run Kubernetes CIS-style checks | `scanning/kube-bench.sh` |
| CI/CD | GitHub Actions | Scan config on push | `.github/workflows/security-scan.yml` |
| Validation | Good and bad pods | Prove policy allow and deny behavior | `test/` |

## Security Layers

1. **Pre-merge checks:** GitHub Actions scans manifests with Trivy and Kubescape.
2. **Namespace guardrails:** Pod Security labels enforce baseline or restricted profiles.
3. **Admission policies:** Kyverno and Gatekeeper reject unsafe pod specs before scheduling.
4. **Least privilege:** RBAC limits user actions in the `development` namespace.
5. **Traffic isolation:** NetworkPolicies apply default-deny behavior.
6. **Runtime visibility:** Falco watches running workloads for suspicious activity.
7. **Cluster assessment:** Trivy, Kubescape, and kube-bench provide manual validation.

## Expected Test Behavior

`test/good-pod.yaml` should be admitted and run:

```bash
kubectl apply -f test/good-pod.yaml
kubectl get pod good
```

Expected status:

```text
good   1/1   Running
```

`test/bad-pod.yaml` should be denied because it uses `nginx:latest` and `privileged: true`:

```bash
kubectl apply -f test/bad-pod.yaml
```

Expected result:

```text
admission denied
```

## Current Known Gaps

These files are placeholders and should be completed before presenting the lab as fully production-like:

- `pod-security/baseline-namespace.yaml`
- `network-policies/allow-monitoring.yaml`
- `policies/kyverno/require-resources.yaml`
- `runtime/audit-policy.yaml`
- `runtime/falco-values.yaml`
