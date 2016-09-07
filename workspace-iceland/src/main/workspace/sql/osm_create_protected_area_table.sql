create table osm_protected_area as select osm_id, boundary, leisure, name, tourism, osm_timestamp::TIMESTAMPTZ, way_area, way as geometry from planet_osm_polygon with no data;
grant all on osm_protected_area to deegree;

create sequence osm_protected_area_seq;
grant all on osm_protected_area_seq to deegree;
alter table osm_protected_area add column id integer default nextval('osm_protected_area_seq');
ALTER TABLE osm_protected_area ADD COLUMN gml_description varchar;
ALTER TABLE osm_protected_area ADD COLUMN gml_identifier varchar;
ALTER TABLE osm_protected_area ADD COLUMN gml_name varchar;
ALTER TABLE osm_protected_area ADD COLUMN osm_timestamp_modified_id varchar;
ALTER TABLE osm_protected_area ADD COLUMN osm_timestamp_modified timestamptz;
ALTER TABLE osm_protected_area ADD PRIMARY KEY (id);

SELECT * FROM versions.pgvsinit('public.osm_protected_area');

GRANT ALL ON osm_protected_area_version to deegree;
GRANT ALL ON versions.public_osm_protected_area_version_log to deegree;
GRANT USAGE ON SEQUENCE versions.public_osm_protected_area_version_log_version_log_id_seq TO deegree;
GRANT ALL ON  versions.public_osm_protected_area_version_log to deegree;