-- Remove SRID table constraint
alter table planet_osm_polygon alter COLUMN way type geometry;
alter table planet_osm_roads alter COLUMN way type geometry;
alter table planet_osm_point alter COLUMN way type geometry;
alter table planet_osm_line alter COLUMN way type geometry;
-- Transform coordinates
update planet_osm_polygon set way = st_transform(way, 4326);
update planet_osm_roads set way = st_transform(way, 4326);
update planet_osm_point set way = st_transform(way, 4326);
update planet_osm_line set way = st_transform(way, 4326);
-- Set SRID table constraint to 4326
SELECT UpdateGeometrySRID('planet_osm_roads','way',4326);
SELECT UpdateGeometrySRID('planet_osm_polygon','way',4326);
SELECT UpdateGeometrySRID('planet_osm_point','way',4326);
SELECT UpdateGeometrySRID('planet_osm_line','way',4326);
-- Set geometry type table constraint where applicable
--    (set to result from e.g. 'select distinct(GeometryType(way)) from planet_osm_roads;')
alter table planet_osm_roads alter COLUMN way type geometry(LINESTRING,4326);
alter table planet_osm_point alter COLUMN way type geometry(POINT,4326);
alter table planet_osm_line alter COLUMN way type geometry(LINESTRING,4326);