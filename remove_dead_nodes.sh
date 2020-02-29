#!/bin/sh
# to be used on a swarm with spot instances

# The swarm will stall on the raft consensus if more than 51% of masters are lost.
# https://docs.docker.com/engine/swarm/raft/
# If 3 masters, one can be lost. If 5, then 3 can be lost.
# A master can go down and another come up on the spot instances. If enough changes are made,
# the down masters will reach a critical percentage if they are not removed.
# "the system cannot process any more requests to schedule additional tasks. The existing tasks
# keep running but the scheduler cannot rebalance tasks to cope with failures if the manager set is not healthy."
# If the consensus is lost, you can run `docker swarm init --force-new-cluster to restart the cluster.
# To reconnect the remaining masters you will need the run the docker swarm join with the master token
# https://docs.docker.com/engine/swarm/admin_guide/

# Meanwhile, it is the intention of this script to help prevent that. It cycles through a quick check
# every 15 seconds and disconnects lost nodes.

while true
do
    #get all masters that are unreachable and remove
    deadList=$(docker node ls | grep Unreachable | awk '{print $1}')
    for dead in $deadList
    do
        docker node demote $dead
        docker node rm --force $dead
    done

    #get all unsucessful or down connections and remove
    deadList=$(docker node ls | egrep 'Unknown|Down' | awk '{print $1}')
    for dead in $deadList
    do
        docker node rm --force $dead
    done

    sleep 15
done
