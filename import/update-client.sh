#!/bin/bash

# OpenLinkMap Copyright (C) 2010 Alexander Matheisen
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it under certain conditions.
# See openlinkmap.org for details.


date
echo ""

# working directory, please change
cd /home/alexander/Projekte/OLM/olm7/import
PATH="$PATH:/home/alexander/Projekte/OLM/olm7/import/bin"

# ~ 45 min
echo "[1/6] Updating data..."
date -u +%s > timestamp
sudo su - postgres
# working directory, please change
cd /home/alexander/Projekte/OLM/olm7/import
PATH="$PATH:/home/alexander/Projekte/OLM/olm7/import/bin"
osmupdate old.o5m new.o5m --max-merge=14 --drop-author -v
rm old.o5m
mv new.o5m old.o5m
echo ""

# ~ 35 min
echo "[2/6] Filtering data..."
osmfilter old.o5m --fake-lonlat --keep="wikipedia= wikipedia:*= contact:phone= website= url= phone= fax= email= addr:email= image= url:official= contact:website= addr:phone= phone:mobile= contact:mobile= addr:fax= contact:email= contact:fax=" --drop-author -v --out-o5m >new-olm.o5m

# ~ 30 min
osmfilter old.o5m --fake-lonlat --keep="amenity=bus_station highway=bus_stop railway=station railway=halt railway=tram_stop amenity=parking" --drop-author -v --out-o5m >new-nextobjects.o5m
echo ""

# ~ 2 min
echo "[3/6] Building diff..."
osmconvert old-olm.o5m new-olm.o5m --diff-contents --fake-lonlat --out-osc >diff-olm.osc
rm old-olm.o5m
mv new-olm.o5m old-olm.o5m

osmconvert old-nextobjects.o5m new-nextobjects.o5m --diff-contents --fake-lonlat --out-osc >diff-nextobjects.osc
rm old-nextobjects.o5m
mv new-nextobjects.o5m old-nextobjects.o5m
echo ""

# ~ 60 min
echo "[4/6] Applying changes..."
osm2pgsql --append --database olm --prefix olm --style olm.style --slim --hstore --cache 2096 diff-olm.osc
rm diff-olm.osc

osm2pgsql --append --database nextobjects --prefix nextobjects --style olm.style --slim --hstore --cache 2096 diff-nextobjects.osc
rm diff-nextobjects.osc
echo ""

# ~ 4 min
echo "[5/6] Generating list..."
psql -d olm -c "COPY (SELECT foo.osmid AS osmid, foo.tags AS tags, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM (SELECT osm_id AS osmid, tags AS tags, ST_Transform(way, 4326) AS geom FROM olm_point WHERE ((tags ? 'wikipedia') OR (tags ? 'phone') OR (tags ? 'addr:phone') OR (tags ? 'contact:phone') OR (tags ? 'phone:mobile') OR (tags ? 'contact:mobile') OR (tags ? 'fax') OR (tags ? 'addr:fax') OR (tags ? 'contact:fax') OR (tags ? 'image') OR (tags ? 'email') OR (tags ? 'addr:email') OR (tags ? 'contact:email') OR (tags ? 'website') OR (tags ? 'contact:website') OR (tags ? 'url') OR (tags ? 'url:official') OR EXISTS(SELECT skeys FROM skeys(tags) WHERE skeys LIKE 'wikipedia:%')) AND ST_IsValid(way)) AS foo) TO STDOUT WITH DELIMITER ';';" > olm-nodes.csv

psql -d olm -c "COPY (SELECT foo.osmid AS osmid, foo.tags AS tags, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM (SELECT osm_id AS osmid, tags AS tags, ST_Transform(ST_Centroid(way), 4326) AS geom FROM olm_polygon WHERE ((tags ? 'wikipedia') OR (tags ? 'phone') OR (tags ? 'addr:phone') OR (tags ? 'contact:phone') OR (tags ? 'phone:mobile') OR (tags ? 'contact:mobile') OR (tags ? 'fax') OR (tags ? 'addr:fax') OR (tags ? 'contact:fax') OR (tags ? 'image') OR (tags ? 'email') OR (tags ? 'addr:email') OR (tags ? 'contact:email') OR (tags ? 'website') OR (tags ? 'contact:website') OR (tags ? 'url') OR (tags ? 'url:official') OR EXISTS(SELECT skeys FROM skeys(tags) WHERE skeys LIKE 'wikipedia:%')) AND ST_IsValid(way)) AS foo) TO STDOUT WITH DELIMITER ';';" > olm-ways.csv

