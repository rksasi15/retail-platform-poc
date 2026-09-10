##############################################################################
# infra-modules/dns
# Private hosted zone (always created) for internal cluster names + external-dns.
# Public zone is OPTIONAL: pass public_zone_id="" for the no-domain PoC path.
##############################################################################
resource "aws_route53_zone" "private" {
  name = var.private_zone_name
  vpc { vpc_id = var.vpc_id }
  tags = merge(var.tags, { Name = var.private_zone_name })
}

data "aws_route53_zone" "public" {
  count   = var.public_zone_id == "" ? 0 : 1
  zone_id = var.public_zone_id
}
