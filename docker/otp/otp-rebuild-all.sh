#!/bin/sh
for i in ./data/graphs/*; do
  ./otp-rebuild.sh `basename $i`
done
