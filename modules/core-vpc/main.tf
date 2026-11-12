# VPC, subnets, IGW, NAT gtwys, Route tables, and security groups

# VPC $ IGW
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Subnets, 3 tiers across 2 AZs (public, private, private-db)
resource "aws_subnet" "public" {
    count                   = length(var.public_subnet_cidrs)
    vpc_id                  = aws_vpc.main.id
    cidr_block              = var.public_subnet_cidrs[count.index]
    availability_zone       = var.azs[count.index]
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.project_name}-public-${count.index + 1}"
    }
 }

resource "aws_subnet" "private" {
    count                   = length(var.private_subnet_cidrs)
    vpc_id                  = aws_vpc.main.id
    cidr_block              = var.private_subnet_cidrs[count.index]
    availability_zone       = var.azs[count.index]
    map_public_ip_on_launch = false
    tags = {
        Name = "${var.project_name}-private-app-${var.azs[count.index]}"
        Tier = "Application"
    }
}

resource "aws_subnet" "private_db" {
    count                   = length(var.private_db_subnet_cidrs)
    vpc_id                  = aws_vpc.main.id
    cidr_block              = var.private_db_subnet_cidrs[count.index]
    availability_zone       = var.azs[count.index]
    map_public_ip_on_launch = false
    tags = {
        Name = "${var.project_name}-private-db-${var.azs[count.index]}"
        Tier = "Database"
    }
}

# NAT Gateway(s) and EIPs
locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_count
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}"
  }
  depends_on = [aws_internet_gateway.main]
}

# Route Tables and Associations
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count         = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  count = var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main[0].id
  }
  tags = {
    Name = "${var.project_name}-private-app-rt${count.index + 1}"
  }
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_app[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-private-db-rt"
  }
}

resource "aws_route_table_association" "private_db" {
  count          = length(var.private_db_subnet_cidrs)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}