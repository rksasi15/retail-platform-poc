##############################################################################
# infra-modules/kms
# Customer-managed CMK used for: kOps etcd/secrets encryption + app secrets (ESO/SealedSecrets).
##############################################################################
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "this" {
  description             = "${var.name} secrets/etcd encryption CMK"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  multi_region            = false
  policy                  = data.aws_iam_policy_document.key.json
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

data "aws_iam_policy_document" "key" {
  statement {
    sid       = "RootAccountAdmin"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  # kOps master/node roles are added post-cluster via a grant in the IRSA phase,
  # or you can add their ARNs to var.additional_key_admins here.
  dynamic "statement" {
    for_each = length(var.additional_key_users) > 0 ? [1] : []
    content {
      sid       = "AllowUse"
      effect    = "Allow"
      actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = var.additional_key_users
      }
    }
  }
}
