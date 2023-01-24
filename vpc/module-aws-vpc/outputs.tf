output "vpcs" {
  value = {
    for vpck, vpc in aws_vpc.main : vpc.tags.Name => {
      description = "outputs for ${vpck} VPC"
      cidr        = vpc.cidr_block
      id          = vpc.id
      route       = vpc.main_route_table_id
      owner       = vpc.owner_id
      tags        = vpc.tags
    }
  }
}

output "hub_id" {
  value = element([for vpck, vpc in aws_vpc.main : vpc.id if vpc.tags.type == "hub"], 0)
}

output "hub_cidr" {
  value = element([for vpck, vpc in aws_vpc.main : vpc.cidr_block if vpc.tags.type == "hub"], 0)
}

output "vpc_peering" {
  value = {
    for peerk, peer in aws_vpc_peering_connection.main : peerk => {
      description = "connects ${aws_vpc.main[peerk].tags.Name} to hub VPC"
      id          = peer.id
    }
  }
}

output "igw" {
  value = {
    "${aws_internet_gateway.hub.tags.Name}" = aws_internet_gateway.hub.id
  }
}

output "hub_subnets" {
  value = merge({
    trusted = {
      id   = aws_subnet.hub_trusted.id
      cidr = aws_subnet.hub_trusted.cidr_block
    }
    },
    {
      untrusted = {
        id   = aws_subnet.hub_untrusted.id
        cidr = aws_subnet.hub_untrusted.cidr_block
      }
  })
}
