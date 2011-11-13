#!/bin/bash

# OpenLinkMap Copyright (C) 2010 Alexander Matheisen
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it under certain conditions.
# See openlinkmap.org for details.


# working directory, please change
cd /home/www/sites/194.245.35.149/site/import
PATH="$PATH:/home/www/sites/194.245.35.149/site/import/bin"
JAVACMD_OPTIONS=-Djava.io.tmpdir=/home/www/sites/194.245.35.149/site/
export JAVACMD_OPTIONS


# download planet file, ~ 8 hours
wget http://planet.openstreetmap.org/pbf-experimental/planet-latest.osm.pbf
mv planet-latest.osm.pbf old.pbf


# update planet file
date -u +%s > timestamp
osmupdate old.pbf new.pbf --max-merge=2 --hourly --drop-author -v
rm old.pbf
mv new.pbf old.pbf


# convert planet file, ~ 25 min
osmconvert old.pbf --drop-relations --out-o5m >temp.o5m


# filter planet file, ~ 35 min
osmfilter temp.o5m --keep="wikipedia= wikipedia:*= contact:phone= website= url= phone= fax= email= addr:email= image= url:official= contact:website= addr:phone= phone:mobile= contact:mobile= addr:fax= contact:email= contact:fax=" --out-o5m >temp-olm.o5m

osmfilter temp.o5m --keep="amenity=bus_station highway=bus_stop railway=station railway=halt railway=tram_stop amenity=parking" --out-o5m >temp-nextobjects.o5m
rm temp.o5m


# create centroids, remove not-node elements, ~ 2 min
osmconvert temp-olm.o5m --all-to-nodes --max-objects=50000000 --fake-lonlat --out-o5m >temp.o5m
rm temp-olm.o5m
osmfilter temp.o5m --drop-relations --drop-ways --keep-nodes="wikipedia= wikipedia:*= contact:phone= website= url= phone= fax= email= addr:email= image= url:official= contact:website= addr:phone= phone:mobile= contact:mobile= addr:fax= contact:email= contact:fax=" --fake-lonlat --out-osm >old-olm.osm
rm temp.o5m

osmconvert temp-nextobjects.o5m --all-to-nodes --max-objects=50000000 --fake-lonlat --out-o5m >temp.o5m
rm temp-nextobjects.o5m
osmfilter temp.o5m --drop-relations --drop-ways --keep-nodes="amenity=bus_station highway=bus_stop railway=station railway=halt railway=tram_stop amenity=parking" --fake-lonlat --out-osm >old-nextobjects.osm
rm temp.o5m


# import in database, ~ 20 min
php newolm-import.php
rm old-olm.osm
rm old-nextobjects.osm