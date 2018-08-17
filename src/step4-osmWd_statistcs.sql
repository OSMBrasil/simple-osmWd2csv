/**
 * Lib and REPORTS.
 * @dependences (SQL) step3
 */

\echo '-- Profile, the totals about direct Wikidata ID (wd_id) use in OSM elements:'
SELECT osm_type
      ,count(*) n_total  -- of osm elements in this analyis
      ,count(*) FILTER(WHERE NOT(wdid_isnull)) n_direct
      ,COALESCE(SUM(count_ref_ids2),0) tot_memb_refs
      ,count(*) FILTER(WHERE wdid_isnull AND has_wdmembs) n_indirect
      ,count(*) FILTER(WHERE wdid_isnull AND has_wdmembs AND num_membs>2) n_indirect3
      ,count(*) FILTER(WHERE num_membs>2) has_wdmembs3
FROM wdosm.tmp_raw_filtered
    ,LATERAL (
      SELECT  wd_id is null OR wd_id=0 wdid_isnull
             ,wd_member_ids is NOT null has_wdmembs
             ,jsonb_int_maxval(wd_member_ids) num_membs
    ) t
GROUP BY 1 order by 1
;

\echo '-- Element type distribution over Wikidata use:'
SELECT element_type, x "Elements with wd_id", y "With distinct wd_id",
      round(100.0*y::float/x::float) as "% distincts"
FROM (
 SELECT osm_type as element_type,
   count(DISTINCT osm_id::text||'.'||wd_id::text) x,
   count(DISTINCT wd_id) y
 FROM wdosm.tmp_raw_filtered group by 1
) t order by 1
;

\echo '-- Report, all profile of Wikidata (wd_id) use:'
SELECT *,   round(100.0*n_direct::float/n_total::float)::text||'%' as "Directs"
  FROM (
  SELECT osm_type, feature_type
    ,count(*) FILTER(where wd_id is not null) as n_direct
    ,count(*) n_total
  FROM wdosm.tmp_raw_filtered
  group by 1,2 order by 1,3 desc,2
) t
;

\echo 'A node with references will be a bug: check no one,'
SELECT osm_id
FROM wdosm.tmp_raw_filtered
WHERE osm_type='n' AND n_ref_ids IS NOT NULL
;
\echo 'Ways need references, counting: must be equal'
SELECT count(*) as n_ways, count(osm_id) n_ways_with_refs
FROM wdosm.tmp_raw_filtered
WHERE osm_type='w' AND w_ref_ids IS NOT NULL
;
