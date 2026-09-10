output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr" { value = aws_vpc.this.cidr_block }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
output "public_subnets_by_az" { value = { for az, s in aws_subnet.public : az => s.id } }
output "private_subnets_by_az" { value = { for az, s in aws_subnet.private : az => s.id } }
output "nat_gateway_ids" { value = aws_nat_gateway.this[*].id }
