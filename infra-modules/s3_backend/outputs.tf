output "tf_state_bucket" { value = aws_s3_bucket.tf_state.id }
output "tf_lock_table" { value = aws_dynamodb_table.tf_lock.name }
output "kops_state_bucket" { value = aws_s3_bucket.kops_state.id }
output "kops_state_store" { value = "s3://${aws_s3_bucket.kops_state.id}" }
output "oidc_discovery_bucket" { value = aws_s3_bucket.oidc.id }
output "oidc_issuer_url" { value = "https://${aws_s3_bucket.oidc.id}.s3.${var.region}.amazonaws.com" }
