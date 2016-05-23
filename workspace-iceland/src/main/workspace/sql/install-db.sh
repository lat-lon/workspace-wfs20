#!/bin/bash

function createDB {
  createdb iceland
  psql -d iceland -c "CREATE EXTENSION postgis;"
}

function dropSchema {
  psql -d iceland -f osm_drop_tables.sql
}

}
function createSchema {
  psql -d iceland -f create_postgis_table.sql
  psql -d iceland -f osm-import_to_epsg-4326.sql
  psql -d iceland -f osm_create_administrative_table.sql
  psql -d iceland -f osm_create_protected_area_table.sql
}

####################
####  EXECUTION ####
####################
createDB
dropSchema
createSchema