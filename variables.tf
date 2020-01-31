
# -----------------------------------------------------------------------------
# variables to inject via terraform.tfvars or environment
# -----------------------------------------------------------------------------

variable "aws_region" {}
variable "aws_key_name" {
  description = "key to access instances  (ie. swarm.pem)"
  type        = string
}
variable "allowed_ip" {
  description = "Ip to allow ssh access"
  type        = string
}
variable "domain" {
  description = "default domain to pull acm and set default listener"
  type        = string
}
variable "owner" {
  description = "project owner ie. company name"
  type        = string
}
variable "ssl_arn" {
  description = "default certificate manager ssl certs"
  type        = string
}
variable "ssl_arns" {
  description = "list of additional certificate manager ssl certs (ie. [\"arn:..\", \"arn:...\"])"
  type        = set(string)
}
variable "subscriptions" {
  description = "phone number list for sms subscription to autscaling notices"
}
variable "sms_id" {
  description = "String to identify sms notice. (ie. Vernon AWS)"
  type        = string
}
variable "S3_scripts_path" {
  description = "S3 bucket path to startup scripts. (ie. bucket/path)"
  type        = string
}
variable "is_bucket_policy" {
  description = "0 if not passing; 1 if passing a bucket_policy_arn"
  type        = number
}
variable "peering_enabled" {
  description = "true || false  to create peer connection to another vpc in the same region.  default=default vpc"
  type        = bool
}
variable "peer_vpc_id" {
  description = "peer connection's vpc id.  May not be used if grabbing default vpc info"
  type        = string
}
variable "peer_cidr" {
  description = "peer connection's cidr.  May not be used if grabbing default vpc info"
  type        = string
}
variable "peer_route_table_id" {
  description = "peer connection's route table to add route to.  May not be used if grabbing default vpc info"
  type        = string
}
variable "docker_username" {
  description = "docker username used to pull private repositories"
  type        = string
}
variable "docker_password" {
  description = "docker password used to pull private repositories"
  type        = string
}

# -----------------------------------------------------------------------------
# variables with defaults.  Override in terraform.tfvars if desired.
# -----------------------------------------------------------------------------

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

variable "tags" {
  type = map

  default = {
    "Owner"   = "Vernon"
    "Project" = "terraform-aws-swarm"
    "Client"  = "internal"
  }
}

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

variable "target_groups" {
  description = "map of target groups"
  type        = list(object({
    name=string,
    domains=list(string),
    port=number,
    protocol=string,
    path=string,
    matcher=string,
    priority=number}))
  # sets up swarmpit.yourdomain in alb and swarmpit target group.  CHANGE yourdomain!!
  default     = [{name="swarmpit", domains=["swarmpit.yourdomain"], port=8080, protocol="HTTP",
                  path="/", matcher="200-299", priority=10}]
}
# swarm variables
# -----------------------------------------------------------------------

variable "first_master_instance_size" {
  description = "type of instance on initial master"
  type        = string
  default     = "m5dn.large"
}

# using instances that come with device attached.  Use the default attached size
variable "first_master_volume_size" {
  description = "volume size on initial master"
  type        = string
  default     = "75"
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

# time to wait for processes to happen on auto-scaling
variable "master_sleep_seconds" {
  description = "sleep time to allow nodes to join before running any stack deploys etc."
  type        = number
  default     = 60
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
