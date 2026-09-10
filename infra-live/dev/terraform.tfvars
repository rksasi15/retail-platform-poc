region            = "ap-south-1"
cluster_name      = "dev.retail.internal"
public_zone_id    = "" # no public domain — PoC uses private zone + self-signed TLS
private_zone_name = "dev.retail.internal"

tf_state_bucket       = "retail-poc-tfstate-dev-125788629837"
tf_lock_table         = "retail-poc-tflock-dev"
kops_state_bucket     = "retail-poc-kops-dev-125788629837"
oidc_discovery_bucket = "retail-poc-oidc-dev-125788629837"

create_irsa = false
