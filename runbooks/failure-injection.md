# Runbook: Failure Injection (Part 7)

## Failure 1 — Misconfigured Ingress -> drift -> fix via Git
Inject: hand-edit the live ingress so it drifts from Git.
```bash
kubectl -n retail-dev patch ingress ui --type=json \
  -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port/number","value":9999}]'
```
Detect: ArgoCD marks `ui-dev` **OutOfSync**; with selfHeal it reverts automatically.
```bash
argocd app get ui-dev            # shows OutOfSync + the diff
argocd app diff ui-dev
```
Fix (the correct GitOps way — don't kubectl edit back):
- If selfHeal is on, ArgoCD already reverted. To prove the Git-driven path,
  temporarily disable selfHeal, observe drift, then `argocd app sync ui-dev`.
Evidence: screenshot the OutOfSync tree + the sync that restores port 80.

## Failure 2 — Memory pressure -> evictions/HPA -> fix via Git
Inject: drop the memory limit far below need in Git and push.
```bash
# in apps/retail-service/values-ui-dev.yaml
#   resources.limits.memory: 16Mi
git commit -am "inject: starve ui memory" && git push
```
Observe:
```bash
kubectl -n retail-dev get pods -w        # OOMKilled / CrashLoopBackOff / Evicted
kubectl -n retail-dev describe pod -l app.kubernetes.io/name=ui | grep -A3 Events
kubectl -n retail-dev get hpa ui         # replica churn under pressure
```
Fix via Git: revert the limit, push, ArgoCD auto-syncs, pods stabilise.
Evidence: `kubectl get events`, HPA output before/after, ArgoCD sync history.
