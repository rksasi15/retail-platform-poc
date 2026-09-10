##############################################################################
# infra-modules/s3_backend
# Creates the buckets + lock table used by BOTH Terraform state and kOps:
#   - tf_state_bucket        : Terraform remote state
#   - tf_lock_table          : Terraform state locking (DynamoDB)
#   - kops_state_bucket      : kOps cluster state store (s3://...)
#   - oidc_discovery_bucket  : kOps IRSA OIDC discovery documents (public-read)
# Run this ONCE with a local backend (see infra-live/dev "make bootstrap"),
# then the env stack migrates its state into tf_state_bucket.
##############################################################################

resource "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket
  tags   = var.tags
}
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = var.tf_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = var.tags
}

resource "aws_s3_bucket" "kops_state" {
  bucket = var.kops_state_bucket
  tags   = var.tags
}
resource "aws_s3_bucket_versioning" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_public_access_block" "kops_state" {
  bucket                  = aws_s3_bucket.kops_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# OIDC discovery bucket MUST be publicly readable so AWS STS can fetch the
# JWKS/keys for IRSA. kOps writes discovery.json + keys.json here.
resource "aws_s3_bucket" "oidc" {
  bucket = var.oidc_discovery_bucket
  tags   = var.tags
}
resource "aws_s3_bucket_public_access_block" "oidc" {
  bucket                  = aws_s3_bucket.oidc.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_ownership_controls" "oidc" {
  bucket = aws_s3_bucket.oidc.id
  rule { object_ownership = "BucketOwnerPreferred" }
}
resource "aws_s3_bucket_policy" "oidc_public_read" {
  bucket = aws_s3_bucket.oidc.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowPublicRead",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.oidc.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.oidc]
}
