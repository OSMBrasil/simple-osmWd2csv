/**
 * Parser. Run only when no alternative.
 * Transfer from CSV and transform OSM-Wikidata Bigdata.
 * @dependences (SQL) step0-*.sql
 * @dependences (file system) cp data/LI_wdDump.raw.csv /tmp
 */

\echo '-- Creating main table from wdDump.raw.csv ... '
SELECT wdosm.alter_tmp_raw_csv('TMP');

\echo '-- CSV file, number of rows to be parsed, '
SELECT COUNT(*) as n_lines FROM wdosm.tmp_raw_csv;

\echo '-- INSERTING AND PARSING (..wait..) -- '
SELECT wdosm.parse_insert( wdosm.get_sid() );


/*
OLD TRASH...

DROP TABLE IF EXISTS tmp_expanded CASCADE;
CREATE TEMPORARY TABLE tmp_expanded AS
  SELECT  DISTINCT *, 0 nivel, 0::bigint wdid2  -- unnecessary distinct
  FROM (
    SELECT osm_id, wd_id, NULL::bigint as ref_id FROM wdosm.tmp_raw_filtered
    WHERE n_ref_ids IS NULL
    UNION
    SELECT osm_id, wd_id, unnest(n_ref_ids) as ref_id FROM wdosm.tmp_raw_filtered
    UNION
    SELECT osm_id, wd_id, unnest(w_ref_ids) as ref_id FROM wdosm.tmp_raw_filtered
    UNION
    SELECT osm_id, wd_id, unnest(r_ref_ids) as ref_id FROM wdosm.tmp_raw_filtered
  ) t
;
CREATE UNIQUE INDEX wdosm_test1_index ON tmp_expanded (osm_id,ref_id);
*/


--select osm_id, wd_id_group(refs) from wdosm.tmp_raw_members;

-- relation/298285 | Q454586 Q7420462 Q9685950 Q174 Q10366796 Q18479100 Q10304645 Q10262437 Q18697265



-- for higher-order references the function must be recursive, calling a second used the jsonb recursive stack
