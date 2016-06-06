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
MODIFY_DATE varchar,
DISPLAY varchar,
NAME_RANK numeric,
NAME_LINK numeric,
TRANSL_CD varchar,
NM_MODIFY_DATE varchar,
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
create table gns_iceland as select * from import ;
grant all on gns_iceland to deegree ;

create sequence gns_iceland_seq;
alter table gns_iceland add column id integer default nextval('gns_iceland_seq');

drop table import;