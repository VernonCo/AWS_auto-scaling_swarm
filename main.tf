provider "aws" {
  region  = var.aws_region
  version = "~> 2.40"
}

# ------------------------------------------------------------------------------
# Setup swarm manager instance in the "public" subnet
# ------------------------------------------------------------------------------

resource "aws_iam_role" "swarm" {
  name        = format("%s-%s-role", var.environment, var.namespace)
  description = "privileges for the swarm master"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "swarm_ssm" {
  role       = aws_iam_role.swarm.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "swarm_sm" {
  role       = aws_iam_role.swarm.id
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_policy" "bucket_policy" {
  name        = format("%s-%s-policy", var.environment, var.namespace)
  description = "Access to S3 scripts bucket policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
          "arn:aws:s3:::${var.S3_scripts_path}/*",
          "arn:aws:s3:::${var.S3_scripts_path}"
      ]
    }
  ]
}
EOF
}

# S3 scripts bucket access
resource "aws_iam_role_policy_attachment" "bucket_access" {
  count      = var.is_bucket_policy
  role       = aws_iam_role.swarm.id
  policy_arn = aws_iam_policy.bucket_policy.arn
}

resource "aws_iam_instance_profile" "swarm" {
  name = format("%s-%s-profile", var.environment, var.namespace)
  role = aws_iam_role.swarm.id
}

resource "aws_security_group" "swarm" {
  vpc_id      = module.vpc.vpc_id
  name        = format("%s-%s-sg", var.environment, var.namespace)
  description = "allow docker and http/https"

  # ephemeral in
  # ingress {
  #   from_port   = 1024
  #   to_port     = 65535
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = [aws_security_group.alb-sg.id]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #dns
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = [aws_security_group.alb-sg.id]
  }
}

# create on-demand instance with elastic-IP attached to initialize the swarm
resource "aws_instance" "first_swarm_master" {
  ami                         = data.aws_ami.target_ami.id
  instance_type               = var.first_master_instance_size
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  key_name                    = var.aws_key_name
  # spot_price    = var.master_spot_price
  depends_on = [
    aws_iam_role_policy_attachment.swarm_sm,
    aws_iam_role.swarm, aws_iam_instance_profile.swarm,
    aws_iam_role_policy_attachment.swarm_ssm,
    aws_vpc_endpoint.secretsmanager
  ]

  root_block_device {
    volume_type = "standard"
    volume_size = var.first_master_volume_size
  }

  vpc_security_group_ids = [aws_security_group.swarm.id]

  iam_instance_profile = aws_iam_instance_profile.swarm.name

  tags = merge(map("Name", format("%s-%s-master-1", var.environment, var.namespace)), var.tags)

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<EOF
#!/bin/bash
# download pem and start script
export ENVIRONMENT=${var.environment}
echo "export ENVIRONMENT=${var.environment}" >> ~/.bashrc
export S3_PATH=${var.S3_scripts_path}
echo "export S3_PATH=${var.S3_scripts_path}" >> ~/.bashrc
nohup aws s3 cp s3://${var.S3_scripts_path}/${var.aws_key_name}.pem /${var.aws_key_name}.pem &
nohup aws s3 cp s3://${var.S3_scripts_path}/swarm_initial_master.sh /start.sh &
yum update -y -q
yum install -y jq
amazon-linux-extras install docker -y
service docker start
export AWS_DEFAULT_REGION=${var.aws_region}  #may not need this
export SWARM_MASTER_TOKEN=${format("%s-swarm-master-token2", var.environment)}
export SWARM_WORKER_TOKEN=${format("%s-swarm-worker-token2", var.environment)}
# export to profile for use in updating tokens with update_tokens.sh
echo "export SWARM_MASTER_TOKEN=$SWARM_MASTER_TOKEN" >> ~/.bashrc
echo "export SWARM_WORKER_TOKEN=$SWARM_WORKER_TOKEN" >> ~/.bashrc

docker swarm init --advertise-addr $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
MASTER_TOKEN=$(aws secretsmanager get-secret-value --secret-id $SWARM_MASTER_TOKEN --query "SecretString" --output text)
echo "TOKEN=$MASTER_TOKEN"
if [ -z "$MASTER_TOKEN" ]
then  #is empty
  aws secretsmanager create-secret --name $SWARM_MASTER_TOKEN --description "swarm token for masters" --secret-string $(docker swarm join-token manager -q) 2>/dev/null
else
  # update token
  aws secretsmanager update-secret --secret-id $SWARM_MASTER_TOKEN --secret-string $(docker swarm join-token manager -q) 2>/dev/null
fi
TOKEN=$(aws} secretsmanager get-secret-value --secret-id $SWARM_WORKER_TOKEN --query "SecretString" --output text)
echo "TOKEN=$TOKEN"
if [ -z "$TOKEN" ]
then  #is empty
  aws secretsmanager create-secret --name $SWARM_WORKER_TOKEN --description "swarm token for workers" --secret-string $(docker swarm join-token worker -q) 2>/dev/null
else
  # update token
  aws secretsmanager update-secret --secret-id $SWARM_WORKER_TOKEN --secret-string $(docker swarm join-token worker -q) 2>/dev/null
fi
mkdir /tmp/data

# sleep time to allow nodes to join before running any stack deploys etc.
sleep ${var.master_sleep_seconds}

chmod 400 /${var.aws_key_name}.pem
chmod +x start.sh
. start.sh 2>&1 >> /start.log
EOF
}
# elastic Ip for primary master

resource "aws_eip" "swarm-master" {
  vpc      = true
  instance = aws_instance.first_swarm_master.id
}



# sms only available in us-east-1 and us-west-2

# resource "aws_autoscaling_notification" "notifications" {
#   group_names = [
#     aws_autoscaling_group.masters.name,
#     aws_autoscaling_group.workers.name,
#   ]

#   notifications = [
#     "autoscaling:EC2_INSTANCE_LAUNCH",
#     "autoscaling:EC2_INSTANCE_TERMINATE",
#     "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
#     "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
#   ]

#   topic_arn = aws_sns_topic.swarm_updates.arn
# }
