create table osm_administrative as select osm_id, admin_level, name, place, way_area, way as geometry from planet_osm_polygon where boundary = 'administrative';
grant all on osm_administrative to deegree;

create sequence osm_administrative_seq;
alter table osm_administrative add column id integer default nextval('osm_administrative_seq');
ALTER TABLE osm_administrative ADD COLUMN gml_description varchar;
ALTER TABLE osm_administrative ADD COLUMN gml_identifier varchar;
ALTER TABLE osm_administrative ADD COLUMN gml_name varchar;