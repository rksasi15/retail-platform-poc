# Runbook: Promotion dev -> stage -> prod (Part 5)

GitOps rule: nothing is promoted by hand on the cluster — only via Git PRs.

## 1. Bump image in dev (auto-syncs)
Edit `apps/retail-service/values-ui-dev.yaml`, change image tag/digest, open a PR.
Merge -> `root-dev` auto-syncs -> ArgoCD rolls the new ReplicaSet.

## 2. Capture the exact digest deployed in dev
```bash
kubectl -n retail-dev get deploy ui -o jsonpath='{.spec.template.spec.containers[0].image}'
# or the resolved digest:
kubectl -n retail-dev get pod -l app.kubernetes.io/name=ui \
  -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
```

## 3. Promote to stage (manual approval)
- Copy `gitops/apps/dev/10-ui.yaml` -> `gitops/apps/stage/10-ui.yaml`
  - `project: ops`, namespace `retail-stage`, valueFiles `values-ui-stage.yaml`
  - REMOVE `syncPolicy.automated` (manual sync)
- In `values-ui-stage.yaml` set `image.digest` to the digest from step 2, `tag: ""`.
- PR + merge. Then a `team-ops` member approves the sync:
```bash
argocd app sync ui-stage            # only team-ops is allowed by the 'ops' AppProject
argocd app wait ui-stage --health
```

## 4. Promote to prod after stage is healthy
Same as step 3 into `apps/prod/` with `values-ui-prod.yaml`, **same digest**.

## 5. Prove same digest across envs
```bash
for ns in retail-dev retail-stage retail-prod; do
  echo -n "$ns: "; kubectl -n $ns get pod -l app.kubernetes.io/name=ui \
    -o jsonpath='{.items[0].status.containerStatuses[0].imageID}{"\n"}'
done
# all three must show the identical sha256 digest -> no mutable-tag drift
```
