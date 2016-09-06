--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.9
-- Dumped by pg_dump version 9.3.9
-- Started on 2015-08-11 10:26:47 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 13 (class 2615 OID 86572)
-- Name: versions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA versions;


SET search_path = versions, pg_catalog;

--
-- TOC entry 1713 (class 1247 OID 86575)
-- Name: checkout; Type: TYPE; Schema: versions; Owner: -
--

CREATE TYPE checkout AS (
	mykey integer,
	action character varying,
	revision integer,
	systime bigint
);


--
-- TOC entry 1682 (class 1247 OID 89357)
-- Name: conflicts; Type: TYPE; Schema: versions; Owner: -
--

CREATE TYPE conflicts AS (
	objectkey bigint,
	mysystime bigint,
	myuser text,
	myversion_log_id bigint,
	conflict_systime bigint,
	conflict_user text,
	conflict_version_log_id bigint
);


--
-- TOC entry 1716 (class 1247 OID 86581)
-- Name: logview; Type: TYPE; Schema: versions; Owner: -
--

CREATE TYPE logview AS (
	revision integer,
	datum timestamp without time zone,
	project text,
	logmsg text
);


--
-- TOC entry 1323 (class 1255 OID 89358)
-- Name: pgvscheck(character varying); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvscheck(character varying) RETURNS SETOF conflicts
    LANGUAGE plpgsql
    AS $_$

  DECLARE
    inTable ALIAS FOR $1;
    mySchema TEXT;
    myTable TEXT;
    myPkey TEXT;
    message TEXT;
    myDebug TEXT;
    confExists record;
    myPkeyRec record;
    conflict BOOLEAN;
    conflictCheck versions.conflicts%rowtype;
    pos integer;
    versionLogTable TEXT;

  BEGIN	
    pos := strpos(inTable,'.');
    conflict := False;
  
    if pos=0 then 
        mySchema := 'public';
  	myTable := inTable; 
    else 
        mySchema := substr(inTable,0,pos);
        pos := pos + 1; 
        myTable := substr(inTable,pos);
    END IF;  
    
    versionLogTable := 'versions."'||mySchema||'_'||myTable||'_version_log"';   

  -- Pruefen ob und welche Spalte der Primarykey der Tabelle ist 
    select into myPkeyRec col.column_name 
    from information_schema.table_constraints as key,
         information_schema.key_column_usage as col
    where key.table_schema = mySchema::name
      and key.table_name = myTable::name
      and key.constraint_type='PRIMARY KEY'
      and key.constraint_name = col.constraint_name
      and key.table_catalog = col.table_catalog
      and key.table_schema = col.table_schema
      and key.table_name = col.table_name;	
  
    IF FOUND THEN
       myPkey := myPkeyRec.column_name;
    else
        RAISE EXCEPTION 'Table % does not have Primarykey defined', mySchema||'.'||myTable;
    END IF;    
    
/*
Check for conflicts before committing. When conflicts are existing stop the commit process 
with a listing of the conflicting objects.
*/    

    message := '';                                  
       
    myDebug := 'select a.'||myPkey||' as objectkey, 
                   a.systime as mysystime, 
                   a.project as myuser,
                   a.max as myversion_log_id,
                   b.systime as conflict_systime, 
                   b.project as conflict_user,
                   b.max as conflict_version_log_id
                                  from (select '||myPkey||', max(systime) as systime, max(version_log_id), project 
                                        from '||versionLogTable||'
                                        where project = current_user
                                              and not commit
                                        group by '||myPkey||', project) as a,
                                       (select foo.*, v.project 
                                        from '||versionLogTable||' as v,  
                                         (
                                           select '||myPkey||', max(systime) as systime, max(version_log_id)
                                           from '||versionLogTable||'
                                           where commit
                                             and project <> current_user
                                           group by '||myPkey||') as foo
                                         where v.version_log_id = foo.max
                                        ) as b
                                  where a.systime < b.systime
                                    and a.'||myPkey||' = b.'||myPkey;

--RAISE EXCEPTION '%',myDebug;           

      EXECUTE myDebug into confExists;                         
                                    
      for conflictCheck IN EXECUTE myDebug
      LOOP
        return next conflictCheck;
        conflict := True;
        message := message||E'\n'||'WARNING! The object with '||myPkey||'='||conflictCheck.objectkey||' is also changed by user '||conflictCheck.conflict_user||'.';
      END LOOP;    
              
      message := message||E'\n\n';
      message := message||'Changes are not committed!'||E'\n\n';
      RAISE NOTICE '%', message;
  END;


$_$;


--
-- TOC entry 1322 (class 1255 OID 89359)
-- Name: pgvscommit(character varying, text); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvscommit(character varying, text) RETURNS SETOF conflicts
    LANGUAGE plpgsql
    AS $_$

  DECLARE
    inTable ALIAS FOR $1;
    logMessage ALIAS FOR $2;
    mySchema TEXT;
    myTable TEXT;
    myPkey TEXT;
    fields TEXT;
    insFields TEXT;
    message TEXT;
    myDebug TEXT;
    commitQuery TEXT;
    checkQuery TEXT;
    myPkeyRec record;
    attributes record;
    testRec record;
    conflict BOOLEAN;
    conflictCheck versions.conflicts%rowtype;
    pos integer;
    versionLogTable TEXT;
    revision integer;

  BEGIN	
    pos := strpos(inTable,'.');
    fields := '';
    insFields := '';
    conflict := False;
  
    if pos=0 then 
        mySchema := 'public';
  	    myTable := inTable; 
    else 
        mySchema := substr(inTable,0,pos);
        pos := pos + 1; 
        myTable := substr(inTable,pos);
    END IF;  

    
    versionLogTable := 'versions."'||mySchema||'_'||myTable||'_version_log"';   

  -- Pruefen ob und welche Spalte der Primarykey der Tabelle ist 
    select into myPkeyRec col.column_name 
    from information_schema.table_constraints as key,
         information_schema.key_column_usage as col
    where key.table_schema = mySchema::name
      and key.table_name = myTable::name
      and key.constraint_type='PRIMARY KEY'
      and key.constraint_name = col.constraint_name
      and key.table_catalog = col.table_catalog
      and key.table_schema = col.table_schema
      and key.table_name = col.table_name;	
  
    IF FOUND THEN
       myPkey := myPkeyRec.column_name;
    else
        RAISE EXCEPTION 'Table % does not have Primarykey defined', mySchema||'.'||myTable;
    END IF;    
    
