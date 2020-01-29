# CREATE PEERING BETWEEN new vpc and default vpc in same region

# data sources
data "aws_vpc" "peer_vpc" {
  default = true
}

data "aws_route_table" "peer" {
  count = var.peering_enabled ? 1 : 0
  vpc_id = data.aws_vpc.peer_vpc.id
  # filter {
  #   name    = "route.destination-cidr-block"
  #   values  = [var.peer_cidr]
  #           }
}

data "aws_route_table" "this" {
  count = var.peering_enabled ? 1 : 0
  vpc_id = module.vpc.vpc_id
  filter {
    name    = "association.main"
    values  = [true]
  }
}

# create resources
resource "aws_vpc_peering_connection" "vpc_peering" {
  count = var.peering_enabled ? 1 : 0
  # provider = aws.peer
  # peer_region = var.peer_region
  peer_vpc_id = data.aws_vpc.peer_vpc.id   # or var.peer_vpc_id
  vpc_id = module.vpc.vpc_id
  auto_accept               = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name        = format("default-vpc-peering-%s-%s",var.environment,var.namespace)
    Environment = var.environment
  }
}

# resource "aws_vpc_peering_connection_accepter" "peering-accepter" {
#   count = var.peering_enabled ? 1 : 0
#   vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering[count.index].id
#   auto_accept               = true
# }

resource "aws_route" "main_route" {
  count = var.peering_enabled ? 1 : 0
  route_table_id            = data.aws_route_table.this[count.index].id
  destination_cidr_block    = data.aws_vpc.peer_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering[count.index].id
}

resource "aws_route" "peer_main_route" {
  count = var.peering_enabled ? 1 : 0
  route_table_id            = data.aws_route_table.peer[count.index].id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering[count.index].id
}

# --------------------------------------------------------------------------------
# example to use for cross region peering
# --------------------------------------------------------------------------------

# provider for cross region peer connection
# provider "aws" {
#   alias = "peer"
#   region = var.peer_region
# }

# data "aws_vpc" "peer_vpc" {
#   provider = aws.peer
#   default = true
# }
# ##########################
# # VPC peering connection #
# ##########################
# resource "aws_vpc_peering_connection" "this" {
  # count = var.peering_enabled ? 1 : 0
#   provider      = aws
#   peer_vpc_id   = data.aws_vpc.peer_vpc.id
#   vpc_id        = module.vpc.vpc_id
#   peer_region   = aws.peer
# }

# ######################################
# # VPC peering accepter configuration #
# ######################################
# resource "aws_vpc_peering_connection_accepter" "peer_accepter" {
  # count = var.peering_enabled ? 1 : 0
#   provider                  = aws.peer
#   vpc_peering_connection_id = aws_vpc_peering_connection.this.id
#   auto_accept               = true
# }

# #######################
# # VPC peering options #
# #######################
# resource "aws_vpc_peering_connection_options" "this" {
  # count = var.peering_enabled ? 1 : 0
#   provider                  = aws
#   vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer_accepter.id

#   requester {
#     allow_remote_vpc_dns_resolution  = var.this_dns_resolution
#     allow_classic_link_to_remote_vpc = var.this_link_to_peer_classic
#     allow_vpc_to_remote_classic_link = var.this_link_to_local_classic
#   }
# }

# resource "aws_vpc_peering_connection_options" "accepter" {
  # count = var.peering_enabled ? 1 : 0
#   provider                  = aws.peer
#   vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer_accepter.id

#   accepter {
#     allow_remote_vpc_dns_resolution  = var.peer_dns_resolution
#     allow_classic_link_to_remote_vpc = var.peer_link_to_peer_classic
#     allow_vpc_to_remote_classic_link = var.peer_link_to_local_classic
#   }
# }

# ###################
# # This VPC Routes #
# ###################
# resource "aws_route" "this_routes_region" {
#   provider                  = aws.this
#   count                     = length(data.aws_route_tables.this_vpc_rts.ids)
#   route_table_id            = tolist(data.aws_route_tables.this_vpc_rts.ids)[count.index]
#   destination_cidr_block    = data.aws_vpc.peer_vpc.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.this.id
# }

# ###################
# # Peer VPC Routes #
# ###################
# resource "aws_route" "peer_routes_region" {
#   provider                  = aws.peer
#   count                     = length(data.aws_route_tables.peer.ids)
#   route_table_id            = tolist(data.aws_route_tables.peer.ids)[count.index]
#   destination_cidr_block    = var.vpc_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.this.id
# }
