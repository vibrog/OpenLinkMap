#!/bin/bash

# OpenLinkMap Copyright (C) 2010 Alexander Matheisen
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it under certain conditions.
# See openlinkmap.org for details.


# set up database, ~ 5 min
sudo su - postgres
# working directory, please change
cd /home/alexander/Projekte/OLM/olm7/import
PATH="$PATH:/home/alexander/Projekte/OLM/olm7/import/bin"
createuser olm

createdb -E UTF8 -O olm olm
createlang plpgsql olm

psql -d olm -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
psql -d olm -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql

echo "CREATE EXTENSION hstore;" | psql -d olm
echo "ALTER TABLE geometry_columns OWNER TO olm; ALTER TABLE spatial_ref_sys OWNER TO olm;" | psql -d olm
echo "ALTER TABLE geography_columns OWNER TO olm;" | psql -d olm


createdb -E UTF8 -O olm nextobjects
createlang plpgsql nextobjects

psql -d nextobjects -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
psql -d nextobjects -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql

echo "CREATE EXTENSION hstore;" | psql -d nextobjects
echo "ALTER TABLE geometry_columns OWNER TO olm; ALTER TABLE spatial_ref_sys OWNER TO olm;"  | psql -d nextobjects
echo "ALTER TABLE geography_columns OWNER TO olm;"  | psql -d nextobjects

# download planet file, ~ 8 hours
wget -O - http://planet.openstreetmap.org/pbf-experimental/planet-latest.osm.pbf | osmconvert - --out-o5m >old.o5m

# update planet file
date -u +%s > timestamp
osmupdate old.o5m new.o5m --max-merge=14 --drop-author -v
rm old.o5m
mv new.o5m old.o5m

# filter planet file, ~ 30 min
osmfilter old.o5m --fake-lonlat --keep="wikipedia= wikipedia:*= contact:phone= website= url= phone= fax= email= addr:email= image= url:official= contact:website= addr:phone= phone:mobile= contact:mobile= addr:fax= contact:email= contact:fax=" --drop-author --out-o5m >old-olm.o5m
osmfilter old.o5m --fake-lonlat --keep="amenity=bus_station highway=bus_stop railway=station railway=halt railway=tram_stop amenity=parking" --drop-author --out-o5m >old-nextobjects.o5m

# convert to .osm, ~ 5 min
osmfilter old-olm.o5m --fake-lonlat  >install-olm.osm
osmfilter old-nextobjects.o5m --fake-lonlat  >install-nextobjects.osm

# initial import of database, ~ 60 min
osm2pgsql --create --hstore --database olm --prefix olm --style olm.style --cache 2096 --slim install-olm.osm
osm2pgsql --create --hstore --database nextobjects --prefix nextobjects --style olm.style --cache 2096 --slim install-nextobjects.osm
rm install-olm.osm
rm install-nextobjects.osm

# generate csv files of database, ~ 1 min
psql -d olm -c "COPY (SELECT foo.osmid AS osmid, foo.tags AS tags, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM (SELECT osm_id AS osmid, tags AS tags, ST_Transform(way, 4326) AS geom FROM olm_point WHERE ((tags ? 'wikipedia') OR (tags ? 'phone') OR (tags ? 'addr:phone') OR (tags ? 'contact:phone') OR (tags ? 'phone:mobile') OR (tags ? 'contact:mobile') OR (tags ? 'fax') OR (tags ? 'addr:fax') OR (tags ? 'contact:fax') OR (tags ? 'image') OR (tags ? 'email') OR (tags ? 'addr:email') OR (tags ? 'contact:email') OR (tags ? 'website') OR (tags ? 'contact:website') OR (tags ? 'url') OR (tags ? 'url:official') OR EXISTS(SELECT skeys FROM skeys(tags) WHERE skeys LIKE 'wikipedia:%')) AND ST_IsValid(way)) AS foo) TO STDOUT WITH DELIMITER ';';" > olm-nodes.csv

# generate csv files of database, ~ 10 min
psql -d olm -c "COPY (SELECT foo.osmid AS osmid, foo.tags AS tags, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM (SELECT osm_id AS osmid, tags AS tags, ST_Transform(ST_Centroid(way), 4326) AS geom FROM olm_polygon WHERE ((tags ? 'wikipedia') OR (tags ? 'phone') OR (tags ? 'addr:phone') OR (tags ? 'contact:phone') OR (tags ? 'phone:mobile') OR (tags ? 'contact:mobile') OR (tags ? 'fax') OR (tags ? 'addr:fax') OR (tags ? 'contact:fax') OR (tags ? 'image') OR (tags ? 'email') OR (tags ? 'addr:email') OR (tags ? 'contact:email') OR (tags ? 'website') OR (tags ? 'contact:website') OR (tags ? 'url') OR (tags ? 'url:official') OR EXISTS(SELECT skeys FROM skeys(tags) WHERE skeys LIKE 'wikipedia:%')) AND ST_IsValid(way)) AS foo) TO STDOUT WITH DELIMITER ';';" > olm-ways.csv

