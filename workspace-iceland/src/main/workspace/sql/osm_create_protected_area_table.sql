create table osm_protected_area as select osm_id, boundary, leisure, name, tourism, way_area, way as geometry from planet_osm_polygon where boundary in ('protected_area', 'national_park');
grant SELECT on osm_protected_area to deegree;