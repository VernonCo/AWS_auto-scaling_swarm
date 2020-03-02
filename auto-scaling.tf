

#launch configuration for swarm nodes as master
resource "aws_launch_configuration" "swarm_master_node" {
  image_id      = data.aws_ami.target_ami.id
  instance_type = var.master_instance_size
  key_name      = var.aws_key_name
  spot_price    = var.master_node_spot_price
  # Must creat the master instance before the swarm masters to get the token
  #  to connect to the initial master and swarm master policies
  depends_on = [
    aws_instance.first_swarm_master, aws_iam_role.swarm,
    aws_iam_role_policy_attachment.swarm_sm,
    aws_iam_instance_profile.swarm_ec2,
    aws_iam_role_policy_attachment.swarm_ssm,
    aws_vpc_endpoint.secretsmanager
  ]

  root_block_device {
    volume_type = "standard"
    volume_size = var.master_volume_size
  }
  associate_public_ip_address = false
  security_groups             = [aws_security_group.swarm.id]

  iam_instance_profile = aws_iam_instance_profile.swarm_ec2.name

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<EOF
#!/bin/bash
export ENVIRONMENT=${var.environment}
echo "export ENVIRONMENT=${var.environment}" >> /etc/profile.d/custom.sh
export S3_PATH=${format("%s-%s-%s", var.bucket_name, var.namespace, var.environment)}
echo "export S3_PATH=S3_PATH" >> /etc/profile.d/custom.sh
nohup aws s3 cp s3://S3_PATH/${var.aws_key_name}.pem /${var.aws_key_name}.pem &
nohup aws s3 cp s3://S3_PATH/swarm_masters.sh /start.sh &
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
# export to profile for use in updating tokens with update_tokens.sh
echo "export SWARM_MASTER_TOKEN=$SWARM_MASTER_TOKEN" >> /etc/profile.d/custom.sh
echo "export SWARM_WORKER_TOKEN=${format("%s-swarm-worker-token", var.environment)}" >> /etc/profile.d/custom.sh

# make sure the first master is set up and has saved the join token to secrets
sleep ${var.sleep_seconds}

TOKEN=$(aws secretsmanager get-secret-value --secret-id $SWARM_MASTER_TOKEN --query "SecretString" --output text)
# echo "TOKEN=$TOKEN"

docker swarm join --token $TOKEN ${aws_instance.first_swarm_master.private_ip}:2377

# get the zone that the instances are running in and add to docker node's label
# this allows you to deploy containers equally in multiple zones using
# the deploy>preferences -spread:  node.labels.zone
chmod +x start.sh
. start.sh 2>&1 >> /start.log
EOF
}

#launch configuration for swarm nodes as workers
resource "aws_launch_configuration" "swarm_worker_node" {
  image_id      = data.aws_ami.target_ami.id
  instance_type = var.worker_instance_size
  key_name      = var.aws_key_name
  spot_price    = var.worker_node_spot_price
  # Must creat the master instance before the workers to get the token
  #  to connect to the master and swarm_worker policies
  depends_on = [
    aws_instance.first_swarm_master, aws_iam_role.swarm,
    aws_iam_role_policy_attachment.swarm_sm,
    aws_iam_instance_profile.swarm_ec2,
    aws_iam_role_policy_attachment.swarm_ssm,
    aws_vpc_endpoint.secretsmanager
  ]

  root_block_device {
    volume_type = "standard"
    volume_size = var.worker_volume_size
  }
  associate_public_ip_address = false
  security_groups             = [aws_security_group.swarm.id]

  iam_instance_profile = aws_iam_instance_profile.swarm_ec2.name

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<EOF
#!/bin/bash
#download pem and start script
export ENVIRONMENT=${var.environment}
echo "export ENVIRONMENT=$ENVIRONMENT" >> /etc/profile.d/custom.sh
export S3_PATH=${format("%s-%s-%s", var.bucket_name, var.namespace, var.environment)}
echo "export S3_PATH=S3_PATH" >> /etc/profile.d/custom.sh
nohup aws s3 cp s3://S3_PATH/${var.aws_key_name}.pem /${var.aws_key_name}.pem &
nohup aws s3 cp s3://S3_PATH/swarm_workers.sh /start.sh &
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
# make sure the first master is set up and has saved the join token to secrets
sleep ${var.sleep_seconds}

export SWARM_WORKER_TOKEN=${format("%s-swarm-worker-token2", var.environment)}
TOKEN=$(aws secretsmanager get-secret-value --secret-id $SWARM_WORKER_TOKEN --query "SecretString" --output text)
# echo "TOKEN=$TOKEN"

docker swarm join --token $TOKEN ${aws_instance.first_swarm_master.private_ip}:2377

# get the zone that the instances are running in and add to docker node's label
# this allows you to deploy containers equally in multiple zones using
# the deploy>preferences -spread:  node.labels.zone
chmod +x start.sh
. start.sh 2>&1 >> /start.log
EOF
}

resource "aws_autoscaling_group" "masters" {
  name                 = format("%s-%s-masters-asg", var.environment, var.namespace)
  launch_configuration = aws_launch_configuration.swarm_master_node.name
  min_size             = var.master_nodes_min_count
  max_size             = var.master_nodes_max_count
  desired_capacity     = var.master_nodes_desired
  termination_policies = ["OldestInstance", "OldestLaunchConfiguration"]
  health_check_type    = "EC2"
  target_group_arns    = aws_lb_target_group.project.*.arn
  vpc_zone_identifier  = module.vpc.private_subnets

  tag {
    key                 = "Name"
    value               = format("%s-%s-master-node", var.environment, var.namespace)
    propagate_at_launch = true
  }
  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "workers" {
  name                 = format("%s-%s-workers-asg", var.environment, var.namespace)
  launch_configuration = aws_launch_configuration.swarm_worker_node.name
  min_size             = var.worker_nodes_min_count
  max_size             = var.worker_nodes_max_count
  desired_capacity     = var.worker_nodes_desired
  termination_policies = ["OldestInstance", "OldestLaunchConfiguration"]
  health_check_type    = "EC2"
  target_group_arns    = aws_lb_target_group.project.*.arn
  vpc_zone_identifier  = module.vpc.private_subnets

  tag {
    key                 = "Name"
    value               = format("%s-%s-worker-node", var.environment, var.namespace)
    propagate_at_launch = true
  }
  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