/*
Check for conflicts before committing. When conflicts are existing stop the commit process 
with a listing of the conflicting objects.
*/    
  message := '';
                                
                                    
    for conflictCheck IN  EXECUTE 'select * from versions.pgvscheck('''||mySchema||'.'||myTable||''')'
    LOOP

      return next conflictCheck;
      conflict := True;
      message := message||E'\n'||'WARNING! The object with '||myPkey||'='||conflictCheck.objectkey||' is also changed by user '||conflictCheck.project||'.';
    END LOOP;    
              
    message := message||E'\n\n';
    message := message||'Changes are not committed!'||E'\n\n';
    IF conflict THEN
       RAISE NOTICE '%', message;
    ELSE    
    
         execute 'create temp table tmp_tab as 
       select project
       from '||versionLogTable||'
       where not commit ';

         select into testRec project from tmp_tab;

        IF NOT FOUND THEN
          execute 'drop table tmp_tab';
          RETURN;
        ELSE  
          execute 'drop table tmp_tab';
          for attributes in select *
                            from  information_schema.columns
                            where table_schema=mySchema::name
                              and table_name = myTable::name

              LOOP
                
                if attributes.column_name <> 'OID' 
                  and attributes.column_name <> 'versionarchive' 
                  and attributes.column_name <> 'new_date' 
                  and  attributes.column_name <> 'archive_date' 
                  and  attributes.column_name <> 'archive' then
                    fields := fields||',log."'||attributes.column_name||'"';
                    insFields := insFields||',"'||attributes.column_name||'"';
                END IF;
              END LOOP;    
            
              fields := substring(fields,2);
              insFields := substring(insFields,2);     
            
          revision := nextval('versions."'||mySchema||'_'||myTable||'_revision_seq"');
         
          commitQuery := 'delete from '||versionLogTable||'
                using (
                    select log.* from '||versionLogTable||' as log,
                       ( 
                    select '||myPkey||', systime
                    from '||versionLogTable||'
                    where not commit and project = current_user
                    except
                    select '||myPkey||', max(systime) as systime
                    from '||versionLogTable||'
                    where not commit and project = current_user
                    group by '||myPkey||') as foo
                    where log.project = current_user
                      and foo.'||myPkey||' = log.'||myPkey||'
                      and foo.systime = log.systime
                      and not commit) as foo
                where '||versionLogTable||'.'||myPkey||' = foo.'||myPkey||'
                  and '||versionLogTable||'.systime = foo.systime
                  and '||versionLogTable||'.project = foo.project;
                  
              delete from "'||mySchema||'"."'||myTable||'" where '||myPkey||' in 
                   (select '||myPkey||'
                    from  '||versionLogTable||'
                             where not commit
                               and project = current_user
                             group by '||myPkey||', project);
   
              insert into "'||mySchema||'"."'||myTable||'" ('||insFields||') 
                    select '||fields||' from '||versionLogTable||' as log,
                       (
                        select '||myPKey||', max(systime) as systime, max(revision) as revision
                        from '||versionLogTable||'
                        where project = current_user
                          and not commit
                          and action <> ''delete''
                        group by '||myPKey||'
                       ) as foo
                    where log.'||myPkey||'= foo.'||myPkey||'
                      and log.systime = foo.systime
                      and log.action <> ''delete'';
                      
                update '||versionLogTable||' set 
                         commit = True, 
                         revision = '||revision||', 
                         logmsg = '''||logMessage ||''',    
                         systime = ' || EXTRACT(EPOCH FROM now()::TIMESTAMP)*1000 || '
                    where not commit
                      and project = current_user;';

--RAISE EXCEPTION '%',commitQuery;

     execute 'INSERT INTO versions.version_tables_logmsg(
                version_table_id, revision, logmsg) 
              SELECT version_table_id, '||revision||', '''||logMessage||''' as logmsg FROM versions.version_tables where version_table_schema = '''||mySchema||''' and version_table_name = '''|| myTable||''''; 
                      

        execute commitQuery;              
     END IF;
  END IF;    

  RETURN;                             

  END;


$_$;


--
-- TOC entry 1326 (class 1255 OID 86586)
-- Name: pgvsdiff(character varying, integer, integer); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvsdiff(character varying, integer, integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    inTable ALIAS FOR $1;
    majorRevision ALIAS FOR $2;
    minorRevision ALIAS FOR $3;
    mySchema TEXT;
    myTable TEXT;
    myPkey TEXT;
    message TEXT;
    diffQry TEXT;
    myPkeyRec record;
    conflict BOOLEAN;
    pos integer;
    versionLogTable TEXT;
    diffRec record;

  BEGIN	
    pos := strpos(inTable,'.');
    conflict := False;
  
    if pos=0 then 
        mySchema := 'public';
  	    myTable := inTable; 
    else 
        mySchema := substr(inTable,0,pos);
        pos := pos + 1; 
        myTable := substr(inTable,pos);
    END IF;  
    
    versionLogTable := 'versions.'||mySchema||'_'||myTable||'_version_log';   

  -- Pruefen ob und welche Spalte der Primarykey der Tabelle ist 
    select into myPkeyRec col.column_name 
    from information_schema.table_constraints as key,
         information_schema.key_column_usage as col
    where key.table_schema = mySchema::name
      and key.table_name = myTable::name
      and key.constraint_type='PRIMARY KEY'
      and key.constraint_name = col.constraint_name
      and key.table_catalog = col.table_catalog
      and key.table_schema = col.table_schema
      and key.table_name = col.table_name;	
  
    IF FOUND THEN
       myPkey := myPkeyRec.column_name;
    else
        RAISE EXCEPTION 'Table % does not have Primarykey defined', mySchema||'.'||myTable;
    END IF;    

     diffQry := ' select '||myPkey||',
                         case 
                           when count(action) = 2 then ''update''
                           else max(action)
                         end as action,
                         revision, systime, logmsg
            from (
            select '||myPkey||', action, revision, systime, logmsg 
            from '||versionLogTable||' 
            where revision = '||majorRevision||'
            union
            select '||myPkey||', action, revision, systime, logmsg 
            from '||versionLogTable||'  
            where revision = '||minorRevision||'
              and '||myPkey||' in (select '||myPkey||' from '||versionLogTable||' where revision = '||majorRevision||')
            order by '||myPkey||', revision desc, action desc) as foo
            group by '||myPkey||', systime, revision, logmsg
            order by revision desc, '||myPkey;

   
            
RAISE EXCEPTION '%', diffQry;            
            
    for diffRec IN  EXECUTE diffQry
    LOOP
      return next diffRec;
    END LOOP;    

 
  END;


$_$;


--
-- TOC entry 1324 (class 1255 OID 86587)
-- Name: pgvsdrop(character varying); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvsdrop(character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    inTable ALIAS FOR $1;
    pos INTEGER;
    mySchema TEXT;
    myTable TEXT;
    versionTableRec record;
    versionTable TEXT;
    versionView TEXT;
    versionLogTable TEXT;
    versionLogTableSeq TEXT;
    versionRevisionSeq TEXT;
    geomCol TEXT;
    geomType TEXT;
    geomDIM INTEGER;
    geomSRID INTEGER;
    testRec record;
    uncommitRec record;
    testTab TEXT;
    

  BEGIN	
    pos := strpos(inTable,'.');
    geomCol := '';
    geomDIM := 2;
    geomSRID := -1;
    geomType := '';

    if pos=0 then 
        mySchema := 'public';
  	    myTable := inTable; 
    else 
        mySchema = substr(inTable,0,pos);
        pos := pos + 1; 
        myTable = substr(inTable,pos);
    END IF;  

    versionView := '"'||mySchema||'"."'||myTable||'_version"';
    versionLogTable := 'versions."'||mySchema||'_'||myTable||'_version_log"';
    versionLogTableSeq := 'versions."'||mySchema||'_'||myTable||'_version_log_version_log_id_seq"';
    versionRevisionSeq := 'versions."'||mySchema||'_'||myTable||'_revision_seq"';

-- Feststellen ob die Tabelle existiert
     select into testRec table_name
     from information_schema.tables
     where table_schema = mySchema::name
          and table_name = myTable::name;

     IF NOT FOUND THEN
       RAISE EXCEPTION 'Table %.% does not exist', mySchema,myTable;
       RETURN False;
     END IF;    
     
-- Feststellen ob die Log-Tabelle existiert
     testTab := mySchema||'_'||myTable||'_version_log';
     
     select into testRec table_name
     from information_schema.tables
     where table_schema = 'versions'
          and table_name = testTab::name;

     IF NOT FOUND THEN
       RAISE EXCEPTION 'Log Table %.% does not exist', mySchema,myTable;
       RETURN False;
     END IF;        
 
     
-- Die grundlegenden Geometrieparameter des Ausgangslayers ermitteln
     select into testRec f_geometry_column, coord_dimension, srid, type
     from geometry_columns
     where f_table_schema = mySchema::name
       and f_table_name = myTable::name;

     geomCol := testRec.f_geometry_column;
     geomDIM := testRec.coord_dimension;
     geomSRID := testRec.srid;
     geomType := testRec.type;

     execute 'create temp table tmp_tab on commit drop as 
       select project
       from '||versionLogTable||'
       where not commit ';

     select into testRec project from tmp_tab;

     IF FOUND THEN

       for uncommitRec in select distinct project from tmp_tab loop
         RAISE NOTICE 'Uncommitted Records are existing for user %. Please commit all changes before use pgvsdrop()', uncommitRec.project;
       end loop;
   --    execute 'drop table tmp_tab';
       RETURN False;
     END IF;  

     IF FOUND THEN
       RAISE EXCEPTION 'Uncommitted Records are existing. Please commit all changes before use pgvsdrop()';
       RETURN False;
     END IF;  

     select into versionTableRec version_table_id as vtid
     from versions.version_tables as vt
     where version_table_schema = mySchema::name
       and version_table_name = myTable::name;

     

    execute 'drop table if exists '||versionLogTable||' cascade;';
    execute 'DROP SEQUENCE if exists '||versionLogTableSeq;
    execute 'DROP SEQUENCE if exists '||versionRevisionSeq;


    
    execute 'delete from versions.version_tables 
               where version_table_id = '''||versionTableRec.vtid||''';';

    execute 'delete from versions.version_tables_logmsg 
               where version_table_id = '''||versionTableRec.vtid||''';';


  RETURN true ;                             

  END;
$_$;


--
-- TOC entry 1317 (class 1255 OID 86588)
-- Name: pgvsinit(character varying); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvsinit(character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    inTable ALIAS FOR $1;
    pos INTEGER;
    mySchema TEXT;
    myTable TEXT;
    versionTable TEXT;
    versionView TEXT;
    versionLogTable TEXT;
    versionLogTableSeq TEXT;
    versionLogTableTmp TEXT;
    geomCol TEXT;
    geomType TEXT;
    geomDIM INTEGER;
    geomSRID INTEGER;
    attributes record;
    testRec record;
    testPKey record;
    fields TEXT;
    newFields TEXT;
    oldFields TEXT;
    updateFields TEXT;
    mySequence TEXT;
    myPkey TEXT;
    myPkeyRec record;
    testTab TEXT;
    archiveWhere TEXT;
    

  BEGIN	
    pos := strpos(inTable,'.');
    fields := '';
    newFields := '';
    oldFields := '';
    updateFields := '';
    geomCol := '';
    geomDIM := 2;
    geomSRID := -1;
    geomType := '';
    mySequence := '';
    archiveWhere := '';

    if pos=0 then 
        mySchema := 'public';
  	myTable := inTable; 
    else 
        mySchema = substr(inTable,0,pos);
        pos := pos + 1; 
        myTable = substr(inTable,pos);
    END IF;  

    versionTable := '"'||mySchema||'"."'||myTable||'_version_t"';
    versionView := '"'||mySchema||'"."'||myTable||'_version"';
    versionLogTable := 'versions."'||mySchema||'_'||myTable||'_version_log"';
    versionLogTableSeq := 'versions."'||mySchema||'_'||myTable||'_version_log_version_log_id_seq"';
    versionLogTableTmp := 'versions."'||mySchema||'_'||myTable||'_version_log_tmp"';

-- Feststellen ob die Tabelle oder der View existiert
     select into testRec table_name
     from information_schema.tables
     where table_schema = mySchema::name
          and table_name = myTable::name;

     IF NOT FOUND THEN
       select into testRec table_name
       from information_schema.views
       where table_schema = mySchema::name
            and table_name = myTable::name;     
       IF NOT FOUND THEN
         RAISE EXCEPTION 'Table %.% does not exist', mySchema,myTable;
         RETURN False;
       END IF;
     END IF;    
 
 
-- Die grundlegenden Geometrieparameter des Ausgangslayers ermitteln
     select into testRec f_geometry_column, coord_dimension, srid, type
     from geometry_columns
     where f_table_schema = mySchema::name
       and f_table_name = myTable::name;

     IF NOT FOUND THEN
       RAISE EXCEPTION 'Table %.% is not registered in geometry_columns', mySchema, myTable;
       RETURN False;
     END IF;

     geomCol := testRec.f_geometry_column;
     geomDIM := testRec.coord_dimension;
     geomSRID := testRec.srid;
     geomType := testRec.type;

     
-- Pruefen ob und welche Spalte der Primarykey der Tabelle old_layer ist 
    select into testPKey col.column_name 
    from information_schema.table_constraints as key,
         information_schema.key_column_usage as col
    where key.table_schema = mySchema::name
      and key.table_name = myTable::name
      and key.constraint_type='PRIMARY KEY'
      and key.constraint_name = col.constraint_name
      and key.table_catalog = col.table_catalog
      and key.table_schema = col.table_schema
      and key.table_name = col.table_name;	
  
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Table %.% has no Primarykey', mySchema, myTable;
        RETURN False;
    END IF;			
       
-- Feststellen ob die Tabelle bereits besteht
     testTab := '"versions"."'||myTable||'_version_log"';
     select into testRec table_name
     from information_schema.tables
     where table_schema = mySchema::name
          and table_name = testTab::name;

     IF FOUND THEN
       RAISE NOTICE 'Table %.% has been deleted', mySchema,testTab;
       execute 'drop table "'||mySchema||'"."'||testTab||'" cascade';
     END IF;    
  
-- Feststellen ob die Log-Tabelle bereits in geometry_columns registriert ist
     select into testRec f_table_name
     from geometry_columns
     where f_table_schema = mySchema::name
          and f_table_name = testTab::name;
          
     IF FOUND THEN
       execute 'delete from geometry_columns where f_table_schema='''||mySchema||''' and f_table_name='''||myTable||'_version_log''';
     END IF;    

