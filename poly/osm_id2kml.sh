#!/usr/sh

set -e

IDS=$1

rm -f *.geojson
echo '{"type":"GeometryCollection","geometries":[' > $2.geojson
for ID in $IDS ; do
  curl "http://polygons.openstreetmap.fr/get_geojson.py?id=$ID&params=0.100000-0.010000-0.050000" >> $2.geojson
  echo -n "," >> $2.geojson
done
echo ']}' >> $2.geojson
sed -i "s/,]}/]}/" $2.geojson

# Convert ot KML
ogr2ogr -f "KML" $2.kml $2.geojson

rm *.geojson
