#!/bin/bash

## Restore a KEYSPACE and its data from a CQL file with the schema of the
## KEYSPACE and an tbz archive containing the snapshot

## Complete variables before running:
## IP: IP of cassandra server
## TMP: choose a TMP folder !!! this folder will be removed if exists.
## SOURCE_KEYSPACE: KEYSPACE used in the backup
## TARGET_KEYSPACE: new KEYSPACE name ; use same name of SOURCE_KEYSPACE if no changes
## SNAPSHOT: choose a name for the backup
## SNAPSHOT_INDEX: index of the snapshot (1, 20210401 ...)

#IP=127.0.0.1
TMP=/tmp/cassandra
#BACKUP_FOLDER=/opt/backups/cassandra
SOURCE_KEYSPACE="thehive"
TARGET_KEYSPACE="thehive"
SNAPSHOT=""
SNAPSHOT_INDEX="1"
DOCKER_CONTAINER=cassandra

## Uncompress data in TMP folder
rm -rf ${TMP} && mkdir ${TMP}
tar jxf "${SNAPSHOT}"_${SNAPSHOT_INDEX}.tbz -C ${TMP}

## Read Cassandra password
#echo -n "Cassandra admin password: "
#read -s CASSANDRA_PASSWORD

## Define new KEYSPACE NAME
#sed -i "s/${SOURCE_KEYSPACE}/${TARGET_KEYSPACE}/g" schema_${SNAPSHOT}_${SNAPSHOT_INDEX}.cql

## Restore keyspace
docker exec -u 0 -it $DOCKER_CONTAINER cqlsh -u cassandra -p "${CASSANDRA_PASSWORD}" cassandra --file schema_"${SNAPSHOT}"_${SNAPSHOT_INDEX}.cql

## Restore data
for TABLE in $(cqlsh -u cassandra -p "${CASSANDRA_PASSWORD}" -e "use ${TARGET_KEYSPACE}; DESC tables ;")
do
docker cp ${TMP}/var/lib/cassandra/data/${SOURCE_KEYSPACE}/"${TABLE}"-*/snapshots/"${SNAPSHOT}"_${SNAPSHOT_INDEX}/* cassandra:/var/lib/cassandra/data/${TARGET_KEYSPACE}/"$TABLE"-*/
done

## Change ownership
#chown -R cassandra:cassandra /var/lib/cassandra/data/${TARGET_KEYSPACE}


## sstableloader
for TABLE in $(docker exec -u 0 -it $DOCKER_CONTAINER ls /var/lib/cassandra/data/${TARGET_KEYSPACE})
do
    docker exec -u 0 -it $DOCKER_CONTAINER sstableloader /var/lib/cassandra/data/${TARGET_KEYSPACE}/"${TABLE}"
done
