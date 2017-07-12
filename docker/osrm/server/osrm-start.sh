#!/bin/sh

die() {
    echo $*
    exit 1
}

[ -z "${BASENAME}" ] && die "BASENAME environment variable must be provided."

# Initialize environment for daemons.
for daemon in routed isochrone; do
    mkdir -p /etc/service/${daemon}/env
    echo ${BASENAME} > /etc/service/${daemon}/env/BASENAME
done

# Specific environment for Isochrone.
echo ${NODE_CONFIG} > /etc/service/isochrone/env/NODE_CONFIG

# Run datastore once with delay
osrm-load.sh ${BASENAME} || die "Impossible to load data."

exec /usr/bin/runsvdir -P /etc/service
