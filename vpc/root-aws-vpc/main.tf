module "vpc" {
  source = "../module-aws-vpc"
  vpcs = var.vpcs
  spoke_subnets = var.spoke_subnets
}
