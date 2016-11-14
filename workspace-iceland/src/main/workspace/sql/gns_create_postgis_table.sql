DROP TABLE IF EXISTS import;
CREATE TABLE import (
RC numeric,
UFI numeric,
UNI numeric,
LAT numeric,
LONG numeric,
DMS_LAT varchar,
DMS_LONG varchar,
MGRS varchar,
JOG varchar,
FC varchar,
DSG varchar,
PC numeric,
CC1 varchar,
ADM1 varchar,
POP numeric,
ELEV numeric,
CC2 varchar,
NT varchar,
LC varchar,
SHORT_FORM varchar,
GENERIC varchar,
SORT_NAME_RO varchar,
FULL_NAME_RO varchar,
FULL_NAME_ND_RO varchar,
SORT_NAME_RG varchar,
FULL_NAME_RG varchar,
FULL_NAME_ND_RG varchar,
NOTE varchar,
MODIFY_DATE date,
DISPLAY varchar,
NAME_RANK numeric,
NAME_LINK numeric,
TRANSL_CD varchar,
NM_MODIFY_DATE date,
F_EFCTV_DT varchar,
F_TERM_DT varchar
);

-- load data:
-- geonames=# \copy import from '../data/ic.txt' with delimiter E'\t' csv header;
\copy import from '../data/ic.txt' with delimiter E'\t' csv header;
alter table import add column geometry geometry(POINT, 4326);
update import set geometry = ST_SetSRID(ST_MakePoint (long,lat), 4326);
-- here, we could create a subset from the imported GNS data
DROP TABLE IF EXISTS gns_iceland;
GRANT SELECT ON import to deegree ;
create table gns_iceland as select * from import with no data;
grant all on gns_iceland to deegree ;

create sequence gns_iceland_seq;
grant all on gns_iceland_seq to deegree ;
alter table gns_iceland add column id integer default nextval('gns_iceland_seq');
ALTER TABLE gns_iceland ADD COLUMN gml_description varchar;
ALTER TABLE gns_iceland ADD COLUMN gml_identifier varchar;
ALTER TABLE gns_iceland ADD COLUMN gml_identifier_codespace varchar;
ALTER TABLE gns_iceland ADD COLUMN gml_name varchar;
ALTER TABLE gns_iceland ADD PRIMARY KEY (id);

SELECT * FROM versions.pgvsinit('public.gns_iceland');

GRANT ALL ON gns_iceland_version to deegree ;
GRANT ALL ON versions.public_gns_iceland_version_log to deegree;
GRANT USAGE ON SEQUENCE versions.public_gns_iceland_version_log_version_log_id_seq TO deegree;
GRANT ALL ON  versions.public_gns_iceland_version_log to deegree;

CREATE OR REPLACE RULE insert AS
    ON INSERT TO gns_iceland_version DO INSTEAD  INSERT INTO versions.public_gns_iceland_version_log (id, rc, ufi, uni, lat, long, dms_lat, dms_long, mgrs, jog, fc, dsg, pc, cc1, adm1, pop, elev, cc2, nt, lc, short_form, generic, sort_name_ro, full_name_ro, full_name_nd_ro, sort_name_rg, full_name_rg, full_name_nd_rg, note, modify_date, display, name_rank, name_link, transl_cd, nm_modify_date, f_efctv_dt, f_term_dt, geometry, gml_description, gml_identifier, gml_identifier_codespace, gml_name, action)
  VALUES (new.id, new.rc, new.ufi, new.uni, new.lat, new.long, new.dms_lat, new.dms_long, new.mgrs, new.jog, new.fc, new.dsg, new.pc, new.cc1, new.adm1, new.pop, new.elev, new.cc2, new.nt, new.lc, new.short_form, new.generic, new.sort_name_ro, new.full_name_ro, new.full_name_nd_ro, new.sort_name_rg, new.full_name_rg, new.full_name_nd_rg, new.note, new.modify_date, new.display, new.name_rank, new.name_link, new.transl_cd, new.nm_modify_date, new.f_efctv_dt, new.f_term_dt, new.geometry, new.gml_description, new.gml_identifier, new.gml_identifier_codespace, new.gml_name, 'insert'::character varying)
  RETURNING public_gns_iceland_version_log.id,
    public_gns_iceland_version_log.rc,
    public_gns_iceland_version_log.ufi,
    public_gns_iceland_version_log.uni,
    public_gns_iceland_version_log.lat,
    public_gns_iceland_version_log.long,
    public_gns_iceland_version_log.dms_lat,
    public_gns_iceland_version_log.dms_long,
    public_gns_iceland_version_log.mgrs,
    public_gns_iceland_version_log.jog,
    public_gns_iceland_version_log.fc,
    public_gns_iceland_version_log.dsg,
    public_gns_iceland_version_log.pc,
    public_gns_iceland_version_log.cc1,
    public_gns_iceland_version_log.adm1,
    public_gns_iceland_version_log.pop,
    public_gns_iceland_version_log.elev,
    public_gns_iceland_version_log.cc2,
    public_gns_iceland_version_log.nt,
    public_gns_iceland_version_log.lc,
    public_gns_iceland_version_log.short_form,
    public_gns_iceland_version_log.generic,
    public_gns_iceland_version_log.sort_name_ro,
    public_gns_iceland_version_log.full_name_ro,
    public_gns_iceland_version_log.full_name_nd_ro,
    public_gns_iceland_version_log.sort_name_rg,
    public_gns_iceland_version_log.full_name_rg,
    public_gns_iceland_version_log.full_name_nd_rg,
    public_gns_iceland_version_log.note,
    public_gns_iceland_version_log.modify_date,
    public_gns_iceland_version_log.display,
    public_gns_iceland_version_log.name_rank,
    public_gns_iceland_version_log.name_link,
    public_gns_iceland_version_log.transl_cd,
    public_gns_iceland_version_log.nm_modify_date,
    public_gns_iceland_version_log.f_efctv_dt,
    public_gns_iceland_version_log.f_term_dt,
    public_gns_iceland_version_log.geometry,
    public_gns_iceland_version_log.gml_description,
    public_gns_iceland_version_log.gml_identifier,
    public_gns_iceland_version_log.gml_identifier_codespace,
    public_gns_iceland_version_log.gml_name,
    public_gns_iceland_version_log.version_log_id,
    public_gns_iceland_version_log.action,
    to_timestamp((public_gns_iceland_version_log.systime / 1000)::double precision) AS to_timestamp;