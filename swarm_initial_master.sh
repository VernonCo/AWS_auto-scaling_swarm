#/bin/sh
# import any necessary scripts in the background
mkdir ./scripts
aws s3 cp s3://$S3_PATH/$ENVIRONMENT-crontab.txt /crontab.txt
aws s3 cp s3://$S3_PATH/$ENVIRONMENT/ ./scripts/ --include "*" --recursive
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/swarmpit.yml ./
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/swarmpit.sh ./
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/ap.env ./
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/ap.yml ./
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/ap.sh ./
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/oq.yml ./
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/oq.sh ./
aws s3 cp s3://$S3_PATH/update_tokens.sh /update_tokens.sh
aws s3 cp s3://$S3_PATH/add_zone_label.sh /add_zone_label.sh

echo "set timezone to America/Chicago"
unlink /etc/localtime
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

sleep 2  # to allow scripts above to be downloaded

echo "set crontab and restart cron/rsyslog to catch TZ"
crontab /crontab.txt
# reset cron to use updated timezone
service crond restart
service rsyslog restart

#docker login to pull private repositories
docker login --username=vernondocker --password=Xht7pyLTnmdh
# create attachable network for the swarm
docker network create --driver=overlay --attachable net-$ENVIRONMENT

cd ./scripts
shopt -s extglob nullglob
for file in *; do
    chmod +x $file
    . $file
done
