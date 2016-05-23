create table osm_administrative as select osm_id, admin_level, name, place, way_
area, way as geometry from planet_osm_polygon where boundary = 'administrative';
grant select on osm_administrative to deegree ;