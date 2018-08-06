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
     NULL::JSONb as member_wd_ids
  FROM (
    SELECT osm_type, osm_id,
           substr(ref,1,1) as ref_type,
           CASE WHEN not(ref ~ '^[a-zA-Z][0-9]+$') THEN NULL::bigint ELSE substr(ref,2)::bigint END as ref_id
    FROM (
      SELECT substr(osm_type,1,1)::char as osm_type,
        osm_id::bigint as osm_id,
        regexp_split_to_table("otherIDs", '[\s,;:\-]+') as ref
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


CREATE FUNCTION wdosm.refs2wdids(  p_ids bigint[] , p_type char ) RETURNS JSONb AS $f$
  SELECT CASE WHEN j='{}'::JSONb THEN NULL ELSE j END
  FROM (
    SELECT jsonb_object_agg(xwd_id,n) as j
    FROM (
      SELECT unnest(wd_ids) as xwd_id, count(*) as n
      FROM   wdosm.li_raw2
      WHERE osm_type=$2 AND osm_id IN (select unnest($1))
      GROUP BY 1
    ) t2
  ) t
$f$ language SQL IMMUTABLE;

CREATE FUNCTION wdosm.wd_id_format(  p_ids bigint[] ) RETURNS text AS $f$
  SELECT 'Q'||array_to_string($1,' Q')
$f$ language SQL IMMUTABLE;

CREATE FUNCTION wdosm.wd_id_format(  p_ids JSONb ) RETURNS text AS $f$
  SELECT array_to_string(  array_agg('Q'|| key ||':'|| value) ,  ' '  )
  FROM jsonb_each_text($1)
$f$ language SQL IMMUTABLE;

CREATE FUNCTION wdosm.wd_id_unformat( p_list text ) RETURNS JSONb AS $f$
  -- reverts wdosm.wd_id_format()
  SELECT jsonb_object_agg(substr(x[1],2), x[2]::int)
  FROM (
    SELECT regexp_split_to_array(item, ':')	as x
    FROM regexp_split_to_table($1, '[\s,;\|]+') t2(item)
  ) t
$f$ language SQL IMMUTABLE;

---------------
--- ALGORITMO:

-- passo 0 - revove nodes expurios
DELETE FROM wdosm.li_raw2 WHERE osm_type='n' AND array_length(wd_ids,1)=0; -- nenhum

-- passo 1 - transcreve wd_ids dos nodes para as ways onde são membros
UPDATE wdosm.li_raw2
  SET member_wd_ids = wdosm.refs2wdids(n_refs,'n')
  WHERE osm_type IN ('w','r')
;
-- passo 2 - transcreve wd_ids das ways para as relations onde são membros
UPDATE wdosm.li_raw2
  SET member_wd_ids = jsonb_merge_sum( member_wd_ids, wdosm.refs2wdids(w_refs,'w') )
  -- não estamos pegando member_wd_ids das ways pois seria parentesco de segunda ordem.
  -- no futuro podemos mudar isso e fazer mais um merge.
  WHERE osm_type='r'
;
-- passo 3 - transcreve wd_ids das relations-filhas para as relations onde são membros
UPDATE wdosm.li_raw2
  SET member_wd_ids = jsonb_merge_sum( member_wd_ids, wdosm.refs2wdids(r_refs,'r') )
  WHERE osm_type='r'
;

-- passo4 - (opcional) sumir com dados redundantes para não poluir.
UPDATE wdosm.li_raw2 SET n_refs=NULL,w_refs=NULL,r_refs=NULL;
DELETE FROM wdosm.li_raw2 WHERE member_wd_ids IS NULL AND wd_ids IS NULL;

-----
-- PRODUTOS!

CREATE VIEW wdosm.li_output AS
 SELECT osm_type, osm_id,
   wdosm.wd_id_format(wd_ids) as wd_ids,
   wdosm.wd_id_format(member_wd_ids) as wd_member_ids
 FROM wdosm.li_raw2
 ORDER BY 1,2
;

COPY (
  SELECT osm_type, osm_id, wd_member_ids
  FROM wdosm.li_output WHERE wd_ids is null
) TO '/tmp/LI_noWdId.csv' CSV HEADER;

COPY (
  SELECT * FROM wdosm.li_output WHERE wd_ids is NOT null
) TO '/tmp/LI_wdDump.csv' CSV HEADER;
