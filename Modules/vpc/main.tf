# modules/vpc/main.tf

# ============================================================
# 1. VPC
# ============================================================
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "sports-facility-booking-vpc"
  }
}

# ============================================================
# 2. Internet Gateway
# ============================================================
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "sports-facility-booking-igw"
  }
}

# ============================================================
# 3. 公有路由表 (Public Route Table)
# ============================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "sports-facility-booking-public-rt"
  }
}

# ============================================================
# 4. 公有子網路 (Public Subnets) — 2 個 AZ
# ============================================================
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "sports-facility-booking-public-${var.azs[count.index]}"
  }
}

# ============================================================
# 5. 公有路由表關聯 (Public Route Table Associations)
# ============================================================
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# 6. 私有子網路 (Private Subnets) — 2 個 AZ
# ============================================================
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "sports-facility-booking-private-${var.azs[count.index]}"
  }
}

# ============================================================
# 7. 私有路由表 (Private Route Tables) — 每個 AZ 各一個
# ============================================================
resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "sports-facility-booking-private-rt-${var.azs[count.index]}"
  }
}

# ============================================================
# 8. Elastic IPs for NAT Gateways
# ============================================================
resource "aws_eip" "nat" {
  count = 2

  domain = "vpc"

  tags = {
    Name = "sports-facility-booking-nat-eip-${var.azs[count.index]}"
  }
}

# ============================================================
# 9. NAT Gateways — 每個 AZ 一個 (Zonal)
# ============================================================
resource "aws_nat_gateway" "this" {
  count = 2

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "sports-facility-booking-nat-${var.azs[count.index]}"
  }

  depends_on = [aws_internet_gateway.this]
}

# ============================================================
# 10. 私有路由表 — 加入 NAT Gateway 路由
# ============================================================
resource "aws_route" "private_nat" {
  count = 2

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

# ============================================================
# 11. 私有路由表關聯 (Private Route Table Associations)
# ============================================================
resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ============================================================
# 12. S3 Gateway Endpoint (加分項目)
# ============================================================
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [aws_route_table.public.id]

  tags = {
    Name = "sports-facility-booking-s3-endpoint"
  }
}