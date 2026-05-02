# Kubernetes Security Hardening Lab

This project demonstrates Kubernetes security best practices:

- Namespaces with Pod Security Standards
- RBAC (least privilege)
- Network Policies (default deny)
- Kyverno policies (runtime enforcement)
- Security scanning (Trivy, Kubescape)

## 🚀 Run on kind

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace
kubectl apply -f namespaces/
kubectl apply -f rbac/
kubectl apply -f network-policies/
kubectl apply -f pod-security/
kubectl apply -f policies/kyverno/

## create a bad-pod
apiVersion: v1
kind: Pod
metadata:
  name: bad-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest

kubectl apply -f bad-pod.yaml

## create a good-pod
apiVersion: v1
kind: Pod
metadata:
  name: good-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    securityContext:
      runAsNonRoot: true

kubectl apply -f good-pod.yaml

## Run scans
./scanning/trivy.sh
./scanning/kubescape.sh