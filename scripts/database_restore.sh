#!/bin/bash

## Restore a KEYSPACE and its data from a CQL file with the schema of the
## KEYSPACE and an tbz archive containing the snapshot.

## Works with cassandra docker container, should be run from host

## Complete variables before running:
## IP: IP of cassandra server
## TMP: choose a TMP folder !!! this folder will be removed if exists.
## SOURCE_KEYSPACE: KEYSPACE used in the backup
## TARGET_KEYSPACE: new KEYSPACE name ; use same name of SOURCE_KEYSPACE if no changes
## SNAPSHOT: choose a name for the backup
## SNAPSHOT_INDEX: index of the snapshot (1, 20210401 ...)

IP=127.0.0.1 # check in /etc/cassandra/cassandra.yaml
TMP=/tmp/cassandra
SOURCE_KEYSPACE="thehive"
TARGET_KEYSPACE="thehive"
SNAPSHOT_PATH=""
SNAPSHOT=""
SNAPSHOT_INDEX="1"
DOCKER_CONTAINER=cassandra
CASSANDRA_PASSWORD=""
CASSANDRA_USER=""

if [ -z "$SNAPSHOT" ]
then
  echo "Need to provide SNAPSHOT."
  echo "Note the formatting of the SNAPSHOT variable - filename without path and extension."
  echo "Exiting."
  exit 1
fi

## Uncompress data in TMP folder
rm -rf ${TMP} && mkdir ${TMP}
tar jxf "${SNAPSHOT_PATH}""${SNAPSHOT}"_${SNAPSHOT_INDEX}.tbz -C ${TMP}

#exit

## Read Cassandra password
#echo -n "Cassandra admin password: "
#read -s CASSANDRA_PASSWORD

## Restore keyspace
docker cp schema_"${SNAPSHOT}"_${SNAPSHOT_INDEX}.cql ${DOCKER_CONTAINER}:/tmp/
docker exec -u 0 -i $DOCKER_CONTAINER cqlsh -u "${CASSANDRA_USER}" -p "${CASSANDRA_PASSWORD}" --file /tmp/schema_"${SNAPSHOT}"_${SNAPSHOT_INDEX}.cql

## Restore data
for TABLE in $(docker exec -u 0 -i $DOCKER_CONTAINER cqlsh -u "${CASSANDRA_USER}" -p "${CASSANDRA_PASSWORD}" -e "use ${TARGET_KEYSPACE}; DESC tables ;")
do
  for FILE in $(ls ${TMP}/var/lib/cassandra/data/${SOURCE_KEYSPACE}/"${TABLE}"-*/snapshots/"${SNAPSHOT}"_${SNAPSHOT_INDEX}/)
  do
    docker cp $FILE cassandra:/var/lib/cassandra/data/${TARGET_KEYSPACE}/"$TABLE"-*/
  done
done

## Change ownership
#chown -R cassandra:cassandra /var/lib/cassandra/data/${TARGET_KEYSPACE}


## sstableloader
for TABLE in $(docker exec -u 0 -i $DOCKER_CONTAINER ls /var/lib/cassandra/data/${TARGET_KEYSPACE})
do
    docker exec -u 0 -i $DOCKER_CONTAINER sh -c "sstableloader -d "${IP}" /var/lib/cassandra/data/${TARGET_KEYSPACE}/${TABLE}"
done
