#!/bin/bash

#
# Sets up the database for this workspace.
#
# Execute script as 'postgresql' user.
# Following tools have to be installed:
# * dropdb
# * psql
# * createdb
#

function dropDB {
  dropdb iceland
}

function createDB {
  psql -c "CREATE USER deegree WITH PASSWORD 'deegree'"
  createdb iceland -O deegree
  psql -d iceland -c "CREATE EXTENSION postgis;"
}

function import {
  psql -d iceland -f ../data/iceland-latest.dump
}

####################
####  EXECUTION ####
####################
# database
dropDB
createDB
import