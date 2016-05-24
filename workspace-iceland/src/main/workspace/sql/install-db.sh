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

function dropAndCreateSchemaAndImportDataGN {
  psql -d iceland -f gns_create_postgis_table.sql
}

function dropSchemaOSM {
  psql -d iceland -f osm_drop_tables.sql
}

function createSchemaOSM {
  psql -d iceland -f osm_create_administrative_table.sql
  psql -d iceland -f osm_create_protected_area_table.sql
}

function importDataOSM {
  psql -d iceland -f osm-import_to_epsg-4326.sql
}

####################
####  EXECUTION ####
####################
# database
dropDB
createDB
# GN
dropAndCreateSchemaAndImportDataGN
# OSM
#dropSchemaOSM
#createSchemaOSM
#importDataOSM