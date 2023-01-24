resource "aws_vpc" "main" {
  for_each         = var.vpcs
  cidr_block       = each.value.cidr
  instance_tenancy = "default"

  tags = {
    Name = "${each.key}_vpc"
    type = each.value.type
  }
}

locals {
  hub_id   = element([for vpck, vpc in aws_vpc.main : vpc.id if vpc.tags.type == "hub"], 0)
  hub_cidr = element([for vpck, vpc in aws_vpc.main : vpc.cidr_block if vpc.tags.type == "hub"], 0)
}

resource "aws_internet_gateway" "hub" {
  vpc_id = local.hub_id
  tags = {
    Name = "hub_igw"
  }
}

resource "aws_subnet" "hub_trusted" {
  #availability_zone       = data.aws_availability_zones.available.names[0]
  vpc_id                  = local.hub_id
  cidr_block              = cidrsubnet(local.hub_cidr, 8, 0)
  map_public_ip_on_launch = false
  tags = {
    Name     = "hub_trusted_subnet"
    Security = "0"
    Type = "hub"
  }
}

resource "aws_subnet" "hub_untrusted" {
  #availability_zone       = data.aws_availability_zones.available.names[0]
  vpc_id                  = local.hub_id
  cidr_block              = cidrsubnet(local.hub_cidr, 8, 1)
  map_public_ip_on_launch = false
  tags = {
    Name     = "hub_untrusted_subnet"
    Security = "100"
    type = "hub"
  }
}

resource "aws_subnet" "spoke" {
  for_each                = var.spoke_subnets
  vpc_id                  = aws_vpc.main[each.value.vpc_id].id
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = each.value.private
  tags = {
    type = "spoke"
    Name = "${each.key}_subnet"
  }
}

resource "aws_vpc_peering_connection" "main" {
  for_each = {
    for vpck, vpc in aws_vpc.main : vpck => vpc if vpc.tags.type == "spoke"
  }
  peer_vpc_id = aws_vpc.main[each.key].id
  vpc_id      = local.hub_id
  auto_accept = true

  tags = {
    Name = "${each.key}_vpc_peering"
  }
}

resource "aws_security_group" "allow_all" {
  for_each    = aws_vpc.main
  name        = "allow_all_sg"
  description = "Allow all inbound/outbound traffic"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_acl" "main" {
  for_each = aws_vpc.main
  vpc_id   = aws_vpc.main[each.key].id

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  tags = {
    Name = "${each.key}_main_acl"
  }
}

resource "aws_network_acl_association" "main" {
  for_each       = var.spoke_subnets
  network_acl_id = aws_network_acl.main[each.value.vpc_id].id
  subnet_id      = aws_subnet.spoke[each.key].id
}

resource "aws_default_route_table" "hub" {
  for_each = {
    for vpck, vpc in aws_vpc.main : vpck => vpc if vpc.tags.type == "hub"
  }
  default_route_table_id = aws_vpc.main[each.key].default_route_table_id
  /* depends_on = [
    aws_vpc_peering_connection.main
  ] */

  dynamic "route" {
    iterator = vpc_rr

    for_each = [
      for vpck, vpc in aws_vpc.main :
      {
        cidr        = aws_vpc.main[vpck].cidr_block,
        vpc_peer_id = aws_vpc_peering_connection.main[vpck].id
      }
      if vpc.tags.type == "spoke"
    ]

    content {
      cidr_block                = vpc_rr.value.cidr
      vpc_peering_connection_id = vpc_rr.value.vpc_peer_id
    }
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }

  tags = {
    Name = "hub_main_rt"
  }
}

resource "aws_default_route_table" "spokes" {
  for_each = {
    for vpck, vpc in aws_vpc.main : vpck => vpc if vpc.tags.type == "spoke"
  }
  default_route_table_id = aws_vpc.main[each.key].default_route_table_id

  route {
    cidr_block                = "0.0.0.0/0"
    vpc_peering_connection_id = aws_vpc_peering_connection.main[each.key].id
  }

  tags = {
    Name = "spoke_${each.key}_main_rt"
  }
}



