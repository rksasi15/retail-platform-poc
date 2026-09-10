##############################################################################
# infra-live/dev — foundations stack (Phase 1) + IRSA (Phase 2, create_irsa=true)
##############################################################################
locals {
  oidc_issuer_url = "https://${var.oidc_discovery_bucket}.s3.${var.region}.amazonaws.com"
}

module "vpc" {
  source            = "../../infra-modules/vpc"
  name              = var.name_prefix
  cluster_name      = var.cluster_name
  cidr              = var.vpc_cidr
  azs               = var.azs
  nat_gateway_count = var.nat_gateway_count
}

module "kms" {
  source = "../../infra-modules/kms"
  name   = "${var.name_prefix}-cmk"
}

module "dns" {
  source            = "../../infra-modules/dns"
  private_zone_name = var.private_zone_name
  vpc_id            = module.vpc.vpc_id
  public_zone_id    = var.public_zone_id
}

# ---- Phase 2: IRSA roles (only after cluster exists) ----
module "iam_irsa" {
  source            = "../../infra-modules/iam_irsa"
  count             = var.create_irsa ? 1 : 0
  name              = var.name_prefix
  region            = var.region
  oidc_issuer_url   = local.oidc_issuer_url
  route53_zone_arns = compact([module.dns.private_zone_arn, module.dns.public_zone_arn])
  kms_key_arn       = module.kms.key_arn
}