psql -d olm -c "COPY (SELECT foo.osmid AS osmid, foo.tags AS tags, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM (SELECT osm_id AS osmid, tags AS tags, ST_Transform(ST_Centroid(way), 4326) AS geom FROM olm_line WHERE ((tags ? 'wikipedia') OR (tags ? 'phone') OR (tags ? 'addr:phone') OR (tags ? 'contact:phone') OR (tags ? 'phone:mobile') OR (tags ? 'contact:mobile') OR (tags ? 'fax') OR (tags ? 'addr:fax') OR (tags ? 'contact:fax') OR (tags ? 'image') OR (tags ? 'email') OR (tags ? 'addr:email') OR (tags ? 'contact:email') OR (tags ? 'website') OR (tags ? 'contact:website') OR (tags ? 'url') OR (tags ? 'url:official') OR EXISTS(SELECT skeys FROM skeys(tags) WHERE skeys LIKE 'wikipedia:%')) AND ST_IsValid(way)) AS foo) TO STDOUT WITH DELIMITER ';';" >> olm-ways.csv

psql -d nextobjects -c "COPY (SELECT foo.type AS type, foo.name AS name, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM( SELECT tags->'name' AS name, CASE WHEN tags->'railway'='station' THEN 'station' WHEN tags->'railway'='halt' THEN 'halt' WHEN tags->'amenity'='bus_station' THEN 'bus_station' WHEN tags->'highway'='bus_stop' THEN 'bus_stop' WHEN tags->'railway'='tram_stop' THEN 'tram_stop' WHEN tags->'amenity'='parking' THEN 'parking' END AS type, ST_Transform(ST_Centroid(way), 4326) AS geom FROM nextobjects_line WHERE ((tags->'amenity' = 'bus_station') OR (tags->'highway' = 'bus_stop') OR (tags->'railway' = 'station') OR (tags->'railway' = 'halt') OR (tags->'railway' = 'tram_stop') OR (tags->'amenity' = 'parking')) AND ST_IsValid(way) ) AS foo) TO STDOUT WITH DELIMITER ';';" > nextobjects.csv

psql -d nextobjects -c "COPY (SELECT foo.type AS type, foo.name AS name, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM( SELECT tags->'name' AS name, CASE WHEN tags->'railway'='station' THEN 'station' WHEN tags->'railway'='halt' THEN 'halt' WHEN tags->'amenity'='bus_station' THEN 'bus_station' WHEN tags->'highway'='bus_stop' THEN 'bus_stop' WHEN tags->'railway'='tram_stop' THEN 'tram_stop' WHEN tags->'amenity'='parking' THEN 'parking' END AS type, ST_Transform(way, 4326) AS geom FROM nextobjects_point WHERE ((tags->'amenity' = 'bus_station') OR (tags->'highway' = 'bus_stop') OR (tags->'railway' = 'station') OR (tags->'railway' = 'halt') OR (tags->'railway' = 'tram_stop') OR (tags->'amenity' = 'parking')) AND ST_IsValid(way) ) AS foo) TO STDOUT WITH DELIMITER ';';" >> nextobjects.csv

psql -d nextobjects -c "COPY (SELECT foo.type AS type, foo.name AS name, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM( SELECT tags->'name' AS name, 	CASE WHEN tags->'railway'='station' THEN 'station' WHEN tags->'railway'='halt' THEN 'halt' WHEN tags->'amenity'='bus_station' THEN 'bus_station' WHEN tags->'highway'='bus_stop' THEN 'bus_stop' WHEN tags->'railway'='tram_stop' THEN 'tram_stop' WHEN tags->'amenity'='parking' THEN 'parking' END AS type, ST_Transform(ST_Centroid(way), 4326) AS geom FROM nextobjects_polygon WHERE ((tags->'amenity' = 'bus_station') OR (tags->'highway' = 'bus_stop') OR (tags->'railway' = 'station') OR (tags->'railway' = 'halt') OR (tags->'railway' = 'tram_stop') OR (tags->'amenity' = 'parking')) AND ST_IsValid(way) ) AS foo) TO STDOUT WITH DELIMITER ';';" >> nextobjects.csv
echo ""

diff olm-nodes.csv olm-nodes-new.csv > diff-nodes.diff
diff olm-ways.csv olm-ways-new.csv > diff-ways.diff
diff nextobjects.csv nextobjects-new.csv > diff-nextobjects.diff

rm olm-nodes.csv
mv olm-nodes-new.csv olm-nodes.csv
rm olm-ways.csv
mv olm-ways-new.csv olm-ways.csv
rm nextobjects.csv
mv nextobjects-new.csv nextobjects.csv

exit

# ~ xx min, seit 19:12
echo "[6/6] Uploading to server..."
scp -r diff-nodes.diff w3_user1@matheisen-v1c-117.kunden.csl.de:/home/www/sites/194.245.35.149/site/import
scp -r diff-ways.diff w3_user1@matheisen-v1c-117.kunden.csl.de:/home/www/sites/194.245.35.149/site/import
scp -r diff-nextobjects.diff w3_user1@matheisen-v1c-117.kunden.csl.de:/home/www/sites/194.245.35.149/site/import
scp -r timestamp w3_user1@matheisen-v1c-117.kunden.csl.de:/home/www/sites/194.245.35.149/site/import
ssh postgres@matheisen-v1c-117.kunden.csl.de "php /home/www/sites/194.245.35.149/site/import/update.php"
echo ""

date
echo ""

echo "Finish."