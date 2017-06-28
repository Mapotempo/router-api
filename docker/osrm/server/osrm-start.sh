#!/bin/sh

die() {
    echo $*
    exit 1
}

# Initialize environment for daemons.
for daemon in routed isochrone; do
    mkdir -p /etc/service/${daemon}/env
    echo ${PROFILE} > /etc/service/${daemon}/env/PROFILE
    echo ${REGION} > /etc/service/${daemon}/env/REGION
done

# Specific environment for Isochrone.
echo ${NODE_CONFIG} > /etc/service/isochrone/env/NODE_CONFIG

# Run datastore once with delay
osrm-load.sh ${PROFILE} ${REGION}

exec /usr/bin/runsvdir -P /etc/service
