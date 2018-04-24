#!/bin/sh

ROUTER=$1

DIR=$(dirname $0)

set -e

echo "Generate graph."
docker-compose --project-directory ${DIR}/../ --project-name router run --rm --entrypoint make otp-${ROUTER} -C /srv/otp/data/graphs/${ROUTER}/

echo "Wait 10 seconds before reloading graph."
sleep 10

echo "Reload graph."
PORT=$(docker inspect router_otp-${ROUTER}_1 | jq -r '.[0].NetworkSettings.Ports["7000/tcp"][0].HostPort')
curl -X PUT http://localhost:${PORT}/otp/routers/${ROUTER}