# generate csv files of database, ~ 2 min
psql -d olm -c "COPY (SELECT foo.osmid AS osmid, foo.tags AS tags, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM (SELECT osm_id AS osmid, tags AS tags, ST_Transform(ST_Centroid(way), 4326) AS geom FROM olm_line WHERE ((tags ? 'wikipedia') OR (tags ? 'phone') OR (tags ? 'addr:phone') OR (tags ? 'contact:phone') OR (tags ? 'phone:mobile') OR (tags ? 'contact:mobile') OR (tags ? 'fax') OR (tags ? 'addr:fax') OR (tags ? 'contact:fax') OR (tags ? 'image') OR (tags ? 'email') OR (tags ? 'addr:email') OR (tags ? 'contact:email') OR (tags ? 'website') OR (tags ? 'contact:website') OR (tags ? 'url') OR (tags ? 'url:official') OR EXISTS(SELECT skeys FROM skeys(tags) WHERE skeys LIKE 'wikipedia:%')) AND ST_IsValid(way)) AS foo) TO STDOUT WITH DELIMITER ';';" >> olm-ways.csv

# generate csv files of database, ~ 2 min
psql -d nextobjects -c "COPY (SELECT foo.type AS type, foo.name AS name, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM( SELECT tags->'name' AS name, CASE WHEN tags->'railway'='station' THEN 'station' WHEN tags->'railway'='halt' THEN 'halt' WHEN tags->'amenity'='bus_station' THEN 'bus_station' WHEN tags->'highway'='bus_stop' THEN 'bus_stop' WHEN tags->'railway'='tram_stop' THEN 'tram_stop' WHEN tags->'amenity'='parking' THEN 'parking' END AS type, ST_Transform(ST_Centroid(way), 4326) AS geom FROM nextobjects_line WHERE ((tags->'amenity' = 'bus_station') OR (tags->'highway' = 'bus_stop') OR (tags->'railway' = 'station') OR (tags->'railway' = 'halt') OR (tags->'railway' = 'tram_stop') OR (tags->'amenity' = 'parking')) AND ST_IsValid(way) ) AS foo) TO STDOUT WITH DELIMITER ';';" > nextobjects.csv

# generate csv files of database, ~ 2 min
psql -d nextobjects -c "COPY (SELECT foo.type AS type, foo.name AS name, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM( SELECT tags->'name' AS name, CASE WHEN tags->'railway'='station' THEN 'station' WHEN tags->'railway'='halt' THEN 'halt' WHEN tags->'amenity'='bus_station' THEN 'bus_station' WHEN tags->'highway'='bus_stop' THEN 'bus_stop' WHEN tags->'railway'='tram_stop' THEN 'tram_stop' WHEN tags->'amenity'='parking' THEN 'parking' END AS type, ST_Transform(way, 4326) AS geom FROM nextobjects_point WHERE ((tags->'amenity' = 'bus_station') OR (tags->'highway' = 'bus_stop') OR (tags->'railway' = 'station') OR (tags->'railway' = 'halt') OR (tags->'railway' = 'tram_stop') OR (tags->'amenity' = 'parking')) AND ST_IsValid(way) ) AS foo) TO STDOUT WITH DELIMITER ';';" >> nextobjects.csv

# generate csv files of database, ~ 2 min
psql -d nextobjects -c "COPY (SELECT foo.type AS type, foo.name AS name, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM( SELECT tags->'name' AS name, 	CASE WHEN tags->'railway'='station' THEN 'station' WHEN tags->'railway'='halt' THEN 'halt' WHEN tags->'amenity'='bus_station' THEN 'bus_station' WHEN tags->'highway'='bus_stop' THEN 'bus_stop' WHEN tags->'railway'='tram_stop' THEN 'tram_stop' WHEN tags->'amenity'='parking' THEN 'parking' END AS type, ST_Transform(ST_Centroid(way), 4326) AS geom FROM nextobjects_polygon WHERE ((tags->'amenity' = 'bus_station') OR (tags->'highway' = 'bus_stop') OR (tags->'railway' = 'station') OR (tags->'railway' = 'halt') OR (tags->'railway' = 'tram_stop') OR (tags->'amenity' = 'parking')) AND ST_IsValid(way) ) AS foo) TO STDOUT WITH DELIMITER ';';" >> nextobjects.csv

exit

# upload
scp -r olm-nodes.csv w3_user1@matheisen-v1c-117.kunden.csl.de:/home/www/sites/194.245.35.149/site/import
scp -r olm-ways.csv w3_user1@matheisen-v1c-117.kunden.csl.de:/home/www/sites/194.245.35.149/site/import
scp -r nextobjects.csv w3_user1@matheisen-v1c-117.kunden.csl.de:/home/www/sites/194.245.35.149/site/import
scp -r timestamp w3_user1@matheisen-v1c-117.kunden.csl.de:/home/www/sites/194.245.35.149/site/import

# start import
ssh postgres@matheisen-v1c-117.kunden.csl.de "php /home/www/sites/194.245.35.149/site/import/install.php"