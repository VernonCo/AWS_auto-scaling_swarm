

resource "aws_security_group" "vpc_channel" {
  vpc_id = module.vpc.vpc_id
  name = format("%s-%s-vpc-channel",var.environment,var.namespace)
  description = "allow all communication on vpc between members of security group swarm_master and swarm_work"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    security_groups = [aws_security_group.swarm.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    security_groups = [aws_security_group.swarm.id]
  }

  tags   = merge(map("Name", format("%s-%s-vpc-channel",var.environment,var.namespace)), var.tags)
}

module "vpc" {
  # "https://github.com/terraform-aws-modules/terraform-aws-vpc"
  source = "../../modules/terraform-aws-vpc"

  name = format("%s-%s-vpc",var.environment,var.namespace)

  azs             = data.aws_availability_zones.available.names
  cidr            = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # enable_classiclink             = true
  # enable_classiclink_dns_support = true
  # add secretsmanager access for swarm to get token

  # put separately so we can use depends on for instances
  # enable_secretsmanager_endpoint = true
  # secretsmanager_endpoint_security_group_ids = [aws_security_group.vpc_channel.id]
  # secretsmanager_endpoint_private_dns_enabled = true
  #if omitted uses private subnets
  # secretsmanager_endpoint_subnet_ids = module.vpc.private_subnets

  propagate_public_route_tables_vgw = true
  propagate_private_route_tables_vgw = true

  public_subnet_tags = {
    Name = format("%s-%s-public",var.environment,var.namespace)
  }

  tags = {
    Namespace       = var.namespace
    Environment = var.environment
  }

  vpc_tags = {
    Name = format("%s-%s-vpc",var.environment,var.namespace)
  }
}

###################################
# VPC Endpoint for Secrets Manager
###################################
data "aws_vpc_endpoint_service" "secretsmanager" {
  service = "secretsmanager"
}

resource "aws_vpc_endpoint" "secretsmanager" {
  depends_on        = [module.vpc.vpc_id,module.vpc.private_subnets,module.vpc.public_subnets]
  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.secretsmanager.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.vpc_channel.id]
  subnet_ids          = coalescelist(module.vpc.private_subnets,module.vpc.public_subnets)
  private_dns_enabled = true
  tags                = merge(map("Name", format("%s-%s-secret-mngr",var.environment,var.namespace)), var.tags)
}

# resource "aws_network_acl" "public" {
#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.public_subnets
#   tags       = merge(map("Name", format("%s-%s-public",var.environment,var.namespace)), var.tags)
# }

# resource "aws_network_acl_rule" "public_ephemeral_out" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 400
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 1024
#   to_port        = 65535
# }

# resource "aws_network_acl_rule" "public_http_out" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 101
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 80
#   to_port        = 80
# }

# resource "aws_network_acl_rule" "public_https_out" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 102
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 443
#   to_port        = 443
# }

# resource "aws_network_acl_rule" "public_ssh_out" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 300
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 22
#   to_port        = 22
# }

# resource "aws_network_acl_rule" "public_ephemeral_in" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 100
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 1024
#   to_port        = 65535
# }

# # resource "aws_network_acl_rule" "public_http_in" {
# #   network_acl_id = aws_network_acl.public.id
# #   rule_number    = 101
# #   egress         = false
# #   protocol       = "tcp"
# #   rule_action    = "allow"
# #   cidr_block     = "0.0.0.0/0"
# #   from_port      = 80
# #   to_port        = 80
# # }

# # resource "aws_network_acl_rule" "public_https_in" {
# #   network_acl_id = aws_network_acl.public.id
# #   rule_number    = 102
# #   egress         = false
# #   protocol       = "tcp"
# #   rule_action    = "allow"
# #   cidr_block     = "0.0.0.0/0"
# #   from_port      = 443
# #   to_port        = 443
# # }

# resource "aws_network_acl_rule" "public_service_in" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 103
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = local.allowed_ip
#   from_port      = 8080
#   to_port        = 8080
# }

# # Docker needs tcp 2377 and 7946, and udp 7946 and 4789
# # between each node in the swarm
# resource "aws_network_acl_rule" "public_docker_in_1" {
#   count = length(module.vpc.private_subnets)

#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 200+count.index
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = element(module.vpc.private_subnets_cidr_blocks,count.index)
#   from_port      = 2377
#   to_port        = 2377
# }

# resource "aws_network_acl_rule" "public_docker_in_2" {
#   count = length(module.vpc.private_subnets)
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 210+count.index
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = element(module.vpc.private_subnets_cidr_blocks,count.index)
#   from_port      = 7946
#   to_port        = 7946
# }