-- Feststellen ob der View bereits in geometry_columns registriert ist
     testTab := '"'||mySchema||'"."'||myTable||'_version"';
     select into testRec f_table_name
     from geometry_columns
     where f_table_schema = mySchema::name
          and f_table_name = testTab::name;

     IF FOUND THEN
       execute 'delete from geometry_columns where f_table_schema='''||mySchema||''' and f_table_name='''||myTable||'_version''';
     END IF;    
     
     
  -- Pruefen ob und welche Spalte der Primarykey der Tabelle ist 
    select into myPkeyRec col.column_name 
    from information_schema.table_constraints as key,
         information_schema.key_column_usage as col
    where key.table_schema = mySchema::name
      and key.table_name = myTable::name
      and key.constraint_type='PRIMARY KEY'
      and key.constraint_name = col.constraint_name
      and key.table_catalog = col.table_catalog
      and key.table_schema = col.table_schema
      and key.table_name = col.table_name;	
  
    IF FOUND THEN
       myPkey := '"'||myPkeyRec.column_name||'"';
    else
        RAISE EXCEPTION 'Table % has no Primarykey', mySchema||'.'||myTable;
        RETURN False;
    END IF;

    execute 'create table '||versionLogTable||' (LIKE "'||mySchema||'"."'||myTable||'");
             create sequence versions."'||mySchema||'_'||myTable||'_revision_seq" INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1;
             alter table '||versionLogTable||' add column version_log_id bigserial;
             alter table '||versionLogTable||' add column action character varying;
             alter table '||versionLogTable||' add column project character varying default current_user;     
             alter table '||versionLogTable||' add column systime bigint default extract(epoch from now()::timestamp)*1000;    
             alter table '||versionLogTable||' add column revision bigint;
             alter table '||versionLogTable||' add column logmsg text;        
             alter table '||versionLogTable||' add column commit boolean DEFAULT False;
             alter table '||versionLogTable||' add constraint '||myTable||'_pkey primary key ('||myPkey||',project,systime,action);
             CREATE INDEX '||mySchema||'_'||myTable||'_version_log_id_idx ON '||versionLogTable||' USING btree (version_log_id);
             
             create index '||myTable||'_version_geo_idx on '||versionLogTable||' USING GIST ('||geomCol||');     
             insert into versions.version_tables (version_table_schema,version_table_name,version_view_schema,version_view_name,version_view_pkey,version_view_geometry_column) 
                 values('''||mySchema||''','''||myTable||''','''||mySchema||''','''||myTable||'_version'','''||testPKey.column_name||''','''||geomCol||''');
             insert into public.geometry_columns (f_table_catalog, f_table_schema,f_table_name,f_geometry_column,coord_dimension,srid,type)
                 values ('''',''versions'','''||myTable||'_version_log'','''||geomCol||''','||geomDIM||','||geomSRID||','''||geomTYPE||''');
             insert into public.geometry_columns (f_table_catalog, f_table_schema,f_table_name,f_geometry_column,coord_dimension,srid,type)
               values ('''','''||mySchema||''','''||myTable||'_version'','''||geomCol||''','||geomDIM||','||geomSRID||','''||geomTYPE||''');';
    
    for attributes in select *
                      from  information_schema.columns
                      where table_schema=mySchema::name
                        and table_name = myTable::name

        LOOP
          
          if attributes.column_default LIKE 'nextval%' then
--             execute 'alter table '||versionLogTable||' alter column '||attributes.column_name||' drop not null';
             mySequence := attributes.column_default;
          ELSE
            if myPkey <> attributes.column_name then
              fields := fields||',"'||attributes.column_name||'"';
              newFields := newFields||',new."'||attributes.column_name||'"';
              oldFields := oldFields||',old."'||attributes.column_name||'"';
              updateFields := updateFields||',"'||attributes.column_name||'"=new."'||attributes.column_name||'"';
            END IF;
          END IF;
          IF attributes.column_name = 'archive' THEN
            archiveWhere := 'and archive=0';           
          END IF;  
        END LOOP;

-- Das erste Komma  aus dem String entfernen
        fields := substring(fields,2);
        newFields := substring(newFields,2);
        oldFields := substring(oldFields,2);
        updateFields := substring(updateFields,2);
        
        IF length(mySequence)=0 THEN
          RAISE EXCEPTION 'No Sequence defined for Table %.%', mySchema,myTable;
          RETURN False;
        END IF;
     


            
     execute 'create or replace view '||versionView||' as 
                SELECT v.'||myPkey||','||fields||',NULL as version_log_id,NULL as action,NULL as systime
                FROM "'||mySchema||'"."'||myTable||'" v,
                  ( SELECT "'||mySchema||'"."'||myTable||'".'||myPkey||'
                    FROM "'||mySchema||'"."'||myTable||'"
                    EXCEPT
                    SELECT v_1.'||myPkey||'
                    FROM '||versionLogTable||' v_1,
                     ( SELECT v_2.'||myPkey||',
                              max(v_2.version_log_id) AS version_log_id
                       FROM '||versionLogTable||' v_2
                       WHERE NOT v_2.commit AND v_2.project::name = "current_user"()
                       GROUP BY v_2.'||myPkey||') foo_1
                    WHERE v_1.version_log_id = foo_1.version_log_id) foo
                WHERE v.'||myPkey||' = foo.'||myPkey||'
                UNION
                SELECT v.'||myPkey||','||fields||',v.version_log_id,v.action,to_timestamp(v.systime/1000) as systime
                FROM '||versionLogTable||' v,
                 ( SELECT v_1.'||myPkey||',
                          max(v_1.version_log_id) AS version_log_id
                   FROM '||versionLogTable||' v_1
                   WHERE NOT v_1.commit AND v_1.project::name = "current_user"()
                   GROUP BY v_1.'||myPkey||') foo
                WHERE v.version_log_id = foo.version_log_id';


    execute 'CREATE OR REPLACE RULE delete AS
                ON DELETE TO '||versionView||' DO INSTEAD  
                INSERT INTO '||versionLogTable||' ('||myPkey||','||fields||',action) VALUES (old.'||myPkey||','||oldFields||',''delete'')';                

       
    execute 'CREATE OR REPLACE RULE insert AS
                ON INSERT TO '||versionView||' DO INSTEAD  
                INSERT INTO '||versionLogTable||' ('||myPkey||','||fields||',action) VALUES ('||mySequence||','||newFields||',''insert'') RETURNING ' ||myPkey||','||fields||',version_log_id,action,to_timestamp(systime/1000)';
          
     execute 'CREATE OR REPLACE RULE update AS
                ON UPDATE TO '||versionView||' DO INSTEAD  
                INSERT INTO '||versionLogTable||' ('||myPkey||','||fields||',action) VALUES (old.'||myPkey||','||newFields||',''update'')'; 

     execute 'INSERT INTO '||versionLogTable||' ('||myPkey||','||fields||', action, revision, logmsg, commit ) 
                select '||myPkey||','||fields||', ''insert'' as action, 0 as revision, ''initial commit revision 0'' as logmsg, ''t'' as commit 
                from "'||mySchema||'"."'||myTable||'"';                          

     execute 'INSERT INTO versions.version_tables_logmsg(
                version_table_id, revision, logmsg) 
              SELECT version_table_id, 0 as revision, ''initial commit revision 0'' as logmsg FROM versions.version_tables where version_table_schema = '''||mySchema||''' and version_table_name = '''|| myTable||''''; 

    execute 'GRANT ALL ON TABLE '||versionLogTable||' TO version';
    execute 'GRANT ALL ON TABLE '||versionLogTableSeq||' TO version';
    execute 'GRANT ALL ON TABLE '||versionView||' TO version';
    execute 'GRANT ALL ON sequence versions."'||mySchema||'_'||myTable||'_revision_seq" to version'; 
    
                
  RETURN true ;                             

  END;
$_$;


--
-- TOC entry 1318 (class 1255 OID 86591)
-- Name: pgvslogview(character varying); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvslogview(character varying) RETURNS SETOF logview
    LANGUAGE plpgsql
    AS $_$    
  DECLARE
    inTable ALIAS FOR $1;
    mySchema TEXT;
    myTable TEXT;
    logViewQry TEXT;
    versionLogTable TEXT;
    pos integer;
    logs versions.logview%rowtype;


  BEGIN	
    pos := strpos(inTable,'.');
  
    if pos=0 then 
        mySchema := 'public';
  	    myTable := inTable; 
    else 
        mySchema := substr(inTable,0,pos);
        pos := pos + 1; 
        myTable := substr(inTable,pos);
    END IF;  
    
    versionLogTable := 'versions."'||mySchema||'_'||myTable||'_version_log"';       

    logViewQry := 'select logt.revision, to_timestamp(logt.systime/1000), logt.project,  logt.logmsg
                           from  versions.version_tables as vt, versions.version_tables_logmsg as logt
                           where vt.version_table_id = logt.version_table_id
                             and vt.version_table_schema = '''||mySchema||'''
                             and vt.version_table_name = '''||myTable||''' 
                           order by revision desc';

--RAISE EXCEPTION '%', logViewQry;

                           
    for logs IN  EXECUTE logViewQry
    LOOP

      return next logs;    
    end loop;                       
  
  END;
$_$;


--
-- TOC entry 1325 (class 1255 OID 89337)
-- Name: pgvsmerge(character varying, integer, character varying); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvsmerge("inTable" character varying, "targetGid" integer, "targetProject" character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$  DECLARE
    inTable ALIAS FOR $1;
    targetGid ALIAS FOR $2;
    targetProject ALIAS FOR $3;
    sourceProject TEXT;
    mySchema TEXT;
    myTable TEXT;
    myPkey TEXT;
    myDebug TEXT;
    myMerge TEXT;
    myDelete TEXT;
    myPkeyRec record;
    myTimestamp bigint;
    conflict BOOLEAN;
    merged BOOLEAN;
    conflictCheck record;
    cols TEXT;
    pos integer;
    versionLogTable TEXT;

  BEGIN	
    sourceProject := current_user;
    pos := strpos(inTable,'.');
    conflict := False;
    merged := False;
  
    if pos=0 then 
        mySchema := 'public';
  	    myTable := inTable; 
    else 
        mySchema := substr(inTable,0,pos);
        pos := pos + 1; 
        myTable := substr(inTable,pos);
    END IF;  
    
    versionLogTable := 'versions."'||mySchema||'_'||myTable||'_version_log"';   

  -- Pruefen ob und welche Spalte der Primarykey der Tabelle ist 
    select into myPkeyRec col.column_name 
    from information_schema.table_constraints as key,
         information_schema.key_column_usage as col
    where key.table_schema = mySchema::name
      and key.table_name = myTable::name
      and key.constraint_type='PRIMARY KEY'
      and key.constraint_name = col.constraint_name
      and key.table_catalog = col.table_catalog
      and key.table_schema = col.table_schema
      and key.table_name = col.table_name;	
  
    IF FOUND THEN
       myPkey := myPkeyRec.column_name;
    else
        RAISE EXCEPTION 'Table % does not have Primarykey defined', mySchema||'.'||myTable;
        RETURN False;
    END IF;    
        

        
myDebug := 'select a.'||myPkey||' as objectkey, 
                   a.systime as mysystime, 
                   a.project as myuser,
                   b.systime as conflict_systime, 
                   b.project as conflict_user,
                   b.max as conflict_version_log_id
                                  from (select '||myPkey||', max(systime) as systime, max(version_log_id), project 
                                        from '||versionLogTable||'
                                        where project = '''||targetProject||'''
                                              and not commit
                                              and '||myPkey||' = '||targetGid||'
                                        group by '||myPkey||', project) as a,
                                       (
                                         select '||myPkey||', max(systime) as systime, max(version_log_id), project
                                         from '||versionLogTable||'
                                         where commit
                                           and project <> '''||targetProject||'''
                                         group by '||myPkey||', project
                                        ) as b
                                  where a.systime < b.systime
                                    and a.'||myPkey||' = b.'||myPkey||'
                                    and a.'||myPkey||' = '||targetGid; 
                                    
                                                                 
-- RAISE EXCEPTION '%',myDebug;    

    execute 'SELECT array_to_string(array_agg(quote_ident(column_name::name)), '','')
             FROM information_schema.columns 
             WHERE (table_schema, table_name) = ($1, $2)' into cols using mySchema, myTable;  

     myTimestamp := round(extract(epoch from now()::timestamp)*1000);
    
    for conflictCheck IN EXECUTE myDebug
    LOOP
       RAISE NOTICE '%  %  %  %  %  %',conflictCheck.objectkey,
                           conflictCheck.mysystime,
                           conflictCheck.myuser,
                           conflictCheck.conflict_systime, 
                           conflictCheck.conflict_user,
                           conflictCheck.conflict_version_log_id;         

       myMerge := 'insert into '||versionLogTable||' ('||cols||', action, project, systime)
                      select '||cols||', action, '''||targetProject||''' as project, 
                        '||myTimestamp||' as systime
                      from '||versionLogTable||' as v,
                        (
                         select max(systime) as systime
                         from '||versionLogTable||'
                         where project = '''||targetProject||'''
                           and '||myPkey||' = '||targetGid||'
                         group by '||myPkey||'
                        ) as foo
                      where '||myPkey||' = '||targetGid||' 
                         and v.systime = foo.systime '; 
                         
        execute myMerge;
      
      merged := True;
                     

     END LOOP;     

     if sourceProject <> targetProject then
       myDelete := 'delete from '||versionLogTable||' 
                       where '||myPkey||' = '||targetGid||' 
                          and project = '''||sourceProject||'''
                          and not commit 
                          and systime < '||myTimestamp;

--       RAISE EXCEPTION '%', myDelete;                             
       execute myDelete;
     end if;

                        


  
  RETURN True;
  
  END;$_$;


--
-- TOC entry 1319 (class 1255 OID 86593)
-- Name: pgvsrevert(character varying); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvsrevert(character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    inTable ALIAS FOR $1;
    pos INTEGER;
    mySchema TEXT;
    myTable TEXT;
    versionTable TEXT;
    versionView TEXT;
    versionLogTable TEXT;
    geomCol TEXT;
    geomType TEXT;
    geomDIM INTEGER;
    geomSRID INTEGER;
    revision INTEGER;
    testRec record;
    testTab TEXT;
    

  BEGIN	
    pos := strpos(inTable,'.');
    geomCol := '';
    geomDIM := 2;
    geomSRID := -1;
    geomType := '';

    if pos=0 then 
        mySchema := 'public';
  	    myTable := inTable; 
    else 
        mySchema = substr(inTable,0,pos);
        pos := pos + 1; 
        myTable = substr(inTable,pos);
    END IF;  

    versionView := mySchema||'.'||myTable||'_version';
    versionLogTable := 'versions."'||mySchema||'_'||myTable||'_version_log"';

-- Feststellen ob die Tabelle existiert
     select into testRec table_name
     from information_schema.tables
     where table_schema = mySchema::name
          and table_name = myTable::name;

     IF NOT FOUND THEN
       RAISE EXCEPTION 'Table %.% does not exist', mySchema,myTable;
       RETURN False;
     END IF;    
     
-- Feststellen ob die Log-Tabelle existiert
     testTab := mySchema||'_'||myTable||'_version_log';
     
     select into testRec table_name
     from information_schema.tables
     where table_schema = 'versions'
          and table_name = testTab::name;

     IF NOT FOUND THEN
       RAISE EXCEPTION 'Log Table %.% does not exist', mySchema,myTable;
       RETURN False;
     END IF;        
 
     execute 'select max(revision) from '||versionLogTable into revision;
     
     execute 'delete from '||versionLogTable||' 
                    where project = current_user
                      and not commit';
                    
  RETURN revision ;                             

  END;
$_$;


--
-- TOC entry 1320 (class 1255 OID 86594)
-- Name: pgvsrevision(); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvsrevision() RETURNS text
    LANGUAGE plpgsql
    AS $$    
DECLARE
  revision TEXT;
  BEGIN	
    revision := '1.8.4';
  RETURN revision ;                             

  END;
$$;


--
-- TOC entry 1327 (class 1255 OID 86595)
-- Name: pgvsrollback(character varying, integer); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvsrollback(character varying, integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    inTable ALIAS FOR $1;
    myRevision ALIAS FOR $2;
    pos INTEGER;
    mySchema TEXT;
    myTable TEXT;
    versionTable TEXT;
    versionView TEXT;
    versionLogTable TEXT;
    attributes record;
    fields TEXT;
    archiveWhere TEXT;
    myPKeyRec Record;
    myPkey Text;
    rollbackQry Text;
    myInsertFields Text;
    

  BEGIN	
    pos := strpos(inTable,'.');
    fields := '';
    myInsertFields := '';
    archiveWhere := '';


    if pos=0 then 
        mySchema := 'public';
  	    myTable := inTable; 
    else 
        mySchema = substr(inTable,0,pos);
        pos := pos + 1; 
        myTable = substr(inTable,pos);
    END IF;  
    
  -- Pruefen ob und welche Spalte der Primarykey der Tabelle ist 
    select into myPkeyRec col.column_name 
    from information_schema.table_constraints as key,
         information_schema.key_column_usage as col
    where key.table_schema = mySchema::name
      and key.table_name = myTable::name
      and key.constraint_type='PRIMARY KEY'
      and key.constraint_name = col.constraint_name
      and key.table_catalog = col.table_catalog
      and key.table_schema = col.table_schema
      and key.table_name = col.table_name;	
  
    myPkey := myPkeyRec.column_name;

    versionTable := '"'||mySchema||'"."'||myTable||'_version_t"';
    versionView := '"'||mySchema||'"."'||myTable||'_version"';
    versionLogTable := 'versions."'||mySchema||'_'||myTable||'_version_log"';
    
    for attributes in select *
                               from  information_schema.columns
                               where table_schema=mySchema::name
                                    and table_name = myTable::name

        LOOP
          
          if attributes.column_name not in ('action','project','systime','revision','logmsg','commit') then
            fields := fields||',v."'||attributes.column_name||'"';
            myInsertFields := myInsertFields||',"'||attributes.column_name||'"';
          END IF;

          END LOOP;

-- Das erste Komma  aus dem String entfernen
        fields := substring(fields,2);
        myInsertFields := substring(myInsertFields,2);


execute 'select versions.pgvsrevert('''||mySchema||'.'||myTable||''')';

rollbackQry := 'insert into '||versionLogTable||' ('||myInsertFields||', action)
                select '||fields||', ''delete'' as action 
                from '||versionLogTable||' as v, 
                  (select v.'||myPkey||', max(v.version_log_id) as version_log_id
                   from '||versionLogTable||' as v,
                (select v.'||myPkey||'
                 from '||versionLogTable||' as v,
                  (select v.'||myPkey||'
                   from '||versionLogTable||' as v
                   where revision > '||myRevision||'
                   except
                   select v.'||myPkey||'
                   from '||versionLogTable||' as v
                   where revision <= '||myRevision||'
                  ) as foo
                 where v.'||myPkey||' = foo.'||myPkey||') as foo
               where v.'||myPkey||' = foo.'||myPkey||'    
               group by v.'||myPkey||') as foo
              where v.version_log_id = foo.version_log_id

              union

                select '||fields||', v.action 
                from '||versionLogTable||' as v, 
                  (select v.'||myPkey||', max(v.version_log_id) as version_log_id
                   from '||versionLogTable||' as v,
                     (select v.'||myPkey||' 
                      from '||versionLogTable||' as v
                      where revision > '||myRevision||'
                except
                 (select v.'||myPkey||'
                  from '||versionLogTable||' as v
                  where revision > '||myRevision||'
                  except
                  select v.'||myPkey||'
                  from '||versionLogTable||' as v
                  where revision <= '||myRevision||' 
                 )) as foo
                 where revision <= '||myRevision||' and v.'||myPkey||' = foo.'||myPkey||'    
                group by v.'||myPkey||') as foo
              where v.version_log_id = foo.version_log_id';

  
 --RAISE EXCEPTION '%', rollbackQry;

      execute rollbackQry;
              
--      execute 'select * from versions.pgvscommit('''||mySchema||'.'||myTable||''',''Rollback to Revision '||myRevision||''')';

  RETURN true ;                             

  END;
