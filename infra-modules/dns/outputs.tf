output "private_zone_id" { value = aws_route53_zone.private.zone_id }
output "private_zone_name" { value = aws_route53_zone.private.name }
output "private_zone_arn" { value = aws_route53_zone.private.arn }
output "public_zone_id" { value = try(data.aws_route53_zone.public[0].zone_id, null) }
output "public_zone_name" { value = try(data.aws_route53_zone.public[0].name, null) }
output "public_zone_arn" { value = try(data.aws_route53_zone.public[0].arn, null) }
