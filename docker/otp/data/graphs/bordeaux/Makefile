# http://data.bordeaux-metropole.fr/data.php?themes=10

all: reload

.phony: all clean reload

.FORCE:

/srv/otp/data/osm/europe/france-latest.osm.pbf:
	mkdir -p `dirname $@`
	wget http://download.geofabrik.de/europe/france-latest.osm.pbf --no-verbose -O $@

bordeaux-bus-gtfs.zip: .FORCE
	curl "http://data.bordeaux-metropole.fr/files.php?gid=68&format=14" -s -L -R -z $@ -o $@

bordeaux-tram-gtfs.zip: .FORCE
	curl "http://data.bordeaux-metropole.fr/files.php?gid=67&format=14" -s -L -R -z $@ -o $@

bordeaux_france.osm.pbf: /srv/otp/data/osm/europe/france-latest.osm.pbf
	osmosis --read-pbf $< --bounding-box top=45.065 left=-0.900 bottom=44.569 right=-0.162 --write-pbf $@

Graph.obj: bordeaux-bus-gtfs.zip bordeaux-tram-gtfs.zip bordeaux_france.osm.pbf
	java -jar ${OTP} --build .

reload: Graph.obj
	curl -X PUT http://otp-${GRAPH}:7000/otp/routers/${GRAPH}

clean:
	rm -f *.osm.pbf Graph.obj *.zip
