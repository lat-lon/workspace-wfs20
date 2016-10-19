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

CREATE OR REPLACE RULE insert AS
    ON INSERT TO osm_administrative_version DO INSTEAD  INSERT INTO versions.public_osm_administrative_version_log (id, osm_id, admin_level, name, place, osm_timestamp, way_area, geometry, gml_description, gml_identifier, gml_name, place_attr_nil, place_attr_nilreason, osm_timestamp_modified_id, osm_timestamp_modified, action)
  VALUES (new.id, new.osm_id, new.admin_level, new.name, new.place, new.osm_timestamp, new.way_area, new.geometry, new.gml_description, new.gml_identifier, new.gml_name, new.place_attr_nil, new.place_attr_nilreason, new.osm_timestamp_modified_id, new.osm_timestamp_modified, 'insert'::character varying)
  RETURNING public_osm_administrative_version_log.id,
    public_osm_administrative_version_log.osm_id,
    public_osm_administrative_version_log.admin_level,
    public_osm_administrative_version_log.name,
    public_osm_administrative_version_log.place,
    public_osm_administrative_version_log.osm_timestamp,
    public_osm_administrative_version_log.way_area,
    public_osm_administrative_version_log.geometry,
    public_osm_administrative_version_log.gml_description,
    public_osm_administrative_version_log.gml_identifier,
    public_osm_administrative_version_log.gml_name,
    public_osm_administrative_version_log.place_attr_nil,
    public_osm_administrative_version_log.place_attr_nilreason,
    public_osm_administrative_version_log.osm_timestamp_modified_id,
    public_osm_administrative_version_log.osm_timestamp_modified,
    public_osm_administrative_version_log.version_log_id,
    public_osm_administrative_version_log.action,
    to_timestamp((public_osm_administrative_version_log.systime / 1000)::double precision) AS to_timestamp;
