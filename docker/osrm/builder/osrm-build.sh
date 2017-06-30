#!/bin/bash

die() {
    echo $*
    exit 1
}

usage() {
    cat >&2 <<EOF
$*

Usage:
	$0 -p profile -r region [-a]

Arguments:
	-p profile	Profile name (car, bicycle, etc.)
	-r region	Full region name (europe, europe/france) or custom region name (dom)
	-a		Add locations to ways before OSRM data extract
EOF

    exit 1
}

# Build OSM file for DOM-TOMs
build_osm_dom_extended(){
    local region="dom"
    local workspace="${DATADIR}/${region}"
    local osm_file="${workspace}/${region}-${TIMESTAMP}.osm.pbf"
    local osm_latest="${workspace}/${region}-latest.osm.pbf"

    if [ -r ${osm_file} ]; then
        echo "OSM file for region DOM already exists."
        return
    fi

    local osm_old="$(readlink -e ${osm_latest})"

    echo "Building extended DOM OSM file."
    mkdir -p ${workspace}

    local extract_region_full

    # Get OSM files
    for extract_region_full in \
        europe/france/guadeloupe \
        europe/france/martinique \
        europe/france/guyane \
        europe/france/reunion \
        europe/france/mayotte \
        australia-oceania/new-caledonia
    do
        osm-manage.sh ${extract_region_full} || die "Impossible to get ${extract_region_full}."
    done

    # merge with osmosis
    echo "Merging OSM files using osmosis."
    #export JAVACMD_OPTIONS="-Djava.io.tmpdir=${DATADIR}/france/"
    export JAVACMD_OPTIONS="-Xms4G -Xmx8G -Djava.io.tmpdir=${workspace}"
    export OSMOSIS_OPTIONS="-v"
    osmosis \
        --read-pbf ${OSM_DATADIR}/europe/france/guadeloupe/guadeloupe-latest.osm.pbf \
        --read-pbf ${OSM_DATADIR}/europe/france/martinique/martinique-latest.osm.pbf \
        --read-pbf ${OSM_DATADIR}/europe/france/guyane/guyane-latest.osm.pbf \
        --read-pbf ${OSM_DATADIR}/europe/france/reunion/reunion-latest.osm.pbf \
        --read-pbf ${OSM_DATADIR}/europe/france/mayotte/mayotte-latest.osm.pbf \
        --read-pbf ${OSM_DATADIR}/australia-oceania/new-caledonia/new-caledonia-latest.osm.pbf \
        --merge --merge --merge --merge --merge \
        --buffer --write-pbf ${osm_file}

    if [ $? -ne 0 ]; then
        rm -f ${osm_file}
        die "Unable to merge regions."
    fi

    echo "Update link to latest DOM OSM file."
    ln -sf --relative ${osm_file} ${osm_latest}

    echo "Cleaning old DOM OSM data."
    rm -f ${osm_old}
}

build_osm_generic(){
    local REGION_FULL=$1
    local REGION=$(basename ${REGION_FULL})

    local OSM_ORIGIN=/srv/osm/${REGION_FULL}/${REGION}-${TIMESTAMP}.osm.pbf
    local OSM_LATEST=${DATADIR}/${REGION_FULL}/${REGION}-latest.osm.pbf

    if [ -r ${OSM_ORIGIN} ]; then
        echo "OSM file for region ${REGION} already exists."
        return
    fi

    local OSM_OLD=$(readlink -e ${OSM_LATEST})

    osm-manage.sh ${REGION_FULL} || die "Unable to manage OSM file for region ${REGION_FULL}."

    echo "Update link to latest ${REGION} OSM file (${OSM_LATEST} -> ${OSM_ORIGIN})."
    mkdir -p $(dirname ${OSM_LATEST})
    ln -sf --relative ${OSM_ORIGIN} ${OSM_LATEST}

    echo "Cleaning old OSM data for region ${REGION}."
    rm -f ${OSM_OLD}
}

build_osm(){
    local BUILD_OSM="build_osm_${REGION}_extended"

    if type -t ${BUILD_OSM} >/dev/null 2>&1; then
        ${BUILD_OSM}
    else
        #die "No OSM build function for region ${REGION}"
        echo "Call build_osm_generic for region \"${REGION_FULL}\"."
        build_osm_generic ${REGION_FULL}
    fi
}

