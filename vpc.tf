resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"
}

module "vpc" {
  source              = "terraform-aws-modules/vpc/aws"
  version             = "5.1.0"
  name                = "${var.prefix}vpc"
  cidr                = "10.0.0.0/16"
  azs                 = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway  = true
  single_nat_gateway  = false
  enable_vpn_gateway  = false
  reuse_nat_ips       = true
  external_nat_ip_ids = aws_eip.nat.*.id
}