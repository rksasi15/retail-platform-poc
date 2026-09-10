# AWS Topology (dev) — reference

```
Region ap-south-1
VPC 10.20.0.0/16
  3 AZs (a/b/c)
    public  /20 per AZ  -> IGW route, NAT-GW (>=2), NLB (nginx), bastion
    private /20 per AZ  -> 3 masters (HA control plane) + workers (spot+on-demand)
                          egress via NAT
Route53
  private zone dev.retail.internal   (kOps DNS + external-dns manages records)
  (public zone: none in PoC -> self-signed TLS via cert-manager CA issuer)
KMS CMK  -> etcd volumes + secrets at rest
S3       -> terraform state | kops state | OIDC discovery (public-read)
DynamoDB -> terraform state lock
IAM      -> kOps node/master roles + IRSA roles:
            external-dns, cert-manager, cluster-autoscaler,
            aws-load-balancer-controller, external-secrets, argocd-repo-server
OIDC     -> created by kOps (enableAWSOIDCProvider) -> trusted by IRSA roles
```

Data flow: PR -> GitHub -> ArgoCD (App-of-Apps) -> Helm render -> kube-apiserver
-> Kyverno admission (no :latest, resources required, no privileged) -> workloads
-> nginx Ingress -> NLB (provisioned by AWS LBC). Prometheus scrapes; Grafana + SLO alert.
