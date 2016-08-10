create table osm_administrative as select osm_id, admin_level, name, place, osm_timestamp::TIMESTAMPTZ, way_area, way as geometry from planet_osm_polygon where boundary = 'administrative';
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

UPDATE osm_administrative set osm_timestamp_modified_id = 'TP_osm_administrative_' || id;
UPDATE osm_administrative set osm_timestamp_modified = cast( osm_timestamp + '1 day'::interval as timestamp);