$_$;


--
-- TOC entry 1321 (class 1255 OID 86596)
-- Name: pgvsupdatecheck(character varying); Type: FUNCTION; Schema: versions; Owner: -
--

CREATE FUNCTION pgvsupdatecheck(character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$    
DECLARE
  inRevision ALIAS FOR $1;
  aktRevision TEXT;
  inMajor integer;
  inMinor integer;
  aktMajor integer;
  aktMinor integer;

  
  BEGIN	
      inMajor = to_number(substr(inRevision,1,1),'9');
      inMinor = to_number(substr(inRevision,3,1),'9');
      aktMajor = to_number(substr(versions.pgvsrevision(),1,1),'9');
      aktMinor = to_number(substr(versions.pgvsrevision(),3,1),'9');
      
      if aktMinor>=7 and inMinor<7 THEN
        execute 'select versions._update07()';
        return False;
      ELSE
        return True;
      END IF;
      
  RETURN revision ;                             

  END;
$_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 247 (class 1259 OID 94491)
-- Name: public_streets_version_log; Type: TABLE; Schema: versions; Owner: -; Tablespace: 
--

CREATE TABLE public_streets_version_log (
    id_0 integer NOT NULL,
    geom public.geometry(MultiLineString,4326),
    id integer,
    type character varying(30),
    name character varying(190),
    oneway character varying(9),
    lanes double precision,
    trunk_rev_begin integer,
    trunk_rev_end integer,
    trunk_parent integer,
    trunk_child integer,
    version_log_id bigint NOT NULL,
    action character varying NOT NULL,
    project character varying DEFAULT "current_user"() NOT NULL,
    systime bigint DEFAULT (date_part('epoch'::text, (now())::timestamp without time zone) * (1000)::double precision) NOT NULL,
    revision bigint,
    logmsg text,
    commit boolean DEFAULT false
);


--
-- TOC entry 248 (class 1259 OID 94497)
-- Name: public_streets_revision_seq; Type: SEQUENCE; Schema: versions; Owner: -
--

CREATE SEQUENCE public_streets_revision_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 249 (class 1259 OID 94499)
-- Name: public_streets_version_log_version_log_id_seq; Type: SEQUENCE; Schema: versions; Owner: -
--

CREATE SEQUENCE public_streets_version_log_version_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3309 (class 0 OID 0)
-- Dependencies: 249
-- Name: public_streets_version_log_version_log_id_seq; Type: SEQUENCE OWNED BY; Schema: versions; Owner: -
--

ALTER SEQUENCE public_streets_version_log_version_log_id_seq OWNED BY public_streets_version_log.version_log_id;


--
-- TOC entry 233 (class 1259 OID 86597)
-- Name: version_tables; Type: TABLE; Schema: versions; Owner: -; Tablespace: 
--

CREATE TABLE version_tables (
    version_table_id bigint NOT NULL,
    version_table_schema character varying,
    version_table_name character varying,
    version_view_schema character varying,
    version_view_name character varying,
    version_view_pkey character varying,
    version_view_geometry_column character varying
);


--
-- TOC entry 234 (class 1259 OID 86603)
-- Name: version_tables_logmsg; Type: TABLE; Schema: versions; Owner: -; Tablespace: 
--

CREATE TABLE version_tables_logmsg (
    id bigint NOT NULL,
    version_table_id bigint,
    revision character varying,
    logmsg character varying,
    systime bigint DEFAULT (date_part('epoch'::text, now()) * (1000)::double precision),
    project character varying DEFAULT "current_user"()
);


--
-- TOC entry 235 (class 1259 OID 86611)
-- Name: version_tables_logmsg_id_seq; Type: SEQUENCE; Schema: versions; Owner: -
--

CREATE SEQUENCE version_tables_logmsg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3310 (class 0 OID 0)
-- Dependencies: 235
-- Name: version_tables_logmsg_id_seq; Type: SEQUENCE OWNED BY; Schema: versions; Owner: -
--

ALTER SEQUENCE version_tables_logmsg_id_seq OWNED BY version_tables_logmsg.id;


--
-- TOC entry 236 (class 1259 OID 86613)
-- Name: version_tables_version_table_id_seq; Type: SEQUENCE; Schema: versions; Owner: -
--

CREATE SEQUENCE version_tables_version_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3311 (class 0 OID 0)
-- Dependencies: 236
-- Name: version_tables_version_table_id_seq; Type: SEQUENCE OWNED BY; Schema: versions; Owner: -
--

ALTER SEQUENCE version_tables_version_table_id_seq OWNED BY version_tables.version_table_id;


--
-- TOC entry 3173 (class 2604 OID 94501)
-- Name: version_log_id; Type: DEFAULT; Schema: versions; Owner: -
--

ALTER TABLE ONLY public_streets_version_log ALTER COLUMN version_log_id SET DEFAULT nextval('public_streets_version_log_version_log_id_seq'::regclass);


--
-- TOC entry 3169 (class 2604 OID 86615)
-- Name: version_table_id; Type: DEFAULT; Schema: versions; Owner: -
--

ALTER TABLE ONLY version_tables ALTER COLUMN version_table_id SET DEFAULT nextval('version_tables_version_table_id_seq'::regclass);


--
-- TOC entry 3172 (class 2604 OID 86616)
-- Name: id; Type: DEFAULT; Schema: versions; Owner: -
--

ALTER TABLE ONLY version_tables_logmsg ALTER COLUMN id SET DEFAULT nextval('version_tables_logmsg_id_seq'::regclass);


--
-- TOC entry 3184 (class 2606 OID 94530)
-- Name: streets_pkey; Type: CONSTRAINT; Schema: versions; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public_streets_version_log
    ADD CONSTRAINT streets_pkey PRIMARY KEY (id_0, project, systime, action);


--
-- TOC entry 3178 (class 2606 OID 86618)
-- Name: version_table_pkey; Type: CONSTRAINT; Schema: versions; Owner: -; Tablespace: 
--

ALTER TABLE ONLY version_tables
    ADD CONSTRAINT version_table_pkey PRIMARY KEY (version_table_id);


--
-- TOC entry 3181 (class 2606 OID 86620)
-- Name: version_tables_logmsg_pkey; Type: CONSTRAINT; Schema: versions; Owner: -; Tablespace: 
--

ALTER TABLE ONLY version_tables_logmsg
    ADD CONSTRAINT version_tables_logmsg_pkey PRIMARY KEY (id);


--
-- TOC entry 3179 (class 1259 OID 86621)
-- Name: fki_version_tables_fkey; Type: INDEX; Schema: versions; Owner: -; Tablespace: 
--

CREATE INDEX fki_version_tables_fkey ON version_tables_logmsg USING btree (version_table_id);


--
-- TOC entry 3182 (class 1259 OID 94531)
-- Name: public_streets_version_log_id_idx; Type: INDEX; Schema: versions; Owner: -; Tablespace: 
--

CREATE INDEX public_streets_version_log_id_idx ON public_streets_version_log USING btree (version_log_id);


--
-- TOC entry 3185 (class 1259 OID 94532)
-- Name: streets_version_geo_idx; Type: INDEX; Schema: versions; Owner: -; Tablespace: 
--

CREATE INDEX streets_version_geo_idx ON public_streets_version_log USING gist (geom);


--
-- TOC entry 3186 (class 2606 OID 86622)
-- Name: version_tables_fkey; Type: FK CONSTRAINT; Schema: versions; Owner: -
--

ALTER TABLE ONLY version_tables_logmsg
    ADD CONSTRAINT version_tables_fkey FOREIGN KEY (version_table_id) REFERENCES version_tables(version_table_id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2015-08-11 10:26:50 CEST

--
-- PostgreSQL database dump complete
--

