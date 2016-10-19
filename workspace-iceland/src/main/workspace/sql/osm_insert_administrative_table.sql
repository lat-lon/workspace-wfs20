INSERT INTO osm_administrative_version (id, osm_id, admin_level, name, place, osm_timestamp, way_area, geometry) SELECT nextval('osm_administrative_seq'::regclass), osm_id, admin_level, name, place, osm_timestamp::TIMESTAMPTZ, way_area, way FROM planet_osm_polygon where boundary = 'administrative';

UPDATE osm_administrative_version set osm_timestamp_modified_id = 'TP_osm_administrative_' || id;
UPDATE osm_administrative_version set osm_timestamp_modified = cast( osm_timestamp + '1 day'::interval as timestamp);