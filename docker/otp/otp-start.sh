#!/bin/bash

DATA=/srv/otp/data

ROUTING=$(for c in ${DATA}/graphs/*; do echo " --router $(realpath --relative-to=${DATA}/graphs $c)"; done)

exec /usr/bin/logger -t ${OTP} --server ${LOGGER_SERVER} --port ${LOGGER_PORT}
exec java -Xmx6G -jar ${OTP} --basePath ${DATA} --analyst --server --port 7000 --insecure ${ROUTING}
