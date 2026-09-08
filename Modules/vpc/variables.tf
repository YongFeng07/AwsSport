variable "vpc_cidr" {
  default = "172.16.0.0/16"
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "sports-facility-booking"
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.16.0.0/20", "172.16.16.0/20"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["172.16.128.0/20", "172.16.144.0/20"]
}