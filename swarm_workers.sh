#/bin/sh

# import any necessary scripts
aws s3 cp s3://$S3_PATH/add_zone_label.sh ./add_zone_label.sh

# echo "set timezone to America/Chicago"
unlink /etc/localtime
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

# echo "run scripts"
bash ./add_zone_label.sh

# cloudstor plugin allows persistent volumes on AWS and Azure
# see swarm_initial_master.sh for limitations and alternatives
# docker plugin install --alias cloudstor:aws --grant-all-permissions docker4x/cloudstor:18.03.0-ce-aws1 CLOUD_PLATFORM=AWS AWS_REGION=$AWS_DEFAULT_REGION EFS_SUPPORTED=0 DEBUG=1
