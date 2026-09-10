# Builds an IRSA assume-role-policy scoped to one namespace:serviceaccount.
variable "oidc_arn" { type = string }
variable "oidc_host" { type = string }
variable "namespace" { type = string }
variable "serviceaccount" { type = string }

data "aws_iam_policy_document" "this" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.serviceaccount}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}
output "policy_json" { value = data.aws_iam_policy_document.this.json }
