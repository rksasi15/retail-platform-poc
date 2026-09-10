##############################################################################
# infra-modules/iam_irsa
# APPLIED AFTER the cluster exists (kOps has published the OIDC discovery docs).
# Creates the IAM OIDC provider + one IRSA role per platform add-on, each trust
# policy scoped to a specific namespace/serviceaccount (least privilege).
##############################################################################

data "aws_caller_identity" "current" {}

# kOps creates the IAM OIDC provider during `kops update cluster --yes`
# (spec.iam.serviceAccountIssuerDiscovery.enableAWSOIDCProvider: true).
# We look it up here — this is why iam_irsa is a PHASE-2 apply (after the cluster).
data "aws_iam_openid_connect_provider" "this" {
  url = var.oidc_issuer_url
}

locals {
  oidc_arn  = data.aws_iam_openid_connect_provider.this.arn
  oidc_host = replace(var.oidc_issuer_url, "https://", "")
}

# Reusable assume-role policy builder for a given namespace:serviceaccount.
module "trust" {
  source   = "./trust"
  for_each = local.sa_bindings

  oidc_arn       = local.oidc_arn
  oidc_host      = local.oidc_host
  namespace      = each.value.namespace
  serviceaccount = each.value.sa
}

locals {
  # namespace/SA each add-on runs as (matches Helm chart defaults in cluster-ops)
  sa_bindings = {
    external_dns = { namespace = "kube-system", sa = "external-dns" }
    cert_manager = { namespace = "cert-manager", sa = "cert-manager" }
    autoscaler   = { namespace = "kube-system", sa = "cluster-autoscaler" }
    lbc          = { namespace = "kube-system", sa = "aws-load-balancer-controller" }
    ext_secrets  = { namespace = "external-secrets", sa = "external-secrets" }
    argocd_repo  = { namespace = "argocd", sa = "argocd-repo-server" }
  }
}

############################## Roles + policies ##############################

# external-dns: manage records in the PUBLIC zone only
resource "aws_iam_role" "external_dns" {
  name               = "${var.name}-external-dns"
  assume_role_policy = module.trust["external_dns"].policy_json
  tags               = var.tags
}
resource "aws_iam_role_policy" "external_dns" {
  role = aws_iam_role.external_dns.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["route53:ChangeResourceRecordSets"], Resource = var.route53_zone_arns },
      { Effect = "Allow", Action = ["route53:ListHostedZones", "route53:ListResourceRecordSets", "route53:ListTagsForResources"], Resource = ["*"] }
    ]
  })
}

# cert-manager: DNS-01 solver on the public zone
resource "aws_iam_role" "cert_manager" {
  name               = "${var.name}-cert-manager"
  assume_role_policy = module.trust["cert_manager"].policy_json
  tags               = var.tags
}
resource "aws_iam_role_policy" "cert_manager" {
  role = aws_iam_role.cert_manager.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["route53:GetChange"], Resource = ["arn:aws:route53:::change/*"] },
      { Effect = "Allow", Action = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets"], Resource = length(var.route53_zone_arns) > 0 ? var.route53_zone_arns : ["*"] },
      { Effect = "Allow", Action = ["route53:ListHostedZonesByName"], Resource = ["*"] }
    ]
  })
}

# cluster-autoscaler
resource "aws_iam_role" "autoscaler" {
  name               = "${var.name}-cluster-autoscaler"
  assume_role_policy = module.trust["autoscaler"].policy_json
  tags               = var.tags
}
resource "aws_iam_role_policy" "autoscaler" {
  role = aws_iam_role.autoscaler.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "autoscaling:DescribeAutoScalingGroups", "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations", "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags", "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions", "ec2:DescribeInstanceTypes", "ec2:DescribeImages",
        "eks:DescribeNodegroup"
      ],
      Resource = ["*"]
    }]
  })
}

# AWS Load Balancer Controller (uses the official IAM policy JSON, fetched by cluster-ops)
resource "aws_iam_role" "lbc" {
  name               = "${var.name}-aws-lbc"
  assume_role_policy = module.trust["lbc"].policy_json
  tags               = var.tags
}
resource "aws_iam_policy" "lbc" {
  name   = "${var.name}-aws-lbc"
  policy = file("${path.module}/policies/lbc-iam-policy.json")
}
resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

# External Secrets Operator: read app secrets from SSM/Secrets Manager, decrypt with CMK
resource "aws_iam_role" "ext_secrets" {
  name               = "${var.name}-external-secrets"
  assume_role_policy = module.trust["ext_secrets"].policy_json
  tags               = var.tags
}
resource "aws_iam_role_policy" "ext_secrets" {
  role = aws_iam_role.ext_secrets.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"], Resource = ["arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.name}/*"] },
      { Effect = "Allow", Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"], Resource = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.name}/*"] },
      { Effect = "Allow", Action = ["kms:Decrypt"], Resource = [var.kms_key_arn] }
    ]
  })
}

# ArgoCD repo-server (e.g. to pull from CodeCommit or assume cross-account for Helm OCI in ECR)
resource "aws_iam_role" "argocd_repo" {
  name               = "${var.name}-argocd-repo-server"
  assume_role_policy = module.trust["argocd_repo"].policy_json
  tags               = var.tags
}
resource "aws_iam_role_policy" "argocd_repo" {
  role = aws_iam_role.argocd_repo.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"], Resource = ["*"] }
    ]
  })
}
