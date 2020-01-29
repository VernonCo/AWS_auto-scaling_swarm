#!/bin/bash
> server.txt
docker node ls -q | xargs docker node inspect -f '{{ .Description.Hostname }}' | xargs -I"SERVER" sh -c "echo SERVER >> server.txt"
SERVERS=($(<server.txt))
for i in "${SERVERS[@]}"
do
	ZONE=$(ssh -i /swarm.pem -oStrictHostKeyChecking=no ec2-user@$i 'curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .availabilityZone')
	echo $ZONE
	docker node update --label-add zone=$ZONE $i
done
