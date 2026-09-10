# Retail Store Platform — DevOps PoC (DEV environment)

End-to-end GitOps platform: **Terraform** (AWS foundations) → **kOps + Ansible**
(HA Kubernetes) → **Helm** (retail-store microservices) → **ArgoCD** (App-of-Apps)
→ **Prometheus/Grafana** (SLOs) → **failure injection**.

This scaffold is scoped to the **dev** environment. `stage`/`prod` reuse the exact
same modules/charts with different `*.tfvars`, `values-<env>.yaml`, and ArgoCD
overlays — the deltas are called out inline and in `runbooks/promotion.md`.

> Region: `ap-south-1` · k8s: `1.30.x` (pinned, see Part 2) · state: S3+DynamoDB

---

## Repo layout (each is a *separate* git repo in real life; kept in one tree here)

```
infra-modules/   Reusable Terraform modules (vpc, dns, kms, s3_backend, iam_irsa)
infra-live/dev/  Env stack that pins & wires the modules + Makefile
cluster-ops/     Ansible: install CLIs, kOps lifecycle, add-on bootstrap
apps/            Helm: platform chart + generic retail-service chart + per-svc values
gitops/          ArgoCD root App-of-Apps, AppProjects (RBAC), notifications, Kyverno
runbooks/        provisioning / promotion / upgrade / rollback / failure playbooks
```

Why one generic `retail-service` chart instead of 6 near-identical charts:
the retail-store services differ only in image, port, env, and data dependency.
A single parameterised chart + per-service values is the DRY, senior pattern and
still gives every service its own HPA/PDB/probes/ingress. See `apps/README.md`.

---

## AWS topology (dev)

```
                                 Route53: dev.retail.internal (private) + public zone for ACME
                                          |
                        +-----------------+------------------+
                        |            VPC 10.20.0.0/16        |
                        |                                    |
     AZ ap-south-1a     |   AZ ap-south-1b   |   AZ ap-south-1c
  +------------------+   +------------------+   +------------------+
  | public  .0.0/20  |   | public  .16.0/20 |   | public  .32.0/20 |   <- ALB/NLB, NAT GW, bastion
  |  NAT-GW-a        |   |  NAT-GW-b        |   |  (NAT optional)  |
  +--------+---------+   +--------+---------+   +--------+---------+
           |                      |                      |
  +--------+---------+   +--------+---------+   +--------+---------+
  | private .64.0/20 |   | private .80.0/20 |   | private .96.0/20 |   <- masters(3) + workers(spot+od)
  +------------------+   +------------------+   +------------------+
           |                      |                      |
        (IGW on public, NAT egress from private)  KMS CMK -> etcd/secrets encryption
        S3: TF state + kOps state + OIDC discovery   DynamoDB: TF lock
        IAM: node roles + IRSA roles (external-dns, cert-manager, autoscaler, LBC, argocd)
```

Full-res diagram source in `runbooks/architecture.md`.

---

## Execution order (the ONLY correct sequence)

There is a real ordering constraint: kOps creates the OIDC provider, and IRSA
roles must trust that provider. So foundations and IRSA are two Terraform phases
around the cluster build. The Makefiles/playbooks encode this — do not reorder.

```
0. Prereqs         # tools, AWS creds, domains  (see below)
1. TF bootstrap    # create S3 state bucket + DynamoDB lock  (local backend, one-time)
                   #   cd infra-live/dev && make bootstrap
2. TF foundations  # VPC, subnets, Route53, KMS, kOps-state bucket, OIDC bucket, node IAM
                   #   make init && make plan && make apply
3. Ansible tools   # install kops/kubectl/helm/argocd CLIs
                   #   cd cluster-ops && ansible-playbook playbooks/install-tools.yml
4. Ansible cluster # template kOps manifest from TF outputs, kops create/update/validate
                   #   ansible-playbook playbooks/cluster-create.yml
5. TF IRSA         # now the OIDC provider exists -> create IRSA roles
                   #   cd infra-live/dev && make apply-irsa
6. Ansible add-ons # autoscaler, metrics-server, nginx+LBC, external-dns, cert-manager, ESO
                   #   ansible-playbook playbooks/addons-bootstrap.yml
7. ArgoCD          # install argocd, apply root App-of-Apps, projects, notifications, policies
                   #   see gitops/README.md
8. GitOps flow     # PR -> auto-sync dev  (Part 5)
9. Observability   # kube-prometheus-stack + SLO alert  (Part 6, deployed via ArgoCD)
10. Failure inject # runbooks/failure-injection.md  (Part 7)
```

Teardown is the reverse: `cluster-destroy.yml` → `make destroy` → `make destroy-bootstrap`.

---

## 0. Prerequisites

| Tool      | Pinned version (dev) | Notes                                  |
|-----------|----------------------|----------------------------------------|
| terraform | >= 1.7, < 2.0        | uses S3 backend w/ native lockfile too |
| kops      | 1.30.x               | must match k8s minor line              |
| kubectl   | 1.30.x               |                                        |
| helm      | 3.14+                |                                        |
| argocd    | 2.11+                | CLI, matches server                    |
| ansible   | 2.16+                | community.general, kubernetes.core     |
| aws cli   | v2                   | profile with admin for PoC             |

```bash
export AWS_PROFILE=retail-poc
export AWS_REGION=ap-south-1
aws sts get-caller-identity     # sanity check
```

This PoC runs **without a public domain**: `external-dns` manages the private
Route53 zone Terraform creates (`dev.retail.internal`), and `cert-manager` issues
TLS from a **self-signed CA** instead of Let's Encrypt. Everything else is
identical to a real setup — to go real later, set a `public_zone_id` in
`terraform.tfvars` and flip `tls_mode: acme` in `cluster-ops/group_vars/dev.yml`.

GitOps repo host: **GitHub** — push this whole tree to one repo and replace the
`CHANGE-ME/retail-platform-poc` placeholder (see `gitops/README.md`).

Start at `runbooks/provisioning.md` for the click-by-click walkthrough.
