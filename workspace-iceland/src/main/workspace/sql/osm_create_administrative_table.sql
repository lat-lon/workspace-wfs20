create table osm_administrative as select osm_id, admin_level, name, place, osm_timestamp::TIMESTAMPTZ, way_area, way as geometry from planet_osm_polygon with no data;
grant all on osm_administrative to deegree;

create sequence osm_administrative_seq;
grant all on osm_administrative_seq to deegree;
alter table osm_administrative add column id integer default nextval('osm_administrative_seq');
ALTER TABLE osm_administrative ADD COLUMN gml_description varchar;
ALTER TABLE osm_administrative ADD COLUMN gml_identifier varchar;
ALTER TABLE osm_administrative ADD COLUMN gml_name varchar;
ALTER TABLE osm_administrative ADD COLUMN place_attr_nil boolean;
ALTER TABLE osm_administrative ADD COLUMN place_attr_nilreason text;
ALTER TABLE osm_administrative ADD COLUMN osm_timestamp_modified_id varchar;
ALTER TABLE osm_administrative ADD COLUMN osm_timestamp_modified timestamptz;
ALTER TABLE osm_administrative ADD PRIMARY KEY (id);

SELECT * FROM versions.pgvsinit('public.osm_administrative');

grant all on osm_administrative_version to deegree;

INSERT INTO osm_administrative_version (osm_id, admin_level, name, place, osm_timestamp, way_area, geometry) SELECT osm_id, admin_level, name, place, osm_timestamp::TIMESTAMPTZ, way_area, way FROM planet_osm_polygon where boundary = 'administrative';

UPDATE osm_administrative_version set osm_timestamp_modified_id = 'TP_osm_administrative_' || id;
UPDATE osm_administrative_version set osm_timestamp_modified = cast( osm_timestamp + '1 day'::interval as timestamp);