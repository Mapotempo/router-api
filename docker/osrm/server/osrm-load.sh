#!/bin/sh

die() {
    echo $*
    exit 1
}

PROFILE=$1
REGION=$2

DATADIR=/srv/osrm/data
DATA_LINK=${DATADIR}/${REGION}-${PROFILE}-latest.osrm
OSRM_FILE=$(/bin/readlink -e ${DATA_LINK})

[ $? -eq 1 ] && die "${DATA_LINK} target not found."

exec /usr/bin/osrm-datastore ${OSRM_FILE}
