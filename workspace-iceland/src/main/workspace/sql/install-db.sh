#!/bin/bash

#
# Execute script as 'postgresql' user.
# Following tools have to be installed:
# * dropdb
# * psql
# * createdb
# * osm2pgsql
#

function dropDB {
  dropdb iceland
}

function createDB {
  psql -c "CREATE USER deegree WITH PASSWORD 'deegree'"
  createdb iceland -O deegree
  psql -d iceland -c "CREATE EXTENSION postgis;"
}

function importGN {
  psql -d iceland -f gns_create_postgis_table.sql
  psql -d iceland -f gns_add_gml_columns.sql
}

function importOSM {
  osm2pgsql --keep-coastlines -s -d iceland ../data/iceland-latest.osm.pbf
  psql -d iceland -f osm_import_to_epsg-4326.sql
  psql -d iceland -f osm_create_administrative_table.sql
  psql -d iceland -f osm_create_protected_area_table.sql
  psql -d iceland -f osm_add_gml_columns_administrative.sql
  psql -d iceland -f osm_add_gml_columns_protected_area.sql
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