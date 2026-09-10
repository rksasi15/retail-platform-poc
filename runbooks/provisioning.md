# Runbook: Provisioning (dev, from zero)

Prereqs done: CLIs installed, `aws sts get-caller-identity` works, SSH key exists,
`ansible-galaxy collection install -r cluster-ops/requirements.yml` run.
No public domain -> PoC uses the private zone + self-signed TLS (already configured).

## 1. Bootstrap remote state (one time)
```bash
cd infra-live/dev
make bootstrap        # creates tfstate + lock + kops + oidc buckets (local backend)
```
If you changed bucket names, update backend.tf + terraform.tfvars to match.

## 2. Foundations (VPC/KMS/DNS/node-IAM)
```bash
make init
make plan
make apply
make output           # writes /tmp/tf-dev-outputs.json for Ansible
```

## 3. Cluster
```bash
cd ../../cluster-ops
# (skip install-tools.yml if you already brew-installed the CLIs)
ansible-playbook playbooks/cluster-create.yml
# ~10-15 min; ends with `kops validate cluster` green
```

## 4. IRSA roles (Phase 2 — needs the cluster's OIDC provider)
```bash
cd ../infra-live/dev
make apply-irsa
make output           # refresh outputs so IRSA ARNs are present
```

## 5. Add-ons (LBC, nginx, external-dns, cert-manager, ESO)
```bash
cd ../../cluster-ops
ansible-playbook playbooks/addons-bootstrap.yml
kubectl get pods -A | egrep 'ingress|cert-manager|external-dns|external-secrets|load-balancer'
kubectl get clusterissuer      # retail-ca-issuer (self-signed CA)
```

## 6. GitOps
Follow `gitops/README.md` (install ArgoCD, connect GitHub, apply root-app).

## Accessing the app without a domain
```bash
NLB=$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -H "Host: dev.retail.example.com" http://$NLB/            # ui
curl -H "Host: dev.retail.example.com" http://$NLB/cart        # path routing
# or:  kubectl -n retail-dev port-forward svc/ui 8080:80
```
