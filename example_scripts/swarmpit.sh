#/bin/sh

#label the swarm master-1 to be able to run swarmpit only in that instance
export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
docker node update --label-add swarmpit.db-data=true $NODE_ID

docker stack deploy -c ./stacks/swarmpit.yml swarmpit
