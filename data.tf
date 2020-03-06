# retieve you ip for allowing access to the intial master
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
    count      = var.allow_local_ip? 1: 0
    # allowed_ip = [var.allowed_ip]  # used to override below
    allowed_ip = ["${chomp(data.http.myip.body)}/32"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# retrieve latest vesion of aws ami
data "aws_ami" "target_ami" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# following example to retrieve default vpc and use instead of creating one
# you would need to change values where calling vpc and subnets

# # get default security group for region
# data "aws_security_group" "default" {
#   id = var.security_group_id
# }
# # get default vpc and subnets
# data "aws_vpc" "default" {
#   id = var.default_vpc_id
# }
# data "aws_subnet_ids" "default" {
#   vpc_id = data.aws_vpc.default.id
# }

# data "aws_subnet" "default" {
#   count = length(data.aws_subnet_ids.default.ids)
#   id       = tolist(data.aws_subnet_ids.default.ids)[count.index]
# }

# output "default_subnet_cidr_blocks" {
#   value = [data.aws_subnet.default.*.cidr_block]
# }