# Cleanup OSRM data if not related to the one we will build.
cleanup_osrm() {
    local osrm=$1
    local target=$(readlink -e ${osrm})

    if [ -n "${target}" -a ! "${target}" -ef "${OSRM_FILE}" ]; then
        echo "Cleaning OSRM files: ${target}*"
        rm -vf ${target}*

        rm -vf ${osrm}
    fi
}

prepare_locations(){
    local OSM_WITH_LOCATIONS=${DATADIR}/${REGION_FULL}/${REGION}-${TIMESTAMP}-locations.osm.pbf
    local OSM_LATEST=${DATADIR}/${REGION_FULL}/${REGION}-latest.osm.pbf

    if [ ! -r ${OSM_WITH_LOCATIONS} ]; then
        echo "Add locations to ways using Osmium on ${OSM_LATEST}, writing to ${OSM_WITH_LOCATIONS}."
        osmium add-locations-to-ways \
            --verbose \
            --keep-untagged-nodes \
            --ignore-missing-nodes \
            -F pbf -f pbf \
            -o ${OSM_WITH_LOCATIONS} -O ${OSM_LATEST} || die "Unable to add locations to ways on OSM file."
    else
        echo "OSM with locations already exists."
    fi

    echo "Update link to OSM file with locations."
    ln -sf --relative ${OSM_WITH_LOCATIONS} ${OSM_LATEST}
}

# Build OSRM data.
build_osrm(){
    cleanup_osrm ${OSRM_LATEST}

    if [ "${ADD_LOCATIONS}" -eq 1 ]; then
        prepare_locations
    fi

    # Create link for OSRM file generation.
    echo "Link to OSM latest: ${OSM_PROFILE_FILE} -> ${OSM_LATEST}"
    ln -sf --relative $(readlink -m ${OSM_LATEST}) ${OSM_PROFILE_FILE}

    if [ ! -r ${OSRM_FILE} ]; then
        echo "Extracting OSRM data for region ${REGION} using profile ${PROFILE}."
        /usr/bin/osrm-extract -p ${PROFILE_PATH} --with-osm-metadata ${OSM_PROFILE_FILE} \
            || die "Unable to extract data."
    else
        echo "Skipping OSRM data extraction because .osrm file exists."
    fi

    if [ ! -r ${OSRM_FILE}.core ]; then
        echo "Preparing OSRM data for region ${REGION} using profile ${PROFILE}."
        OSRM_CONTRACT="/usr/bin/osrm-contract"

        /usr/bin/osrm-contract ${OSRM_FILE} || die "Unable to prepare data."
    else
        echo "Skipping OSRM data preparation because .osrm.core file exists."
    fi

    # Create a link to the latest OSRM for the next start
    echo "Linking latest OSRM to ${OSRM_FILE}."
    ln -sf --relative ${OSRM_FILE} ${OSRM_LATEST}
}

# Global common variables
DATADIR=/srv/osrm/data
OSM_DATADIR=/srv/osm

TIMESTAMP=$(date +%Y%m%d)

# Command line argument parsing

ADD_LOCATIONS=0

while getopts "p:r:a" option
do
    case $option in
        p)
            PROFILE=${OPTARG}
            ;;
        r)
            REGION_FULL=${OPTARG}
            ;;
        a)
            ADD_LOCATIONS=1
            ;;
        :)
            usage "Option -${OPTARG} needs a value."
            ;;
        \?)
            usage "Invalid option: -${OPTARG}."
            ;;
        *)
            usage
            ;;
      esac
done

shift $((OPTIND-1))

[ -z "${PROFILE}" ] && usage "Profile must be provided."
[ -z "${REGION_FULL}" ] && usage "Region must be provided."

REGION=$(basename ${REGION_FULL})

# Fetch latest OSM data.
build_osm

PROFILE_PATH=/srv/osrm/profiles/profile-${PROFILE}.lua

OSM_LATEST=${DATADIR}/${REGION_FULL}/${REGION}-latest.osm.pbf
OSM_PROFILE_FILE=${DATADIR}/${REGION}-${PROFILE}-${TIMESTAMP}.osm.pbf

OSRM_FILE=${DATADIR}/${REGION}-${PROFILE}-${TIMESTAMP}.osrm
OSRM_LATEST=${DATADIR}/${REGION}-${PROFILE}-latest.osrm
OSRM_OLD=$(readlink -e ${OSRM_LATEST})


# Build OSRM files
build_osrm

# Unset to force cleanup.
unset OSRM_FILE
#cleanup_osrm ${OSRM_LATEST}

# Cleanup OSM link
rm -vf ${OSM_PROFILE_FILE}
