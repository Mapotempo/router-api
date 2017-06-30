#!/bin/bash

# Ansible managed: Don't modify this file here because your changes will be erased by ansible.

# Constants
OSM_BASE_DIR="/srv/osm"
GEOFABRIK_URL="http://download.geofabrik.de"
OSM_FR_URL="http://download.openstreetmap.fr/extracts"
TIMESTAMP="$(date +%Y%m%d)"

# Parameters
PROGRAM="$0"
REGION_FULL="$1"
REGION="$(basename ${REGION_FULL})"

# Global variables derived from parameters.
WORKSPACE="${OSM_BASE_DIR}/${REGION_FULL}"
OSM_FILE="${WORKSPACE}/${REGION}-${TIMESTAMP}.osm.pbf"
OSM_LATEST="${WORKSPACE}/${REGION}-latest.osm.pbf"
OSM_OLD="$(readlink -e ${OSM_LATEST})"

export JAVACMD_OPTIONS="-server -Xms4G -Xmx8G -Djava.io.tmpdir=/tmp/"
export OSMOSIS_OPTIONS="-v"

# Usage function.
usage() {
    cat <<EOF
Usage:
    ${PROGRAM} region timestamp

    region: Full region name (europe, or europe/france)
EOF

    exit 1
}

# Die function
die() {
    echo $*
    exit 1
}

# Initialize an Osmosis workspace for a region, in a specific directory if
# passed as parameter, or a one based on ${WORKSPACE} and region if not
# passed.
init_workspace() {
    # Ensure directory exists.
    echo "Initializing Osmosis workspace for region ${REGION}."
    mkdir -p ${WORKSPACE}

    local configuration=${WORKSPACE}/configuration.txt

    # Initialize workspace.
    if [ ! -r ${configuration} ]; then
        osmosis --read-replication-interval-init workingDirectory=${WORKSPACE}
    fi

    # Set configuration.txt.
    echo "Updating configuration file."
    cat >${configuration} <<EOF
# The URL of the directory containing change files.
baseUrl=http://download.geofabrik.de/${REGION_FULL}-updates/

# Defines the maximum time interval in seconds to download in a single invocation.
# Setting to 0 disables this feature.
# 2 days
maxInterval=172800

EOF
}

# Download OSM and state files from Geofabrik.
download_geofabrik() {
    local state_file=${WORKSPACE}/state.txt

    local osm_url=${GEOFABRIK_URL}/${REGION_FULL}-latest.osm.pbf
    local state_url=${GEOFABRIK_URL}/${REGION_FULL}-updates/state.txt

    init_workspace

    # and download data.
    echo "Downloading OSM file from Geofabrik for region ${REGION}."
    wget -q ${osm_url} -O ${OSM_FILE}
    [ $? -ne 0 ] && die "Unable to download OSM file for region ${REGION}."

    echo "Downloading state file for region ${REGION}."
    wget -q ${state_url} -O ${state_file}
    [ $? -ne 0 ] && die "Unable to download state file for region ${REGION}."
}

# Update OSM file using Osmosis.
update_osmosis() {
    local osc_file=${WORKSPACE}/${REGION}.osc.gz

    echo "Fetching updates for region ${REGION} using Osmosis."
    osmosis --read-replication-interval \
        workingDirectory=${WORKSPACE} \
        --simplify-change --sort-change \
        --write-xml-change ${osc_file}

    if [ $? -eq 0 ]; then
        echo "Applying updates to OSM file for region ${REGION} using Osmosis."
        osmosis --read-xml-change ${osc_file} \
            --read-pbf ${OSM_LATEST} \
            --apply-change \
            --write-pbf ${OSM_FILE}
        [ $? -ne 0 ] && die "Unable to apply diff for region ${REGION}."
    else
        echo "Unable to get diff for region ${REGION}, clean up ${WORKSPACE} and download full data."
        rm -f ${osc_file}
        rm -f ${OSRM_LATEST}
        rm -f ${OSM_OLD}
        rm -f ${OSRM_FILE}

        download_geofabrik
    fi
}

download_osm_fr() {
    local osm_url=${OSM_FR_URL}/${REGION_FULL}-latest.osm.pbf

    mkdir -p ${WORKSPACE}

    echo "Download OSM extract from OpenStreetMap France."
    wget -q ${osm_url} -O ${OSM_FILE}
    [ $? -ne 0 ] && die "Unable to download OSM file extract for region ${REGION}."
}

manage_geofabrik() {
    if [ -z "${OSM_OLD}" ]; then
        echo "Old OSM file for region ${REGION} is absent."
        # OSM file absent, download it from Geofabrik.
        download_geofabrik
    else
        echo "Old OSM file for region ${REGION} found: ${OSM_OLD}"
        # OSM file present, updating it.
        update_osmosis
    fi
}

manage_osm_fr() {
    download_osm_fr
}

# Cleanup old OSM data if it is not the same as the current one.
cleanup() {
    if [ -n "${OSM_OLD}" -a ! "${OSM_OLD}" -ef "${OSM_FILE}" ]; then
        echo "Cleanup old OSM file for region ${REGION}."
        rm -f ${OSM_OLD}
    fi
}

# Initialize or update OSM file for region.

if [ -r "${OSM_FILE}" ]; then
    echo "OSM file for region ${REGION} already exists."
    exit 0
fi

echo "Check if region ${REGION_FULL} is managed by Geofabrik."
curl -sI ${GEOFABRIK_URL}/${REGION_FULL}-updates/ | head -n 1 | grep -q '^HTTP/1.1 200 OK'
if [ $? -eq 0 ]; then
    manage_geofabrik
else
    manage_osm_fr
fi

echo "Update link for latest OSM file to ${OSM_FILE}."
ln -sf --relative ${OSM_FILE} ${OSM_LATEST}

cleanup

