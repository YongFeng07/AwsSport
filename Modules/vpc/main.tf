resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "sports-facility-booking-vpc"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "172.16.0.0/20"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "sports-facility-booking-subnet-public1-us-east-1a"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "172.16.16.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "sports-facility-booking-subnet-public2-us-east-1b"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "172.16.128.0/20"
  availability_zone = "us-east-1a"

  tags = {
    Name = "sports-facility-booking-subnet-private1-us-east-1a"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "172.16.144.0/20"
  availability_zone = "us-east-1b"

  tags = {
    Name = "sports-facility-booking-subnet-private2-us-east-1b"
  }
}