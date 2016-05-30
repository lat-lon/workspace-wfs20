#!/bin/bash

#
# Execute script as 'postgresql' user.
# Following tools have to be installed:
# * createdb
# * psql
# * osm2pgsql
#

function dropDB {
  dropdb iceland
}

function createDB {
  createdb iceland -O deegree
  psql -d iceland -c "CREATE EXTENSION postgis;"
}

function importGN {
  psql -d iceland -f gns_create_postgis_table.sql
}

function importOSM {
  osm2pgsql --keep-coastlines -s -d iceland ../data/iceland-latest.osm.pbf
  psql -d iceland -f osm-import_to_epsg-4326.sql
  psql -d iceland -f osm_create_administrative_table.sql
  psql -d iceland -f osm_create_protected_area_table.sql
  psql -d iceland -f osm_drop_tables.sql
}

####################
####  EXECUTION ####
####################
# database
dropDB
createDB
# GN
importGN
# OSM
importOSM