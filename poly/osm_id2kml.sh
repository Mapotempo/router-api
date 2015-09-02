#!/usr/sh

IDS=$1

rm *.geojson
for ID in $IDS ; do
  wget "http://polygons.openstreetmap.fr/?id=$ID&params=0" -O /dev/null # Call the generator
  wget "http://polygons.openstreetmap.fr/get_geojson.py?id=$ID&params=0" -O $ID.geojson
done

# Merge geojson
cat *.geojson | \
  sed -e 's/^{"type":"GeometryCollection","geometries":\[{"type":"MultiPolygon","coordinates":\[//' -e 's/]}]}$/,/' >> $2.tmp
echo '{"type":"GeometryCollection","geometries":[{"type":"MultiPolygon","coordinates":[' > $2.geojson
cat $2.tmp | tr -d '\n' | sed -e 's/,$//' >> $2.geojson
echo ']}]}' >> $2.geojson

# Convert ot KML
ogr2ogr -f "KML" -lco COORDINATE_PRECISION=7 $2.kml $2.geojson

rm *.geojson $2.tmp
