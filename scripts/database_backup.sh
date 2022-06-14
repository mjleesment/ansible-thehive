#!/bin/bash

## Create a CQL file with the schema of the KEYSPACE
## and an tbz archive containing the snapshot

## Complete variables before running:
## KEYSPACE: Identify the right keyspace to save in cassandra
## SNAPSHOT: choose a name for the backup

#IP=127.0.0.1
DOCKER_CONTAINER=cassandra
SOURCE_KEYSPACE=thehive
SNAPSHOT=thehive_cassandra_backup_$(date ++%Y%m%d%H%M%S)
SNAPSHOT_INDEX=1
CASSANDRA_PASSWORD=""
BACKUP_PATH=/opt/backups/cassandra

# Backup Cassandra

docker exec -u 0 -i $DOCKER_CONTAINER nodetool cleanup ${SOURCE_KEYSPACE}

docker exec -u 0 -i $DOCKER_CONTAINER nodetool snapshot ${SOURCE_KEYSPACE}  -t "${SNAPSHOT}"_${SNAPSHOT_INDEX}

#echo -n "Cassandra admin password":
#read -s CASSANDRA_PASSWORD

## Save schema
#cqlsh -u cassandra -p ${CASSANDRA_PASSWORD} ${IP} -e "DESCRIBE KEYSPACE ${SOURCE_KEYSPACE}" > schema_${SNAPSHOT}_${SNAPSHOT_INDEX}.cql
docker exec -u 0 -i $DOCKER_CONTAINER cqlsh -u cassandra -p "${CASSANDRA_PASSWORD}" -e "DESCRIBE KEYSPACE ${SOURCE_KEYSPACE}" > ${BACKUP_PATH}/schema_"${SNAPSHOT}"_${SNAPSHOT_INDEX}.cql

## Create archive
lastcommand=$?
if [[ $lastcommand == 0 ]]
then
  docker exec -u 0 -i ${DOCKER_CONTAINER} sh -c "tar cjf /tmp/${SNAPSHOT}_${SNAPSHOT_INDEX}.tbz /var/lib/cassandra/data/${SOURCE_KEYSPACE}/*/snapshots/${SNAPSHOT}_${SNAPSHOT_INDEX}/"
  docker cp ${DOCKER_CONTAINER}:/tmp/"${SNAPSHOT}"_${SNAPSHOT_INDEX}.tbz ${BACKUP_PATH}/
  docker exec -u 0 -i ${DOCKER_CONTAINER} rm /tmp/"${SNAPSHOT}"_${SNAPSHOT_INDEX}.tbz
fi
