# gitops/ — ArgoCD App-of-Apps (GitHub)

Step 7 of the top-level runbook. Assumes the cluster + add-ons are up.

## 0. Push this tree to GitHub

Create a repo (e.g. `retail-platform-poc`) and push. Then replace the placeholder
repo URL everywhere:

```bash
# from the repo root
GH="https://github.com/<your-user>/retail-platform-poc.git"
grep -rl "CHANGE-ME/retail-platform-poc" gitops | xargs sed -i '' "s#https://github.com/rksasi15/retail-platform-poc.git#$GH#g"   # macOS sed
git add -A && git commit -m "wire gitops repo url" && git push
```

## 1. Install ArgoCD (Helm)

```bash
helm repo add argo https://argoproj.github.io/argo-helm && helm repo update
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace \
  -f gitops/install/argocd-values.yaml --wait

# initial admin password
argocd admin initial-password -n argocd
# access (PoC): port-forward, or expose via nginx ingress
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
argocd login localhost:8080 --username admin --insecure
```

## 2. Connect the private GitHub repo (PAT)

Create a GitHub **fine-grained PAT** with *Contents: read* on the repo, then:

```bash
argocd repo add https://github.com/<your-user>/retail-platform-poc.git \
  --username <your-user> --password <PAT>
```

(Public repo? You can skip this — ArgoCD reads it anonymously.)

## 3. Apply projects, notifications, then the root app

```bash
kubectl apply -f gitops/projects/dev-project.yaml
kubectl apply -f gitops/projects/ops-project.yaml
kubectl apply -f gitops/notifications/argocd-notifications-cm.yaml
kubectl -n argocd create secret generic argocd-notifications-secret \
  --from-literal=slack-token=xoxb-your-token          # optional (Slack)

kubectl apply -f gitops/root-app.yaml                 # App-of-Apps takes over
```

`root-dev` now renders every child in `gitops/apps/dev/`:

| Wave | App | Sync |
|------|-----|------|
| -1 | kube-prometheus-stack | auto |
| 0  | platform, kyverno | auto |
| 1  | kyverno-policies, ui/catalog/cart/orders/checkout | auto |
| 2  | slo-rules | auto |

**dev = auto-sync** (prune + selfHeal). **stage/prod** overlays flip
`syncPolicy.automated` off → manual sync, gated by the `ops` AppProject so only
`team-ops` can promote (Part 4 RBAC).

## 4. Verify

```bash
argocd app list
argocd app get root-dev
kubectl -n retail-dev get pods,hpa,ingress
kubectl get clusterpolicy          # kyverno guardrails Enforce-ing
```

## Promotion to stage/prod

See `runbooks/promotion.md` — copy `apps/dev/` → `apps/stage/`, point at
`values-<svc>-stage.yaml`, set `project: ops`, remove `automated:`, and pin the
image **digest** promoted from dev (proves same artifact across envs).
