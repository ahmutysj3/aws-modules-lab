data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "trace-tf-unlocked-bucket"
    key    = "aws-net-terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  hub_id = element([for vpck, vpc in data.terraform_remote_state.network.outputs.vpcs : vpc.id if vpc.tags.type == "hub"], 0)

  hub_cidr = element([for vpck, vpc in data.terraform_remote_state.network.outputs.vpcs : vpc.cidr if vpc.tags.type == "hub"], 0)

  untrusted_subnet_id = data.terraform_remote_state.network.outputs.hub_subnets.untrusted.id

  untrusted_subnet_cidr = data.terraform_remote_state.network.outputs.hub_subnets.untrusted.cidr

  key_name = data.terraform_remote_state.network.outputs.ec2_key.name
}

resource "aws_instance" "openvpn" {
  count         = var.test_openvpn == true ? 1 : 0
  ami           = var.openvpn_ami
  key_name      = local.key_name
  instance_type = "t2.micro"
  tags = {
    "Name" = "openvpn_as"
  }
  user_data = <<EOF
    admin_user=${var.server_username}
    admin_pw=${var.server_password}
    EOF
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.openvpn[0].id
  }
}

resource "aws_network_interface" "openvpn" {
  count           = var.test_openvpn == true ? 1 : 0
  subnet_id       = local.untrusted_subnet_id
  private_ips     = [cidrhost(local.untrusted_subnet_cidr, 100)]
  security_groups = [aws_security_group.openvpn[0].id]

  tags = {
    Name = "openvpn_interface"
  }
}

resource "aws_eip" "openvpn_public" {
  count                     = var.test_openvpn == true ? 1 : 0
  vpc                       = true
  network_interface         = aws_network_interface.openvpn[0].id
  associate_with_private_ip = cidrhost(local.untrusted_subnet_cidr, 100)
  tags = {
    Name = "openvpn_public"
  }
}

resource "aws_security_group" "openvpn" {
  count       = var.test_openvpn == true ? 1 : 0
  name        = "open_vpn_sg"
  description = "Allows necessary protocols for openvpn AS"
  vpc_id      = local.hub_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_network_interfaces" "all" {}

output "network_interfaces" {
  value = data.aws_network_interfaces.all.ids
}

output "openvpn" {
  value = {
    name          = try(aws_instance.openvpn[0].tags.Name, null)
    id            = try(aws_instance.openvpn[0].id, null)
    instance_type = try(aws_instance.openvpn[0].instance_type, null)
    key_name      = try(aws_instance.openvpn[0].key_name, null)
    net_int       = try(aws_network_interface.openvpn[0].id, null)
  }
}


output "openvpn_eip" {
  value = {
    openvpn_eip = {
      id          = try(aws_eip.openvpn_public[0].id, null)
      public_ip   = try(aws_eip.openvpn_public[0].public_ip, null)
      mapped_to   = try(aws_eip.openvpn_public[0].private_ip, null)
      attached_to = try(aws_eip.openvpn_public[0].instance, null)
    }
  }
}