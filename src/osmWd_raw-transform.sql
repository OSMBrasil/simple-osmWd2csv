/**
 * Transfer from CSV and transform OSM-Wikidata Bigdata.
 * @dependences (SQL) osmWd_lib.sql
 * @dependences (file system) cp data/LI_wdDump.raw.csv /tmp
 */


CREATE EXTENSION file_fdw;
CREATE SERVER files FOREIGN DATA WRAPPER file_fdw;

DROP SCHEMA IF EXISTS wdosm CASCADE;
CREATE SCHEMA wdosm;

-- temp only from transfer
CREATE FOREIGN TABLE wdosm.li_raw (
   osm_type text,
   osm_id bigint,
   "otherIDs" text
) SERVER files OPTIONS (
   filename '/tmp/LI_wdDump.raw.csv',
   format 'csv',
   header 'true'
);
---

CREATE TABLE wdosm.li_raw2 AS
  SELECT  osm_type, osm_id,
     array_distinct_sort( array_agg(CASE WHEN ref_type='n' THEN ref_id ELSE NULL END) ) n_refs,
     array_distinct_sort( array_agg(CASE WHEN ref_type='w' THEN ref_id ELSE NULL END) ) w_refs,
     array_distinct_sort( array_agg(CASE WHEN ref_type='r' THEN ref_id ELSE NULL END) ) r_refs,
     array_distinct_sort( array_agg(CASE WHEN ref_type='Q' THEN ref_id ELSE NULL END) ) wd_ids,
     NULL::bigint[] as member_wd_ids
  FROM (
    SELECT osm_type, osm_id,
           substr(ref,1,1) as ref_type,
           substr(ref,2)::bigint as ref_id
    FROM (
      SELECT substr(osm_type,1,1) as osm_type,
        osm_id::bigint as osm_id,
        regexp_split_to_table("otherIDs", ' ') as ref
      FROM wdosm.li_raw
    ) t2
  ) t
  GROUP BY 1,2
  ORDER BY 1,2
;
CREATE UNIQUE INDEX wdosm_li_index_osmid ON wdosm.li_raw2 (osm_id);
CREATE UNIQUE INDEX wdosm_li_index_osmtyid ON wdosm.li_raw2 (osm_type,osm_id);


---------------
--- LOCAL LIB:

CREATE FUNCTION wdosm.n_wd_ids(  p_ids bigint[] ) RETURNS bigint[] AS $f$
  SELECT array_agg(wd_ids[1])
  FROM   wdosm.li_raw2
  WHERE osm_type='n' AND osm_id IN (select unnest($1))
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION wdosm.w_wd_ids(  p_ids bigint[] , p_type text ) RETURNS bigint[] AS $f$
  SELECT CASE WHEN x='{}'::bigint[] THEN NULL ELSE x END
  FROM (
    SELECT array_agg_mult(wd_ids) as x
    FROM   wdosm.li_raw2
    WHERE osm_type=$2 AND osm_id IN (select unnest($1))
  ) t
$f$ language SQL IMMUTABLE;



---------------
--- ALGORITMO:

-- passo 0 - revove nodes expurios
DELETE FROM wdosm.li_raw2 WHERE osm_type='n' AND array_length(wd_ids,1)=0; -- nenhum

-- passo 1 - transcreve wd_ids dos nodes para as ways onde são membros, e esvazia n_refs
UPDATE wdosm.li_raw2
  SET member_wd_ids = array_distinct_sort( wdosm.n_wd_ids(n_refs) )
  WHERE osm_type IN ('w','r')
;
--UPDATE wdosm.li_raw2 SET n_refs=NULL;

-- passo 2 - transcreve wd_ids das ways para as relations onde são membros, e esvazia w_refs
UPDATE wdosm.li_raw2
  SET member_wd_ids = array_merge_sort( member_wd_ids, wdosm.w_wd_ids(w_refs,'w') )
  -- não estamos pegando member_wd_ids das ways pois seria parentesco de segunda ordem.
  -- no futuro podemos mudar isso e fazer mais um merge.
  WHERE osm_type='r'
;
--UPDATE wdosm.li_raw2 SET w_refs=NULL;

UPDATE wdosm.li_raw2
  SET member_wd_ids = array_merge_sort( member_wd_ids, wdosm.w_wd_ids(r_refs,'r') )
  -- não estamos pegando member_wd_ids das ways pois seria parentesco de segunda ordem.
  -- no futuro podemos mudar isso e fazer mais um merge.
  WHERE osm_type='r'
;
--UPDATE wdosm.li_raw2 SET r_refs=NULL;

DELETE FROM wdosm.li_raw2 WHERE member_wd_ids IS NULL AND wd_ids IS NULL;

-----
-- PRODUTOS!

CREATE VIEW wdosm.li_no_wdid AS
 SELECT osm_type,osm_id,'Q'||array_to_string(member_wd_ids,' Q') as wd_member_ids
 FROM wdosm.li_raw2
 WHERE wd_ids is null
;
CREATE VIEW wdosm.li_final AS
 SELECT osm_type,osm_id,wd_ids,'Q'||array_to_string(member_wd_ids,' Q') as wd_member_ids
 FROM wdosm.li_raw2
 WHERE wd_ids is NOT null
;


COPY (SELECT * FROM wdosm.li_no_wdid) TO '/tmp/LI_noWdId.csv' CSV HEADER;
COPY (SELECT * FROM wdosm.li_final) TO '/tmp/LI_final.csv' CSV HEADER;
