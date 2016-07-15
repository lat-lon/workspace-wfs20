#!/bin/bash

#
# Creates a database dump of a *.osm.pbf file. This dump can be used by the install.sh script.
# Creating this dump is just necessary if the *.osm.pbf file is updated. Otherwise, a version of this dump already exists in the workspace.
#
# Execute script as 'postgresql' user.
# Following tools have to be installed:
# * psql
# * createdb
# * osm2pgsql
#  -> requires osm2psql >= 0.90.0 (contains fix for https://github.com/openstreetmap/osm2pgsql/issues/137)
#  -> Ubuntu package can be downloaded from http://archive.ubuntu.com/ubuntu/pool/universe/o/osm2pgsql/
# * pg_dump
# * dropdb
#

function createDB {
  psql -c "CREATE USER deegree WITH PASSWORD 'deegree'"
  createdb iceland_dump_base
  psql -d iceland_dump_base -c "CREATE EXTENSION postgis;"
}

function importOSM {
  osm2pgsql -S ../data/iceland-latest.style --keep-coastlines -x -s -d iceland_dump_base ../data/iceland-latest.osm.pbf
  psql -d iceland_dump_base -f osm_import_to_epsg-4326.sql
  psql -d iceland_dump_base -f osm_create_administrative_table.sql
  psql -d iceland_dump_base -f osm_create_protected_area_table.sql
  psql -d iceland_dump_base -f osm_drop_tables.sql
}

function createDump {
 pg_dump -t osm_protected_area_seq -t osm_administrative_seq -t osm_protected_area -t osm_administrative iceland_dump_base -f ../data/iceland-latest.dump
} 

function dropDB {
  dropdb iceland_dump_base
}

####################
####  EXECUTION ####
####################
createDB
importOSM
createDump
dropDB