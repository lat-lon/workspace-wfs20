#!/bin/bash

#
# Execute script as 'postgresql' user.
# Following tools have to be installed:
# * dropdb
# * psql
# * createdb
# * osm2pgsql
#  * requires osm2psql >= 0.90.0 (contains fix for https://github.com/openstreetmap/osm2pgsql/issues/137)
#  * Ubuntu package can be downloaded from http://archive.ubuntu.com/ubuntu/pool/universe/o/osm2pgsql/
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
}

function importOSM {
  psql -d iceland -f ../data/iceland-latest.dump
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
