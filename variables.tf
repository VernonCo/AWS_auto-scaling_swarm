
# *** Requires AWS static or environment credentials.  If they are not provided, you
# will need to uncomment them in the provider on the main.tf and the 2 first variables below

# -----------------------------------------------------------------------------
# variables to inject via terraform.tfvars or environment
# -----------------------------------------------------------------------------

# AWS provider info
# variable access_key {}
# variable secret_key {}
variable "aws_region" {}

variable "aws_key_name" {
  description = "key to access instances  (ie. 'swarm' for swarm.pem)"
  type        = string
}
# *** place the pem in the same folder as this file ***********************
#  in order to be copied to the S3 private scripts bucket
# allows ssh between instances if desired
variable has_pem {
  description = "1 if passing a pem for containers to ssh back and forth"
  type        = string
  default     = ""
}
variable "allowed_ip" {
  description = "Ip to allow ssh access ie. 173.2.2.2/32"
  type        = string
}
variable "ssl_arn" {
  description = "default certificate manager ssl cert"
  type        = string
}
variable bucket_name {
  description = "bucket name for scripts"
  type        = string
}
variable "domain" {
  description = "default domain to pull acm and set default listener"
  type        = string
  default     = "example.com"
}
variable "owner" {
  description = "project owner ie. company name"
  type        = string
  default     = "my_project"
}
variable "ssl_arns" {
  description = "list of additional certificate manager ssl certs (ie. [\"arn:..\", \"arn:...\"])"
  type        = set(string)
  default     = []
}
variable "portainer_password" {
  description = "portainer password for admin access"
  type        = string
  default     = "a_password_to_use"
}

# add a peering connection  ie to the default vpc
variable "peering_enabled" {
  description = "true || false  to create peer connection to another vpc in the same region.  default=default vpc"
  type        = bool
  default     = false
}
variable "peer_vpc_id" {
  description = "peer connection's vpc id.  May not be used if grabbing default vpc info"
  type        = string
  default     = ""
}
variable "peer_cidr" {
  description = "peer connection's cidr.  May not be used if grabbing default vpc info"
  type        = string
  default     = ""
}
variable "peer_route_table_id" {
  description = "peer connection's route table to add route to.  May not be used if grabbing default vpc info"
  type        = string
  default     = ""
}

# Add AWS Secrets for docker login to pull private repositories
variable "docker_username" {
  description = "docker username used to pull private repositories"
  type        = string
  default     = ""
}
variable "docker_password" {
  description = "docker password used to pull private repositories"
  type        = string
  default     = ""
}

# following 2 can be used in regions that have sns as part of notifications.tf

# variable "subscriptions" {
#   description = "phone number list for sms subscription to autscaling notices"
#   type        = set(string)
#   default     = null
# }
# variable "sms_id" {
#   description = "String to identify sms notice. (ie. Vernon AWS)"
#   type        = string
#   default     = null
# }
# -----------------------------------------------------------------------------
# variables with defaults.  Override in terraform.tfvars or here if desired.
# -----------------------------------------------------------------------------

# sets up swarmpit.yourdomain in alb and swarmpit target group.
# *************  CHANGE yourdomain!!  *******************************
variable "target_groups" {
  description = "map of target groups"
  type = list(object({
    name     = string,
    domains  = list(string),
    port     = number,
    protocol = string,
    path     = string,
    matcher  = string,
  priority = number }))
  default = [
    { name = "swarmpit", domains = ["dev-swarmpit.yourdomain"],
    port = 8080, protocol = "HTTP", path = "/", matcher = "200-299", priority = 10 },
    { name = "portainer", domains = ["dev-portainer.yourdomain"],
    port = 9000, protocol = "HTTP", path = "/", matcher = "200-299", priority = 20 }
  ]
}

variable "tags" {
  type = map

  default = {
    "Owner"   = "YOUR COMPANY"
    "Project" = "terraform-aws-swarm"
    "Client"  = "internal"
  }
}
variable "environment" {
  description = "used through out for tagging and creating unique resources"
  type        = string
  default     = "dev"
}

variable "namespace" {
  description = "used through out for tagging and creating unique resources"
  type        = string
  default     = "swarm"
}

#network settings check to make sure there are no colisions with existing
variable "vpc_cidr" {
  description = "vpc cidr ie. 172.28.0.0/16"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "list of cidr for private subnets"
  type        = set(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "list of cidr for public subnets"
  type        = set(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable script_uploads {
  description = "list of script files to upload. They run on instances at start up"
  type        = list(string)
  default = [
    "swarm_initial_master.sh", "swarm_masters.sh", "swarm_workers.sh",
    "update_tokens.sh", "add_zone_label.sh", "remove_dead_nodes.sh"
  ]
}

variable swarm_script_uploads {
  description = "list of swarm deploy script files to upload. They run on instances at start up. see example_scripts"
  type        = list(string)
  default     = ["portainer.sh", "swarmpit.sh"]
}

variable swarm_stack_uploads {
  description = "list of docker-compose files for stacks. see example_scripts/stacks"
  type        = list(string)
  default     = ["portainer.yml", "swarmpit.yml"]
}
# swarm variables
# -----------------------------------------------------------------------

variable "first_master_instance_size" {
  description = "type of instance on initial master"
  type        = string
  default     = "t3.large"
}

# using instances that come with device attached.  Use the default attached size
variable "first_master_volume_size" {
  description = "volume size on initial master"
  type        = string
  default     = "30"
}

variable "master_node_spot_price" {
  type    = string
  default = "0.007"
}

# additional masters besides intial master
variable "master_nodes_min_count" {
  description = "number of swarm master nodes to launch"
  type        = number
  default     = 2 #2
}

variable "master_nodes_max_count" {
  description = "max number of swarm master nodes to launch"
  type        = number
  default     = 4 #4
}

variable "master_nodes_desired" {
  description = "number of swarm master nodes to launch"
  type        = number
  default     = 2 #2
}

variable "master_instance_size" {
  description = "type of instance and size. ie t2.micro"
  type        = string
  default     = "t2.small"
}

# using instances that come with device attached.  Use the default attached size
variable "master_volume_size" {
  description = "size of the data volume. (ie. 30)"
  type        = string
  default     = "30"
}

variable "worker_node_spot_price" {
  type    = string
  default = "0.358"
}

#nodes as worker only
variable "worker_nodes_min_count" {
  description = "number of swarm worker nodes to launch"
  type        = number
  default     = 0
}

variable "worker_nodes_max_count" {
  description = "number of swarm worker nodes to launch"
  type        = number
  default     = 0
}

variable "worker_nodes_desired" {
  description = "number of swarm worker nodes to launch"
  type        = number
  default     = 0
}

variable "worker_instance_size" {
  description = "type of instance and size. ie t2.micro"
  type        = string
  default     = "m5dn.2xlarge"
}

# using instances that come with device attached.  Use the default attached size
variable "worker_volume_size" {
  description = "size of the data volume. (ie. 30)"
  type        = string
  default     = "300"
}

variable "sleep_seconds" {
  description = "make sure the first master is set up and has saved the join token to secrets"
  type        = number
  default     = 15
}

# -----------------------------------------------------------------------------
# data lookups
# -----------------------------------------------------------------------------
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
