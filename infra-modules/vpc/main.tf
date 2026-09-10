##############################################################################
# infra-modules/vpc
# One VPC, 3 AZs, public + private subnets, IGW, >=2 NAT GWs, route tables.
# Subnets are tagged so kOps can consume this as a SHARED VPC and so the
# AWS Load Balancer Controller auto-discovers subnets.
##############################################################################

locals {
  # kOps + LBC subnet discovery tags. cluster_name is the kOps cluster FQDN.
  cluster_tag = { "kubernetes.io/cluster/${var.cluster_name}" = "shared" }
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, local.cluster_tag, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

############################# Public subnets ################################
resource "aws_subnet" "public" {
  for_each                = { for i, az in var.azs : az => i }
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.cidr, 4, each.value) # /20 blocks 0,1,2
  map_public_ip_on_launch = true
  tags = merge(var.tags, local.cluster_tag, {
    Name                     = "${var.name}-public-${each.key}"
    "kubernetes.io/role/elb" = "1" # public ALB/NLB placement
    "SubnetType"             = "Public"
  })
}

############################# Private subnets ###############################
resource "aws_subnet" "private" {
  for_each          = { for i, az in var.azs : az => i }
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.cidr, 4, each.value + 4) # /20 blocks 4,5,6
  tags = merge(var.tags, local.cluster_tag, {
    Name                              = "${var.name}-private-${each.key}"
    "kubernetes.io/role/internal-elb" = "1" # internal LB placement
    "SubnetType"                      = "Private"
  })
}

############################# NAT gateways ##################################
# >=2 NAT GWs for HA egress. In dev you may set nat_gateway_count=1 to save cost;
# leave at 2+ to match the assignment.
resource "aws_eip" "nat" {
  count  = var.nat_gateway_count
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.azs[count.index]].id
  tags          = merge(var.tags, { Name = "${var.name}-nat-${count.index}" })
  depends_on    = [aws_internet_gateway.this]
}

############################# Route tables ##################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-rt-public" })
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# One private RT per AZ, each pointing at the nearest NAT (round-robin if fewer NATs).
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id
  tags     = merge(var.tags, { Name = "${var.name}-rt-private-${each.key}" })
}

resource "aws_route" "private_nat" {
  for_each               = aws_subnet.private
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[index(var.azs, each.key) % var.nat_gateway_count].id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
