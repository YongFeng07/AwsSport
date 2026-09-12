# modules/vpc/variables.tf

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "sports-facility-booking"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "Availability Zones (2 AZs for high availability)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (2 subnets)"
  type        = list(string)
  default     = ["172.16.0.0/20", "172.16.16.0/20"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (2 subnets)"
  type        = list(string)
  default     = ["172.16.128.0/20", "172.16.144.0/20"]
}