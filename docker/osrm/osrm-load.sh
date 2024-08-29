#!/bin/sh

die() {
    echo $*
    exit 1
}

BASENAME=$1

DATADIR=/srv/osrm/data
DATA_LINK=${DATADIR}/${BASENAME}-latest.osrm.timestamp
OSRM_FILE=$(/bin/readlink -e ${DATA_LINK})
OSRM_FILE=${OSRM_FILE%.timestamp}

[ $? -eq 1 ] && die "${OSRM_FILE} target not found."

echo "Loads ${OSRM_FILE}"
exec osrm-datastore ${OSRM_FILE}
