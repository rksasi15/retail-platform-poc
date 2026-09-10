# Consumed by Ansible (cluster-create/addons-bootstrap) via `terraform output -json`.
output "region" { value = var.region }
output "cluster_name" { value = var.cluster_name }
output "vpc_id" { value = module.vpc.vpc_id }
output "vpc_cidr" { value = module.vpc.vpc_cidr }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "private_subnets_by_az" { value = module.vpc.private_subnets_by_az }
output "public_subnets_by_az" { value = module.vpc.public_subnets_by_az }
output "kms_key_arn" { value = module.kms.key_arn }
output "private_zone_id" { value = module.dns.private_zone_id }
output "private_zone_name" { value = module.dns.private_zone_name }
output "private_zone_arn" { value = module.dns.private_zone_arn }
output "public_zone_id" { value = module.dns.public_zone_id }
output "public_zone_name" { value = module.dns.public_zone_name }
output "kops_state_store" { value = "s3://${var.kops_state_bucket}" }
output "oidc_discovery_store" { value = "s3://${var.oidc_discovery_bucket}" }
output "oidc_issuer_url" { value = local.oidc_issuer_url }

# IRSA role ARNs (null until create_irsa=true) — fed into Helm values for add-ons
output "irsa_external_dns_role_arn" { value = try(module.iam_irsa[0].external_dns_role_arn, null) }
output "irsa_cert_manager_role_arn" { value = try(module.iam_irsa[0].cert_manager_role_arn, null) }
output "irsa_autoscaler_role_arn" { value = try(module.iam_irsa[0].autoscaler_role_arn, null) }
output "irsa_lbc_role_arn" { value = try(module.iam_irsa[0].lbc_role_arn, null) }
output "irsa_external_secrets_role_arn" { value = try(module.iam_irsa[0].external_secrets_role_arn, null) }
output "irsa_argocd_repo_role_arn" { value = try(module.iam_irsa[0].argocd_repo_role_arn, null) }
