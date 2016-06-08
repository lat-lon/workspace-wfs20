create table osm_protected_area as select osm_id, boundary, leisure, name, tourism, way_area, way as geometry from planet_osm_polygon where boundary in ('protected_area', 'national_park');
grant all on osm_protected_area to deegree;

create sequence osm_protected_area_seq;
grant all on osm_protected_area_seq to deegree;
alter table osm_protected_area add column id integer default nextval('osm_protected_area_seq');
ALTER TABLE osm_protected_area ADD COLUMN gml_description varchar;
ALTER TABLE osm_protected_area ADD COLUMN gml_identifier varchar;
ALTER TABLE osm_protected_area ADD COLUMN gml_name varchar;