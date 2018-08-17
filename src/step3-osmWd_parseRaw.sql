/**
 * Parser.
 * Transfer from CSV and transform OSM-Wikidata Bigdata.
 * @dependences (SQL) step0-*.sql
 * @dependences (file system) cp data/LI_wdDump.raw.csv /tmp
 */

\echo '-- Creating main table from wdDump.raw.csv ... '

SELECT wdosm.alter_tmp_raw_csv('LI'); -- LI is a sample, replace by yours!

\echo '-- INSERTING AND PARSING (..wait..) -- '
DELETE FROM wdosm.tmp_raw_filtered;  -- must be explicit to avooid confusion...
INSERT INTO  wdosm.tmp_raw_filtered  -- must be explicit
  SELECT * FROM wdosm.vw_tmp_raw_filtered
;

\echo '-- CSV file, number of rows to be parsed, '
SELECT COUNT(*) as n_lines FROM wdosm.tmp_raw_csv;

---------------
--- FINAL PARSE ALGORITHM:

\echo '-- Incluing wd_member_ids as first-order references:'

UPDATE wdosm.tmp_raw_filtered -- ref nodes
SET (wd_member_ids, used_ref_ids) = (
   SELECT t.wd_ids, t.osm_ids
   FROM wdosm.get_member_wds('n',n_ref_ids) t
) WHERE count_ref_ids2>0
;
UPDATE wdosm.tmp_raw_filtered -- ref ways
SET (wd_member_ids, used_ref_ids) = (
   SELECT jsonb_merge_sum(wd_member_ids, t.wd_ids)
          ,used_ref_ids || t.osm_ids
   FROM wdosm.get_member_wds('w',w_ref_ids) t
) WHERE count_ref_ids2>0
;
UPDATE wdosm.tmp_raw_filtered -- ref relations
SET (wd_member_ids, used_ref_ids) = (
   SELECT jsonb_merge_sum(wd_member_ids, t.wd_ids)
          ,used_ref_ids || t.osm_ids
   FROM wdosm.get_member_wds('r',r_ref_ids) t
) WHERE count_ref_ids2>0
;

\echo '-- END (no recurence or second-order references) --'

-- for higher-order references the function must be recursive, calling a second used the jsonb recursive stack

-----
-- Exporting as datasets and reports

\echo '-- EXPORTING final results to /tmp:'

COPY ( -- main dump!
  SELECT osm_type, osm_id, wd_id, refcenter
  FROM wdosm.li_output
) TO '/tmp/TMP.wdDump.csv'
  CSV HEADER
;

COPY ( -- list suspects
  SELECT osm_type, osm_id, wd_member_ids
  FROM wdosm.li_output
  WHERE wd_id is null AND wd_memb_max>1
) TO '/tmp/TMP.noWdId.csv' CSV HEADER;
