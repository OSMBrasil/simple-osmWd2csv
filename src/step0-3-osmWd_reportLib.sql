/**
 * Lib for REPORTS.
 * @dependences (SQL) step3
 */

CREATE FUNCTION wdosm.check_same_wdid_refcenter(
  p_sid int DEFAULT 0,
  p_cut integer DEFAULT 5,
  p_type char DEFAULT 'n'
) RETURNS TABLE (commom_wd_id bigint, refcenter text, osm_ids bigint[]) AS $f$
  SELECT wds[1] commom_wd_id, refcenter, osm_ids
  FROM (
   SELECT array_agg(osm_id) osm_ids,
    array_agg(wd_id) wds,
    substr(centroid,1,p_cut) refcenter, -- old base36_encode(centroid) .. will base32
    count(*) n
   FROM wdosm.main
   WHERE centroid is not null AND osm_type=p_type
         AND CASE p_sid=0 THEN true ELSE p_sid=sid END
   GROUP BY 3
   HAVING count(*)>1
  ) t
  WHERE array_is_allsame(wds)
  ORDER BY 1
$f$ language SQL IMMUTABLE;


-- XHTML formaters:

CREATE or replace FUNCTION xhtml_ahref(p_a text, p_url text) RETURNS xml AS $f$
  SELECT xmlelement(
          name a,
          xmlattributes(p_url||p_a as href, '_black' as target),
          p_a
        )
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION wdosm.xhtml_wd_ahref(p_a text) RETURNS xml AS $f$
    SELECT xhtml_ahref($1, 'http://wikidata.org/entity/')
$f$ language SQL IMMUTABLE;
CREATE or replace FUNCTION wdosm.xhtml_wd_ahref(p_a bigint) RETURNS xml AS $wrap$
    SELECT wdosm.xhtml_wd_ahref('Q'||p_a::text)
$wrap$ language SQL IMMUTABLE;

CREATE or replace FUNCTION wdosm.xhtml_osm_ahref(p_a text, p_osm_type char) RETURNS xml AS $f$
    SELECT xhtml_ahref($1, concat('https://www.openstreetmap.org/',j->>$2,'/'))
    FROM (SELECT '{"n":"node","w":"way","r":"relation"}'::jsonb) t(j)
$f$ language SQL IMMUTABLE;
CREATE or replace FUNCTION wdosm.xhtml_osm_ahref(bigint,char) RETURNS xml AS $wrap$
    SELECT wdosm.xhtml_osm_ahref($1::text,$2)
$wrap$ language SQL IMMUTABLE;

CREATE or replace FUNCTION wdosm.xhtml_osm_ahref(
  bigint[], p_osm_type char, p_sep text DEFAULT ', '
) RETURNS xml AS $f$
    SELECT array_to_string( array_agg(wdosm.xhtml_osm_ahref(x::text,$2)),  p_sep )::xml
    FROM unnest($1) t(x)
$f$ language SQL IMMUTABLE;

-- -- --




CREATE or replace FUNCTION wdosm.check_same_wdid_refcenter_xml(
  p_cut integer DEFAULT 6,
  p_type char DEFAULT 'n'
) RETURNS xml AS $f$
  SELECT xmlelement(
    name table, xmlattributes(1 as border),
    xmlelement(
      name tr,
      xmlconcat(
        xmlelement( name th, 'commom_wd_id'),
        xmlelement( name th, 'osm_ids')
      ) -- concat()
    ), -- tr header
    xmlagg(
      xmlelement(
        name tr,
        xmlconcat(
          xmlelement(name td, wdosm.xhtml_wd_ahref(commom_wd_id) ), -- td
          xmlelement(name td, wdosm.xhtml_osm_ahref(osm_ids,p_type) ) -- td
        ) -- concat()
      ) -- tr
    ) -- agg(tr)
  ) --  table
  FROM wdosm.check_same_wdid_refcenter($1,$2)
$f$ language SQL IMMUTABLE;

-- --



---------------
--- OTHER LOCAL FORMAT LIB:


CREATE FUNCTION wdosm.wd_id_format(  p_ids bigint[] ) RETURNS text AS $f$
  SELECT 'Q'||array_to_string($1,' Q')
$f$ language SQL IMMUTABLE;

CREATE FUNCTION wdosm.wd_id_format(  p_ids JSONb ) RETURNS text AS $f$
  SELECT jsonb_summable_output(p_ids,' ', 'Q')
$f$ language SQL IMMUTABLE;

CREATE FUNCTION wdosm.wd_id_unformat( p_list text ) RETURNS JSONb AS $f$
  -- reverts wdosm.wd_id_format()
  SELECT jsonb_object_agg(substr(x[1],2), x[2]::int)
  FROM (
    SELECT regexp_split_to_array(item, ':')	as x
    FROM regexp_split_to_table($1, '[\s,;\|]+') t2(item)
  ) t
$f$ language SQL IMMUTABLE;

CREATE FUNCTION wdosm.wd_id_sparql(  bigint[] ) RETURNS text AS $f$
  SELECT 'wd:Q'||array_to_string(  array_agg(x) ,  ', wd:Q'  )
  FROM unnest($1) t(x)
$f$ language SQL IMMUTABLE;
