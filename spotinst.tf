# can be used inplace of the auto-scaling.tf & asg_policy.tf
# provider "spotinst" {
#   token = var.spotinst_token

#   account = var.spotinst_account
# }

# resource "spotinst_elastigroup_aws" "stage-swarm-masters" {

#   depends_on = [aws_instance.first_swarm_master]
#   name       = format("%s-swarm-masters", var.environment)

#   description = "stage swarm project"

#   spot_percentage = 100

#   orientation = "balanced"

#   draining_timeout = 120

#   fallback_to_ondemand = true

#   lifetime_period = "days"

#   # if desiring persistent volumes
#   # persist_block_devices = true
#   # persist_private_ip = true
#   # block_devices_mode = "reattach"

#   persist_block_devices = false

#   persist_root_device = false
#   revert_to_spot {
#     perform_at = "always"
#   }

#   desired_capacity = var.master_nodes_desired

#   min_size = var.master_nodes_min_count

#   max_size = var.master_nodes_max_count

#   capacity_unit = "instance"

#   instance_types_ondemand = "m5dn.large"

#   instance_types_spot = ["m5dn.large", "m5n.large", "m5n.xlarge", "m5dn.xlarge"]

#   instance_types_preferred_spot = ["m5dn.xlarge", "m5dn.large"]

#   subnet_ids = module.vpc.private_subnets

#   product = "Linux/UNIX"

#   # elastic_load_balancers = ["dev-swarm-ap", "dev-swarm-emailq", "dev-swarm-myvernon", "dev-swarm-oq", "dev-swarm-portainer", "dev-swarm-swarmpit"]

#   target_group_arns = aws_lb_target_group.project.*.arn

#   security_groups = [aws_security_group.swarm.id]

#   enable_monitoring = false

#   ebs_optimized = false

#   image_id = data.aws_ami.target_ami.id

#   key_name = var.aws_key_name

#   # used to run processes at start-up
#   user_data = <<EOF
# #!/bin/bash
# export ENVIRONMENT=${var.environment}
# echo "export ENVIRONMENT=${var.environment}" >> /etc/profile.d/custom.sh
# export S3_PATH=${format("%s-%s-%s-scripts", var.domain, var.namespace, var.environment)}
# echo "export S3_PATH=S3_PATH" >> /etc/profile.d/custom.sh
# nohup aws s3 cp s3://$S3_PATH/swarm_masters.sh /start.sh &
# # may be added by default in amazon image
# export AWS_DEFAULT_REGION=${var.aws_region}
# echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> /etc/profile.d/custom.sh
# yum update -y -q
# yum install -y jq
# amazon-linux-extras install docker -y
# service docker start
# if [[ "${var.has_pem}" ]];then
#   nohup aws s3 cp s3://$S3_PATH/${var.aws_key_name}.pem /${var.aws_key_name}.pem
#   chmod 400 /${var.aws_key_name}.pem
# fi

# #docker login to pull private repositories if username and password secret identities are passed.
# DOCKER_USER=$(aws secretsmanager get-secret-value --secret-id ${var.docker_username} --query "SecretString" --output text)
# DOCKER_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${var.docker_password} --query "SecretString" --output text)
# if test "$DOCKER_USER" && test "$DOCKER_PASSWORD";then
#   docker login --username=$DOCKER_USER --password=$DOCKER_PASSWORD
# fi
# export SWARM_MASTER_TOKEN=${format("%s-swarm-master-token2", var.environment)}
# # export to profile for use in updating tokens with update_tokens.sh
# echo "export SWARM_MASTER_TOKEN=$SWARM_MASTER_TOKEN" >> /etc/profile.d/custom.sh
# echo "export SWARM_WORKER_TOKEN=${format("%s-swarm-worker-token", var.environment)}" >> /etc/profile.d/custom.sh

# # make sure the first master is set up and has saved the join token to secrets
# sleep ${var.sleep_seconds}

# TOKEN=$(aws secretsmanager get-secret-value --secret-id $SWARM_MASTER_TOKEN --query "SecretString" --output text)
# # echo "TOKEN=$TOKEN"

# docker swarm join --token $TOKEN

# # get the zone that the instances are running in and add to docker node's label
# # this allows you to deploy containers equally in multiple zones using
# # the deploy>preferences -spread:  node.labels.zone
# chmod +x start.sh
# . start.sh 2>&1 >> /start.log

# # runs the shutdown script if specified
# curl -fsSL https://s3.amazonaws.com/spotinst-public/services/agent/elastigroup-agent-init.sh | \
# SPOTINST_ACCOUNT_ID=${var.spotinst_account} \
# SPOTINST_TOKEN=${var.spotinst_token} \
# bash
# EOF

# # can be used to run processes before shutdown
# shutdown_script = <<EOF
# !/bin/sh
# sendmail -s "Spot instance shutting down" ${var.support_email} -a /var/log/cloud-init-output.log
# $NODE=$(docker node ls |grep '\*' | awk '{print $1'})
# docker node demote $NODE
# docker node rm $NODE
# EOF

#   tags {
#     key = "Name"

#     value = format("%s-swarm-masters", var.environment)
#   }

#   iam_instance_profile = aws_iam_instance_profile.swarm_ec2.name

#   health_check_type = "TARGET_GROUP"

