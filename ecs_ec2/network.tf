data "aws_availability_zones" "availabe" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${title(var.project_name)} VPC" })
}

resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.availabe.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${title(var.project_name)} Public Subnet" })
}

resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.availabe.names[count.index]
  vpc_id            = aws_vpc.main.id
  tags              = merge(local.tags, { Name = "${title(var.project_name)} Private Subnet" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${title(var.project_name)} Internet Gateway" })
}

resource "aws_route" "route" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = var.allow_all_cidr
  gateway_id             = aws_internet_gateway.main.id
}
