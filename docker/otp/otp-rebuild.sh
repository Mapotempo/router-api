#!/bin/sh

ROUTER=$1

DIR=$(dirname $0)

set -e

echo "Generate graph."
docker-compose --project-directory ${DIR}/../ --project-name router run --rm --entrypoint make otp-${ROUTER} -C /srv/otp/data/graphs/${ROUTER}/
