# Runbook: Upgrade & Rollback

## Cluster upgrade (kOps rolling)
```bash
# 1. bump k8s_version in cluster-ops/group_vars/dev.yml
# 2. dry run + apply + rolling update (drains one node at a time, validates between)
cd cluster-ops
ansible-playbook playbooks/cluster-upgrade.yml
```
Rollback: set the previous k8s_version back and re-run; kops rolls nodes to the
prior version. etcd is backed up (backupRetentionDays: 7) if you need restore.

## App rollback (GitOps)
Everything is Git, so rollback = revert the commit.
```bash
git revert <bad-commit> && git push        # ArgoCD auto-syncs dev back
# or, immediate, then reconcile Git:
argocd app rollback ui-dev <history-id>
argocd app history ui-dev
```

## Add-on rollback
```bash
helm history <release> -n <ns>
helm rollback <release> <revision> -n <ns>
```
