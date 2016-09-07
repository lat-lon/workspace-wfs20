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
create table gns_iceland as select * from import with no data;
grant all on gns_iceland to deegree ;

create sequence gns_iceland_seq;
grant all on gns_iceland_seq to deegree ;
alter table gns_iceland add column id integer default nextval('gns_iceland_seq');
ALTER TABLE gns_iceland ADD COLUMN gml_description varchar;
ALTER TABLE gns_iceland ADD COLUMN gml_identifier varchar;
ALTER TABLE gns_iceland ADD COLUMN gml_name varchar;
ALTER TABLE gns_iceland ADD PRIMARY KEY (id);

SELECT * FROM versions.pgvsinit('public.gns_iceland');

GRANT ALL ON gns_iceland_version to deegree ;
GRANT ALL ON versions.public_gns_iceland_version_log to deegree;
GRANT USAGE ON SEQUENCE versions.public_gns_iceland_version_log_version_log_id_seq TO deegree;
GRANT ALL ON  versions.public_gns_iceland_version_log to deegree;

INSERT INTO gns_iceland_version (RC, UFI, UNI, LAT, LONG, DMS_LAT, DMS_LONG, MGRS, JOG, FC, DSG, PC, CC1, ADM1, POP, ELEV, CC2, NT, LC, SHORT_FORM, GENERIC, SORT_NAME_RO, FULL_NAME_RO, FULL_NAME_ND_RO, SORT_NAME_RG, FULL_NAME_RG, FULL_NAME_ND_RG, NOTE, MODIFY_DATE, DISPLAY, NAME_RANK, NAME_LINK, TRANSL_CD, NM_MODIFY_DATE, F_EFCTV_DT, F_TERM_DT, geometry) SELECT RC, UFI, UNI, LAT, LONG, DMS_LAT, DMS_LONG, MGRS, JOG, FC, DSG, PC, CC1, ADM1, POP, ELEV, CC2, NT, LC, SHORT_FORM, GENERIC, SORT_NAME_RO, FULL_NAME_RO, FULL_NAME_ND_RO, SORT_NAME_RG, FULL_NAME_RG, FULL_NAME_ND_RG, NOTE, MODIFY_DATE, DISPLAY, NAME_RANK, NAME_LINK, TRANSL_CD, NM_MODIFY_DATE, F_EFCTV_DT, F_TERM_DT, geometry FROM import;

drop table import;