# Auto-scaling Swarm on AWS

## This is Used With the Following Folder Structure.

-  /
-    /aws- _region_
-      /dev                (git clone https://github.com/venonco/aws-auto-scaling-swarm)
-      /prod
-    /modules
-      /terraform-aws-vpc  (git clone https://github.com/terraform-aws-modules/terraform-aws-vpc.git)

## Uses Terraform 0.12
Variables are not quoted, and code is not backwards compatible with 0.11

## Useage
### State Storage
Recomend setting up a tf state on aws S3 and dynamodb (Otherwise, remove tf-state.tf to store locally).  External storage on AWS allows multiple developers to use the same code and lock others out while running apply to prevent mangled configurations.
#### Create S3 Bucket and Dynamodb Table for TF State
Add a region/dev/state/terraform.tfvars to override variables.  Then in region/dev/state run:
  `terraform init`
  `terraform apply`
It will create an S3 bucket and a global dynamodb lock table with replications in 2 regions of your choice.  You can easily change it to have only one replication or as many as you like.
#### Create tf-state.tf in Environment Folder for Environment State Storage
Dev has file already to be edited. Otherwise, you can copy the example in dev/state/backend-example to edit.
  `cp backend-example/tf-state.tf path_to_environment_folder/`
cd to region/dev and rerun `terraform init` to use the new bucket and lock table. You should see
  'Successfully configured the backend "s3"! Terraform will automatically use this backend unless the backend configuration changes.'
### Configure Variables for Your Use.
Create a region/dev/terraform.tfvars which will automatically be imported by terraform to override desired variables in variables.tf  Number of nodes, instance sizes, etc. are all configurable.
### Apply the Resources
Do `terraform init` in region/dev/ and then run `terraform apply`.  It will show you what resources will be created but will not create them unless you specifically type in 'yes' and hit enter.  If you hit enter with anything else, the apply will be canceled.
## What it Can Do
aws-auto-scaling-swarm can create the resources needed to run a swarm on AWS including a application load balancer (alb) with target groups you specify that would target ports on the swarm for web resources. Some of the resources are:
  - VPC
  - Security groups
  - route tables
  - private and public subnets in each zone
  - alb
  - target groups
  - initial master using on-demand instance
  - auto scaling groups (masters, workers)
  - auto scaling configs (masters, workers) using spot instances
  - auto scaling policies based on cpu ( you can add based on free memory)
### Initial Swarm Master
An initial on-demand (if reserved is desired, change in main.tf) swarm master is created to begin the process. It sets up swarm tokens and runs stacks.  It also has an public IP to access it from the allowed IP.
#### Cron Jobs, Scripts & Stacks
This swarm master can download scripts & stacks and a crontab.txt to run cronjobs from a S3 bucket (see the user_data in main.tf for the initial master and swarm_initial_master.sh) There is a sleep time while the intial swarm master waits for the other nodes to come up before creating the stacks.

Structure for the S3 bucket:
 - /namespace/environment   _environment_-crontab.txt, update_tokens.sh, add_zone_label.sh(for swarmpit)
  -   /dev  bash scripts (ie. example-script.sh)
  -      /stacks  yml files  (ie. example.yml)
  -   /prod
  -  .....
Example scripts install swarmpit.

If S3 scripts are not used, you can still ssh into the initial master to copy/create scripts and stacks to run.
#### AWS Secret Manager for Swarm Token
The initial swarm master will create swarm tokens and save them to the AWS secrets manager for the other nodes to retrieve.
### Swarm Master Nodes
You can set the number of swarm master nodes running on spot instances (if on-demand or reserved is desired, change in main.tf). (recommend even numbers to go with the initial master for an odd number of masters. ie. 2 masters + initial master = 3 masters).  They are started on an auto-scaling group and retrieve their swarm token from the AWS secrets manager.  In case of an auto-scaling later, you may need to manually manage container dispersion (https://docs.docker.com/engine/swarm/admin_guide/#force-the-swarm-to-rebalance).

When they start up with the terrafrom apply, any scripts to load stacks that are ran on the initial master should apply to these masters.
### Swarm Worker Nodes
You can set the desired number of swarm worker nodes running on spot instances (if on-demand or reserved is desired, change in main.tf). They are started on an auto-scaling group and retrieve their swarm token from the AWS secrets manager.  In case of an auto-scaling later, you may need to manually manage container dispersion (https://docs.docker.com/engine/swarm/admin_guide/#force-the-swarm-to-rebalance).

When they start up with the terrafrom apply, any scripts to load stacks that are ran on the initial master should apply to these workers.
### Multiple Target Groups, Multiple Domains, Multiple SSL Certificates
target_groups and ssl_arns variables allow you to set multiple targets and domains. See the variables in variables.tf and alb.tf
### Peering Connection to Default VPC
Can enable a peering connection to the default VPC to be able to connect to resources on the default VPC.  Does not take much to enable a cross region peering connection if needed (see commented out section of peering_vpc.tf).
