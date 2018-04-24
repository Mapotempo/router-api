#!/bin/sh

DIR=$(dirname $0)

for i in ${DIR}/data/graphs/*; do
  ${DIR}/otp-rebuild.sh `basename $i`
done
