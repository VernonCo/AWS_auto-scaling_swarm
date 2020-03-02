provider "aws" {
  region  = var.aws_region
  version = "~> 2.50"
  # access_key = var.access_key
  # secret_key = var.secret_key
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
  depends_on  = [aws_s3_bucket.scripts_bucket]
  name        = format("%s-%s-bucket-policy", var.environment, var.namespace)
  description = "Access to S3 scripts bucket policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
          "${format("%s/*", aws_s3_bucket.scripts_bucket.arn)}",
          "${aws_s3_bucket.scripts_bucket.arn}"
      ]
    }
  ]
}
EOF
}

# S3 scripts bucket access
resource "aws_iam_role_policy_attachment" "bucket_access" {
  role       = aws_iam_role.swarm.id
  policy_arn = aws_iam_policy.bucket_policy.arn
}

# S3 scripts bucket access
resource "aws_iam_role_policy_attachment" "volume_access" {
  role       = aws_iam_role.swarm.id
  policy_arn = aws_iam_policy.volume_policy.arn
}

# *** Following is needed only if using cloudstor or similar permanent volumes plugin ***
resource "aws_iam_policy" "volume_policy" {
  name        = format("%s-%s-volume-policy", var.environment, var.namespace)
  description = "Access to volume managment policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "ec2:CreateTags",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "swarm_ec2" {
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
# modifying this after apply will recreate initial master and replace launch configurations.
# the new initial_master will be orphaned from the original extra nodes. You will need to ssh to
# the intial  master, then ssh to a  master node, get the token, and then join the initial master
# to the swarm.  Finally update the AWS secret token with the correct information so that any auto-
# scaling nodes will connect correctly.
resource "aws_instance" "first_swarm_master" {
  ami                         = data.aws_ami.target_ami.id
  instance_type               = var.first_master_instance_size
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  key_name                    = var.aws_key_name
  # spot_price    = var.master_spot_price
  depends_on = [
    aws_iam_role_policy_attachment.swarm_sm,
    aws_iam_role.swarm, aws_iam_instance_profile.swarm_ec2,
    aws_iam_role_policy_attachment.swarm_ssm,
    aws_vpc_endpoint.secretsmanager, aws_s3_bucket.scripts_bucket
  ]

  root_block_device {
    volume_type = "standard"
    volume_size = var.first_master_volume_size
  }

  vpc_security_group_ids = [aws_security_group.swarm.id]

  iam_instance_profile = aws_iam_instance_profile.swarm_ec2.name

  tags = merge(map("Name", format("%s-%s-master-1", var.environment, var.namespace)), var.tags)

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<EOF
#!/bin/bash
# download pem and start script
export ENVIRONMENT=${var.environment}
echo "export ENVIRONMENT=${var.environment}" >> /etc/profile.d/custom.sh
export S3_PATH=${format("%s-%s-%s", var.bucket_name, var.namespace, var.environment)}
echo "export S3_PATH=$S3_PATH" >> /etc/profile.d/custom.sh &
nohup aws s3 cp s3://$S3_PATH/swarm_initial_master.sh /start.sh &
# may be added by default in amazon image
export AWS_DEFAULT_REGION=${var.aws_region}
echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> /etc/profile.d/custom.sh
yum update -y -q
yum install -y jq
amazon-linux-extras install docker -y
service docker start

if [[ "${var.has_pem}" ]];then
  nohup aws s3 cp s3://$S3_PATH/${var.aws_key_name}.pem /${var.aws_key_name}.pem
  chmod 400 /${var.aws_key_name}.pem
fi

#docker login to pull private repositories if username and password secret identities are passed.
DOCKER_USER=$(aws secretsmanager get-secret-value --secret-id ${var.docker_username} --query "SecretString" --output text)
DOCKER_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${var.docker_password} --query "SecretString" --output text)
if test "$DOCKER_USER" && test "$DOCKER_PASSWORD";then
  docker login --username=$DOCKER_USER --password=$DOCKER_PASSWORD
fi

export SWARM_MASTER_TOKEN=${format("%s-swarm-master-token2", var.environment)}
export SWARM_WORKER_TOKEN=${format("%s-swarm-worker-token2", var.environment)}
# export to profile for use in updating tokens with update_tokens.sh
echo "export SWARM_MASTER_TOKEN=$SWARM_MASTER_TOKEN" >> /etc/profile.d/custom.sh
echo "export SWARM_WORKER_TOKEN=$SWARM_WORKER_TOKEN" >> /etc/profile.d/custom.sh

docker swarm init --advertise-addr $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
MASTER_TOKEN=$(aws secretsmanager get-secret-value --secret-id $SWARM_MASTER_TOKEN --query "SecretString" --output text)
echo "TOKEN=$MASTER_TOKEN"
if [ -z "$MASTER_TOKEN" ]
then  # does not exist so create secret
  aws secretsmanager create-secret --name $SWARM_MASTER_TOKEN --description "swarm token for masters" --secret-string $(docker swarm join-token manager -q) 2>/dev/null
else
  # exists so update token
  aws secretsmanager update-secret --secret-id $SWARM_MASTER_TOKEN --secret-string $(docker swarm join-token manager -q) 2>/dev/null
fi
TOKEN=$(aws secretsmanager get-secret-value --secret-id $SWARM_WORKER_TOKEN --query "SecretString" --output text)
echo "TOKEN=$TOKEN"
if [ -z "$TOKEN" ]
then  # does not exist so create secret
  aws secretsmanager create-secret --name $SWARM_WORKER_TOKEN --description "swarm token for workers" --secret-string $(docker swarm join-token worker -q) 2>/dev/null
else
  # exists so update token
  aws secretsmanager update-secret --secret-id $SWARM_WORKER_TOKEN --secret-string $(docker swarm join-token worker -q) 2>/dev/null
fi
echo "${var.portainer_password}" > /portainer_password

docker node update --label-add type=initial_master $(hostname)
# sleep time to allow nodes to join before running any stack deploys etc.
nodes=$((${var.master_nodes_desired} + ${var.worker_nodes_desired}))
while [ $(docker node ls -q | wc -l) -lt "$nodes" ]; do echo 'Waiting for nodes' >> /start.log;sleep 5;done

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
