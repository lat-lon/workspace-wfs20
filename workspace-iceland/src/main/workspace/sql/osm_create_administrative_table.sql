create table osm_administrative as select osm_id, admin_level, name, place, way_area, way as geometry from planet_osm_polygon where boundary = 'administrative';
grant all on osm_administrative to deegree;

create sequence osm_administrative_seq;
grant all on osm_administrative_seq to deegree;
alter table osm_administrative add column id integer default nextval('osm_administrative_seq');
ALTER TABLE osm_administrative ADD COLUMN gml_description varchar;
ALTER TABLE osm_administrative ADD COLUMN gml_identifier varchar;
ALTER TABLE osm_administrative ADD COLUMN gml_name varchar;
ALTER TABLE osm_administrative ADD COLUMN place_attr_nil boolean;
ALTER TABLE osm_administrative ADD COLUMN place_attr_nilreason text;
ALTER TABLE osm_administrative ADD COLUMN administrative_date date;
ALTER TABLE osm_administrative ADD COLUMN administrative_datetime timestamp;

UPDATE osm_administrative set administrative_date = cast(date '2018-07-01' - trunc( osm_id & 50 ) * '1 month'::interval as date);
UPDATE osm_administrative set administrative_datetime = cast(timestamp '2018-07-01 20:03:50' - trunc( (osm_id & 100)) * '1 month'::interval as timestamp);