# resource "aws_network_acl_rule" "public_docker_in_3" {
#   count = length(module.vpc.private_subnets)
#   cidr_block     = element(module.vpc.private_subnets_cidr_blocks,count.index)
#   rule_number    = 220+count.index
#   network_acl_id = aws_network_acl.public.id
#   egress         = false
#   protocol       = "udp"
#   rule_action    = "allow"
#   from_port      = 7946
#   to_port        = 7946
# }

# resource "aws_network_acl_rule" "public_docker_in_4" {
#   count = length(module.vpc.private_subnets)
#   cidr_block     = element(module.vpc.private_subnets_cidr_blocks,count.index)
#   rule_number    = 230+count.index
#   network_acl_id = aws_network_acl.public.id
#   egress         = false
#   protocol       = "udp"
#   rule_action    = "allow"
#   from_port      = 4789
#   to_port        = 4789
# }

# resource "aws_network_acl_rule" "public_docker_out_1" {
#   count = length(module.vpc.private_subnets)
#   cidr_block     = element(module.vpc.private_subnets_cidr_blocks,count.index)
#   rule_number    = 240+count.index
#   network_acl_id = aws_network_acl.public.id
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   from_port      = 2377
#   to_port        = 2377
# }

# resource "aws_network_acl_rule" "public_docker_out_2" {
#   count = length(module.vpc.private_subnets)
#   cidr_block     = element(module.vpc.private_subnets_cidr_blocks,count.index)
#   rule_number    = 250+count.index
#   network_acl_id = aws_network_acl.public.id
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   from_port      = 7946
#   to_port        = 7946
# }

# resource "aws_network_acl_rule" "public_docker_out_3" {
#   count = length(module.vpc.private_subnets)
#   cidr_block     = element(module.vpc.private_subnets_cidr_blocks,count.index)
#   rule_number    = 260+count.index
#   network_acl_id = aws_network_acl.public.id
#   egress         = true
#   protocol       = "udp"
#   rule_action    = "allow"
#   from_port      = 7946
#   to_port        = 7946
# }

# resource "aws_network_acl_rule" "public_docker_out_4" {
#   count = length(module.vpc.private_subnets)
#   cidr_block     = element(module.vpc.private_subnets_cidr_blocks,count.index)
#   rule_number    = 270+count.index
#   network_acl_id = aws_network_acl.public.id
#   egress         = true
#   protocol       = "udp"
#   rule_action    = "allow"
#   from_port      = 4789
#   to_port        = 4789
# }

# resource "aws_network_acl_rule" "public_ssh_in" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 301
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = local.allowed_ip
#   from_port      = 22
#   to_port        = 22
# }

# # ------------------------------------------------------------------------------
# # NAT gateway - Allows traffic out of the private subnet
# # ------------------------------------------------------------------------------
# # resource "aws_eip" "nat_eip" {
# #   vpc = true
# # }

# # resource "aws_nat_gateway" "main" {
# #   allocation_id = aws_eip.nat_eip.id
# #   subnet_id     = aws_subnet.public.id
# #   depends_on    = [aws_internet_gateway.main]
# #   tags          = merge(map("Name", format("%s-%s-nat-gateway",var.environment,var.namespace)), var.tags)
# # }

# # ------------------------------------------------------------------------------
# # define the private subnet
# # ------------------------------------------------------------------------------

# # resource "aws_subnet" "private" {
# #   vpc_id                  = module.vpc.vpc_id
# #   cidr_block              = cidrsubnet(var.vpc_cidr, 10, 41)
# #   map_public_ip_on_launch = false
# #   availability_zone       = data.aws_availability_zones.available.names[1]
# #   tags                    = merge(map("Name", format("%s-%s-private",var.environment,var.namespace)), var.tags)
# # }

# # resource "aws_route_table" "private" {
# #   vpc_id = module.vpc.vpc_id

# #   route {
# #     cidr_block     = "0.0.0.0/0"
# #     nat_gateway_id = aws_nat_gateway.main.id
# #   }

# #   tags = merge(map("Name", format("%s-%s-private",var.environment,var.namespace)), var.tags)
# # }

# # resource "aws_route_table_association" "private_route_table_association" {
# #   subnet_id      = aws_subnet.private.id
# #   route_table_id = aws_route_table.private.id
# # }

# resource "aws_network_acl" "private" {
#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets
#   tags       = merge(map("Name", format("%s-%s-private",var.environment,var.namespace)), var.tags)
# }

# resource "aws_network_acl_rule" "ephemeral_out" {
#   network_acl_id = aws_network_acl.private.id
#   rule_number    = 100
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 1024
#   to_port        = 65535
# }

