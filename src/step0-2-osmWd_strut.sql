/**
 * Structure of mais dataets and functions.
 * @dependences (file system) cp data/LI_wdDump.raw.csv /tmp
 */

CREATE EXTENSION file_fdw;
CREATE SERVER files FOREIGN DATA WRAPPER file_fdw;

DROP SCHEMA IF EXISTS wdosm CASCADE;
CREATE SCHEMA wdosm;

-- only for data-transfer:
CREATE FOREIGN TABLE wdosm.tmp_raw_csv (
   osm_type text,
   osm_id bigint,
   other_ids text
) SERVER files OPTIONS (
   filename '/tmp/TMP.wdDump.raw.csv',
   format 'csv',
   header 'true'
);

CREATE TABLE wdosm.tmp_raw_dist_ids (
  osm_id bigint NOT NULL PRIMARY KEY -- will create UNIQUE INDEX
);

CREATE or replace FUNCTION wdosm.alter_tmp_raw_csv (
  p_name text DEFAULT 'TMP', -- eg. 'LI', the ISO-two-letter code Liechtenstein
  p_run_insert boolean DEFAULT true,
  p_path text DEFAULT '/tmp'
) RETURNS text AS $f$
DECLARE
  fname text := '%s/%s.wdDump.raw.csv';
  sql text := $$
     ALTER FOREIGN TABLE wdosm.tmp_raw_csv OPTIONS (
       SET filename %L
     );
  $$;
BEGIN
  p_name = upper(trim(p_name));
  fname := format(fname,p_path,p_name);
  sql := format(sql,fname);
  IF p_run_insert THEN
    sql:=sql || $$
    DELETE FROM wdosm.tmp_raw_dist_ids;
    -- Heuristic to avoid a lot of non-existent IDs (file OSM was filtered)
    INSERT INTO  wdosm.tmp_raw_dist_ids
      SELECT DISTINCT osm_id FROM wdosm.tmp_raw_csv
    ;
    $$;
  END IF;
  EXECUTE sql;
  RETURN format('-- table wdosm.tmp_raw_csv using %L',fname);
END
$f$ LANGUAGE plpgsql;


CREATE VIEW wdosm.vw_tmp_raw_filtered AS
  SELECT osm_type, osm_id
    ,array_to_string(array_agg(other) FILTER(WHERE ref_type='t' OR ref_type='h'),'-') feature_type
    ,MAX(wd_id) wd_id  -- ? need FILTER(WHERE ref_type='Q')
    ,MAX(centroid) centroid  -- ? need FILTER(WHERE ref_type='l')
    ,SUM(count_ref_ids) count_ref_ids -- original from file.OSM or pre-parser
    ,SUM(array_length(ref_ids,1)) count_ref_ids2 -- as useful ref_ids
    ,MAX(ref_ids) FILTER (WHERE ref_ids is NOT NULL AND ref_type='n') n_ref_ids
    ,MAX(ref_ids) FILTER (WHERE ref_ids is NOT NULL AND ref_type='w') w_ref_ids
    ,MAX(ref_ids) FILTER (WHERE ref_ids is NOT NULL AND ref_type='r') r_ref_ids
    ,NULL::jsonb wd_member_ids -- for a second-step processing from ref_ids
    ,NULL::bigint[] used_ref_ids
  FROM (
    /*  typical distribution of the query (before sommarize ref_type)
    ref_type | count | ref_ids
    r        |    67 |     861
    w        |  3390 |  109577
    n        | 59145 | 1834782
    h        | 27328 |
    Q        | 10416 |
    l        |  6363 |
    t        |  3404 |
    */
    SELECT osm_type, osm_id, ref_type
      ,SUM(CASE WHEN is_ref THEN 1::int ELSE 0::int END)  count_ref_ids -- see also n
      ,array_distinct_sort( array_agg(ref2) FILTER (
        WHERE is_ref AND (SELECT true FROM wdosm.tmp_raw_dist_ids WHERE t1.ref2=osm_id)
      )) ref_ids -- array_length(ref_ids,1) =< count_ref_ids
      ,MAX(ref)  FILTER( WHERE not(is_ref) AND ref_type NOT IN ('Q','l') ) other
      ,MAX(ref2) FILTER( WHERE ref_type='l' AND is_int ) centroid
      ,MAX(ref2) FILTER( WHERE ref_type='Q' AND is_int ) wd_id
      ,COUNT(*)::int as n -- for quality-control only; n=count_ref_ids always excet nodes (count_ref_ids=0 and n=1)
    FROM (
      SELECT *, is_int AND ref_type NOT IN ('Q','l') is_ref
             ,ref::bigint ref2
      FROM (
        SELECT *, (sref ~ '^[a-zA-Z][0-9]+$') as is_int
               ,substr(sref,1,1) as ref_type
               ,substr(sref,2) as ref
        FROM (
          SELECT substr(osm_type,1,1)::char osm_type
            ,osm_id::bigint as osm_id
            ,regexp_split_to_table(other_ids, '[\s,;:\-]+') as sref
          FROM wdosm.tmp_raw_csv
        ) t3
      ) t2
    ) t1
    GROUP BY 1,2,3
    ORDER BY 1,2,3
  ) t0
  GROUP BY 1,2
  ORDER BY 1,2
;


---- --- ---

SELECT wdosm.alter_tmp_raw_csv('LI',false); -- LI is a sample, replace by yours!

CREATE table wdosm.tmp_raw_filtered AS
  SELECT * FROM wdosm.vw_tmp_raw_filtered
  LIMIT 0;  -- is only to mount a structure.
;
CREATE UNIQUE INDEX wdosm_exp1_index ON wdosm.tmp_raw_filtered (osm_type,osm_id);
-- now any other can run by DELETE / INSERT instead TO CREATE.
-- so , run wdosm.alter_tmp_raw_csv('YOURS',true)

---- --- ---

CREATE or replace FUNCTION wdosm.get_member_wds(
  p_reftype char, p_refids bigint[]
) RETURNS  TABLE (wd_ids jsonb, osm_ids bigint[], osm_type char) AS $f$
  SELECT jsonb_agg_mergesum(j_wdid), array_agg(osm_id), p_reftype
  FROM (
    SELECT  osm_id, jsonb_build_object(osm_type ||':Q'|| wd_id::text, 1)  j_wdid
    FROM wdosm.tmp_raw_filtered
    WHERE wd_id IS NOT NULL AND osm_type = p_reftype AND osm_id = ANY(p_refids)
  ) t
$f$ language SQL IMMUTABLE;

-----
-- Other VIEWS (function dependents)

CREATE VIEW wdosm.li_output AS
  SELECT osm_type, osm_id
         ,'Q'||wd_id AS wd_id
         ,base36_encode(centroid) refcenter
         ,jsonb_int_maxval(wd_member_ids) wd_memb_max
         ,wd_member_ids
  FROM wdosm.tmp_raw_filtered
  WHERE wd_id is NOT null
  ORDER BY 1,2
;
