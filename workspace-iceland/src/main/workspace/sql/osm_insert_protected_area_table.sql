INSERT INTO osm_protected_area_version (id, osm_id, boundary, leisure, name, tourism, osm_timestamp, way_area, geometry) SELECT nextval('osm_protected_area_seq'::regclass), osm_id, boundary, leisure, name, tourism, osm_timestamp::TIMESTAMPTZ, way_area, way FROM planet_osm_polygon where boundary in ('protected_area', 'national_park') ;

UPDATE osm_protected_area_version set osm_timestamp_modified_id = 'TP_osm_protected_area_' || id;
UPDATE osm_protected_area_version set osm_timestamp_modified = cast( osm_timestamp + '1 day'::interval as timestamp);
