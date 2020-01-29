#/bin/sh

# import any necessary scripts
nohup aws s3 cp s3://$S3_PATH/update_tokens.sh /update_tokens.sh &
aws s3 cp s3://$S3_PATH/add_zone_label.sh ./add_zone_label.sh

echo "set timezone to America/Chicago"
unlink /etc/localtime
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

#sleep 2  # to allow scripts above to be downloaded

# echo "run scripts"
sudo bash ./add_zone_label.sh
