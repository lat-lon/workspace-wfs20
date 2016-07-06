create table osm_protected_area as select osm_id, boundary, leisure, name, tourism, way_area, way as geometry from planet_osm_polygon where boundary in ('protected_area', 'national_park');
grant all on osm_protected_area to deegree;

create sequence osm_protected_area_seq;
grant all on osm_protected_area_seq to deegree;
alter table osm_protected_area add column id integer default nextval('osm_protected_area_seq');
ALTER TABLE osm_protected_area ADD COLUMN gml_description varchar;
ALTER TABLE osm_protected_area ADD COLUMN gml_identifier varchar;
ALTER TABLE osm_protected_area ADD COLUMN gml_name varchar;
ALTER TABLE osm_protected_area ADD COLUMN protected_area_date date;
ALTER TABLE osm_protected_area ADD COLUMN protected_area_datetime timestamp;

UPDATE osm_protected_area set protected_area_date = cast(date '2016-07-01' - trunc( osm_id & 50 ) * '1 month'::interval as date);
UPDATE osm_protected_area set protected_area_datetime = cast(timestamp '2016-07-01 20:03:50' - trunc( (osm_id & 100)) * '1 month'::interval as timestamp);