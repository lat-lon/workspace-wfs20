create table osm_protected_area as select osm_id, boundary, leisure, name, tourism, osm_timestamp::TIMESTAMPTZ, way_area, way as geometry from planet_osm_polygon with no data;
grant all on osm_protected_area to deegree;

create sequence osm_protected_area_seq;
grant all on osm_protected_area_seq to deegree;
alter table osm_protected_area add column id integer default nextval('osm_protected_area_seq');
ALTER TABLE osm_protected_area ADD COLUMN gml_description varchar;
ALTER TABLE osm_protected_area ADD COLUMN gml_identifier varchar;
ALTER TABLE osm_protected_area ADD COLUMN gml_identifier_codespace varchar;
ALTER TABLE osm_protected_area ADD COLUMN gml_name varchar;
ALTER TABLE osm_protected_area ADD COLUMN osm_timestamp_modified_id varchar;
ALTER TABLE osm_protected_area ADD COLUMN osm_timestamp_modified timestamptz;
ALTER TABLE osm_protected_area ADD PRIMARY KEY (id);

SELECT * FROM versions.pgvsinit('public.osm_protected_area');

GRANT ALL ON osm_protected_area_version to deegree;
GRANT ALL ON versions.public_osm_protected_area_version_log to deegree;
GRANT USAGE ON SEQUENCE versions.public_osm_protected_area_version_log_version_log_id_seq TO deegree;
GRANT ALL ON  versions.public_osm_protected_area_version_log to deegree;

CREATE OR REPLACE RULE insert AS
    ON INSERT TO osm_protected_area_version DO INSTEAD  INSERT INTO versions.public_osm_protected_area_version_log (id, osm_id, boundary, leisure, name, tourism, osm_timestamp, way_area, geometry, gml_description, gml_identifier, gml_identifier_codespace, gml_name, osm_timestamp_modified_id, osm_timestamp_modified, action)
  VALUES (new.id, new.osm_id, new.boundary, new.leisure, new.name, new.tourism, new.osm_timestamp, new.way_area, new.geometry, new.gml_description, new.gml_identifier, new.gml_identifier_codespace, new.gml_name, new.osm_timestamp_modified_id, new.osm_timestamp_modified, 'insert'::character varying)
  RETURNING public_osm_protected_area_version_log.id,
    public_osm_protected_area_version_log.osm_id,
    public_osm_protected_area_version_log.boundary,
    public_osm_protected_area_version_log.leisure,
    public_osm_protected_area_version_log.name,
    public_osm_protected_area_version_log.tourism,
    public_osm_protected_area_version_log.osm_timestamp,
    public_osm_protected_area_version_log.way_area,
    public_osm_protected_area_version_log.geometry,
    public_osm_protected_area_version_log.gml_description,
    public_osm_protected_area_version_log.gml_identifier,
    public_osm_protected_area_version_log.gml_identifier_codespace,
    public_osm_protected_area_version_log.gml_name,
    public_osm_protected_area_version_log.osm_timestamp_modified_id,
    public_osm_protected_area_version_log.osm_timestamp_modified,
    public_osm_protected_area_version_log.version_log_id,
    public_osm_protected_area_version_log.action,
    to_timestamp((public_osm_protected_area_version_log.systime / 1000)::double precision) AS to_timestamp;