#   health_check_grace_period = 300

#   health_check_unhealthy_duration_before_replacement = 120

#   placement_tenancy = "default"

#   #   preferred_availability_zones = ["us-east-2b", "us-east-2c"]

#   region = var.aws_region
# }

# resource "spotinst_elastigroup_aws" "stage-swarm-workers" {

#   depends_on = [aws_instance.first_swarm_master]
#   name       = format("%s-swarm-workers", var.environment)

#   description = "stage swarm project"

#   spot_percentage = 100

#   orientation = "balanced"

#   draining_timeout = 120

#   fallback_to_ondemand = true

#   lifetime_period = "days"

#   # if desiring persistent volumes
#   # persist_block_devices = true
#   # persist_private_ip = true
#   # block_devices_mode = "reattach"

#   persist_block_devices = false

#   persist_root_device = false
#   revert_to_spot {
#     perform_at = "always"
#   }

#   desired_capacity = var.worker_nodes_desired

#   min_size = var.worker_nodes_min_count

#   max_size = var.worker_nodes_max_count

#   capacity_unit = "instance"

#   instance_types_ondemand = "m5dn.large"

#   instance_types_spot = ["m5dn.large", "m5n.large", "m5n.xlarge", "m5dn.xlarge"]

#   instance_types_preferred_spot = ["m5dn.xlarge", "m5dn.large"]

#   subnet_ids = module.vpc.private_subnets

#   product = "Linux/UNIX"

#   # elastic_load_balancers = ["dev-swarm-ap", "dev-swarm-emailq", "dev-swarm-myvernon", "dev-swarm-oq", "dev-swarm-portainer", "dev-swarm-swarmpit"]

#   target_group_arns = aws_lb_target_group.project.*.arn

#   security_groups = [aws_security_group.swarm.id]

#   enable_monitoring = false

#   ebs_optimized = false

#   image_id = data.aws_ami.target_ami.id

#   key_name = var.aws_key_name

#   # used to run processes at start-up
#   user_data = <<EOF
# #!/bin/bash
# #download pem and start script
# export ENVIRONMENT=${var.environment}
# echo "export ENVIRONMENT=$ENVIRONMENT" >> /etc/profile.d/custom.sh
# export S3_PATH=${format("%s-%s-%s-scripts", var.domain, var.namespace, var.environment)}
# echo "export S3_PATH=S3_PATH" >> /etc/profile.d/custom.sh
# nohup aws s3 cp s3://$S3_PATH/swarm_workers.sh /start.sh &
# # may be added by default in amazon image
# export AWS_DEFAULT_REGION=${var.aws_region}
# echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> /etc/profile.d/custom.sh
# yum update -y -q
# yum install -y jq
# amazon-linux-extras install docker -y
# service docker start
# if [[ "${var.has_pem}" ]];then
#   nohup aws s3 cp s3://$S3_PATH/${var.aws_key_name}.pem /${var.aws_key_name}.pem
#   chmod 400 /${var.aws_key_name}.pem
# fi

# #docker login to pull private repositories if username and password secret identities are passed.
# DOCKER_USER=$(aws secretsmanager get-secret-value --secret-id ${var.docker_username} --query "SecretString" --output text)
# DOCKER_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${var.docker_password} --query "SecretString" --output text)
# if test "$DOCKER_USER" && test "$DOCKER_PASSWORD";then
#   docker login --username=$DOCKER_USER --password=$DOCKER_PASSWORD
# fi
# # make sure the first master is set up and has saved the join token to secrets
# sleep ${var.sleep_seconds}

# export SWARM_WORKER_TOKEN=${format("%s-swarm-worker-token2", var.environment)}
# TOKEN=$(aws secretsmanager get-secret-value --secret-id $SWARM_WORKER_TOKEN --query "SecretString" --output text)
# # echo "TOKEN=$TOKEN"

# docker swarm join --token $TOKEN

# # get the zone that the instances are running in and add to docker node's label
# # this allows you to deploy containers equally in multiple zones using
# # the deploy>preferences -spread:  node.labels.zone
# chmod +x start.sh
# . start.sh 2>&1 >> /start.log

# # runs the shutdown script if specified
# curl -fsSL https://s3.amazonaws.com/spotinst-public/services/agent/elastigroup-agent-init.sh | \
# SPOTINST_ACCOUNT_ID=${var.spotinst_account} \
# SPOTINST_TOKEN=${var.spotinst_token} \
# bash
# EOF

# # can be used to run processes before shutdown
# shutdown_script = <<EOF
# !/bin/sh
# sendmail -s "Spot instance shutting down" ${var.support_email} -a /var/log/cloud-init-output.log
# $NODE=$(docker node ls |grep '\*' | awk '{print $1'})
# docker node rm $NODE
# EOF

#   tags {
#     key = "Name"

#     value = format("%s-swarm-workers", var.environment)
#   }

#   iam_instance_profile = aws_iam_instance_profile.swarm_ec2.name

#   health_check_type = "TARGET_GROUP"

#   health_check_grace_period = 300

#   health_check_unhealthy_duration_before_replacement = 120

#   placement_tenancy = "default"

#   #   preferred_availability_zones = ["us-east-2b", "us-east-2c"]

#   region = var.aws_region
# }
