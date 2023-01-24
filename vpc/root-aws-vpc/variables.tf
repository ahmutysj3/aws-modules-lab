variable "region_aws" {
  description = "aws region"
  type        = string
  default     = "us-east-1"
}

variable "vpcs" {
  description = "builds the hub/spoke VPCs"
  type = map(object({
    cidr = string
    type = string
  }))
}

variable "spoke_subnets" {
  description = "used to build firewall subnets"
  type = map(object({
    private = bool
    vpc_id  = string
    cidr    = string
    mgmt    = bool
  }))
}

