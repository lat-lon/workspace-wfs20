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
#  * requires osm2psql >= 0.90.0 (contains fix for https://github.com/openstreetmap/osm2pgsql/issues/137)
#  * Ubuntu package can be downloaded from http://archive.ubuntu.com/ubuntu/pool/universe/o/osm2pgsql/
# * pg_dump
# * dropdb
#

function createDB {
  psql -c "CREATE USER deegree WITH PASSWORD 'deegree'"
  psql -c "CREATE USER version"
  createdb iceland_dump_base
  psql -d iceland_dump_base -c "CREATE EXTENSION postgis;"
}

function createPGVersionFunctions {
  psql -d iceland_dump_base -f pgversion_createFunctions_erweitert.sql
}

function importGN {
  psql -d iceland_dump_base -f gns_create_postgis_table.sql
  PGPASSWORD=deegree psql -h localhost -d iceland_dump_base -U deegree -f gns_insert_postgis_table.sql
  psql -d iceland_dump_base -f gns_drop_table.sql
}

function importOSM {
  osm2pgsql -S ../data/iceland-latest.style --keep-coastlines -x -s -d iceland_dump_base ../data/iceland-latest.osm.pbf
  psql -d iceland_dump_base -f osm_import_to_epsg-4326.sql
  psql -d iceland_dump_base -f osm_create_administrative_table.sql
  psql -d iceland_dump_base -f osm_create_protected_area_table.sql
  PGPASSWORD=deegree psql -h localhost -d iceland_dump_base -U deegree -f osm_insert_administrative_table.sql
  PGPASSWORD=deegree psql -h localhost -d iceland_dump_base -U deegree -f osm_insert_protected_area_table.sql
  psql -d iceland_dump_base -f osm_drop_tables.sql
}

function grantPrivilegesToDeegree {
  psql -d iceland_dump_base -c "GRANT USAGE ON SCHEMA versions TO deegree;"
}

function createDump {
 pg_dump iceland_dump_base -f ../data/iceland-latest.dump
} 

function dropDB {
  dropdb iceland_dump_base
}

####################
####  EXECUTION ####
####################
createDB
createPGVersionFunctions
importGN
importOSM
grantPrivilegesToDeegree
createDump
dropDB