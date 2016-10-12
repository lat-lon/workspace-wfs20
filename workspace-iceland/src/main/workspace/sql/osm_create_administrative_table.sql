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

GRANT ALL ON osm_administrative_version to deegree;
GRANT ALL ON versions.public_osm_administrative_version_log to deegree;
GRANT USAGE ON SEQUENCE versions.public_osm_administrative_version_log_version_log_id_seq TO deegree;
GRANT ALL ON  versions.public_osm_administrative_version_log to deegree;