output "oidc_provider_arn" { value = data.aws_iam_openid_connect_provider.this.arn }
output "external_dns_role_arn" { value = aws_iam_role.external_dns.arn }
output "cert_manager_role_arn" { value = aws_iam_role.cert_manager.arn }
output "autoscaler_role_arn" { value = aws_iam_role.autoscaler.arn }
output "lbc_role_arn" { value = aws_iam_role.lbc.arn }
output "external_secrets_role_arn" { value = aws_iam_role.ext_secrets.arn }
output "argocd_repo_role_arn" { value = aws_iam_role.argocd_repo.arn }
