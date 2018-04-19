#!/bin/sh
for i in ./data/graphs/*; do
  make -C $i clean
done