# resource "aws_network_acl_rule" "private_http_out" {
#   network_acl_id = aws_network_acl.private.id
#   rule_number    = 101
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 80
#   to_port        = 80
# }

# resource "aws_network_acl_rule" "private_https_out" {
#   network_acl_id = aws_network_acl.private.id
#   rule_number    = 102
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 443
#   to_port        = 443
# }

# resource "aws_network_acl_rule" "ephemeral_in" {
#   network_acl_id = aws_network_acl.private.id
#   rule_number    = 100
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 1024
#   to_port        = 65535
# }

# # resource "aws_network_acl_rule" "private_http_in" {
# #   network_acl_id = aws_network_acl.private.id
# #   rule_number    = 101
# #   egress         = false
# #   protocol       = "tcp"
# #   rule_action    = "allow"
# #   cidr_block     = "0.0.0.0/0"
# #   from_port      = 80
# #   to_port        = 80
# # }

# # resource "aws_network_acl_rule" "https_in" {
# #   network_acl_id = aws_network_acl.private.id
# #   rule_number    = 102
# #   egress         = false
# #   protocol       = "tcp"
# #   rule_action    = "allow"
# #   cidr_block     = "0.0.0.0/0"
# #   from_port      = 443
# #   to_port        = 443
# # }

# # Docker needs tcp 2377 and 7946, and udp 7946 and 4789
# # between each node in the swarm
# resource "aws_network_acl_rule" "private_docker_in_1" {
#   count = length(module.vpc.public_subnets)
#   cidr_block     = element(module.vpc.public_subnets_cidr_blocks,count.index)
#   rule_number    = 280+count.index
#   network_acl_id = aws_network_acl.private.id
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   from_port      = 2377
#   to_port        = 2377
# }

# resource "aws_network_acl_rule" "private_docker_in_2" {
#   count = length(module.vpc.public_subnets)
#   cidr_block     = element(module.vpc.public_subnets_cidr_blocks,count.index)
#   rule_number    = 290+count.index
#   network_acl_id = aws_network_acl.private.id
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   from_port      = 7946
#   to_port        = 7946
# }

# resource "aws_network_acl_rule" "private_docker_in_3" {
#   count = length(module.vpc.public_subnets)
#   cidr_block     = element(module.vpc.public_subnets_cidr_blocks,count.index)
#   rule_number    = 310+count.index
#   network_acl_id = aws_network_acl.private.id
#   egress         = false
#   protocol       = "udp"
#   rule_action    = "allow"
#   from_port      = 7946
#   to_port        = 7946
# }

# resource "aws_network_acl_rule" "private_docker_in_4" {
#   count = length(module.vpc.public_subnets)
#   cidr_block     = element(module.vpc.public_subnets_cidr_blocks,count.index)
#   rule_number    = 320+count.index
#   network_acl_id = aws_network_acl.private.id
#   egress         = false
#   protocol       = "udp"
#   rule_action    = "allow"
#   from_port      = 4789
#   to_port        = 4789
# }

# resource "aws_network_acl_rule" "private_docker_out_1" {
#   count = length(module.vpc.public_subnets)
#   cidr_block     = element(module.vpc.public_subnets_cidr_blocks,count.index)
#   rule_number    = 330+count.index
#   network_acl_id = aws_network_acl.private.id
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   from_port      = 2377
#   to_port        = 2377
# }

# resource "aws_network_acl_rule" "private_docker_out_2" {
#   count = length(module.vpc.public_subnets)
#   cidr_block     = element(module.vpc.public_subnets_cidr_blocks,count.index)
#   rule_number    = 340+count.index
#   network_acl_id = aws_network_acl.private.id
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   from_port      = 7946
#   to_port        = 7946
# }

# resource "aws_network_acl_rule" "private_docker_out_3" {
#   count = length(module.vpc.public_subnets)
#   cidr_block     = element(module.vpc.public_subnets_cidr_blocks,count.index)
#   rule_number    = 350+count.index
#   network_acl_id = aws_network_acl.private.id
#   egress         = true
#   protocol       = "udp"
#   rule_action    = "allow"
#   from_port      = 7946
#   to_port        = 7946
# }

# resource "aws_network_acl_rule" "private_docker_out_4" {
#   count = length(module.vpc.public_subnets)
#   cidr_block     = element(module.vpc.public_subnets_cidr_blocks,count.index)
#   rule_number    = 360+count.index
#   network_acl_id = aws_network_acl.private.id
#   egress         = true
#   protocol       = "udp"
#   rule_action    = "allow"
#   from_port      = 4789
#   to_port        = 4789
# }
