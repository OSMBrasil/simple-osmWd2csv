/**
 * PUBLIC LIB (COMMOM UTILITIES)
 */

CREATE or replace FUNCTION jsonb_merge_sum(  jsonb, jsonb ) RETURNS jsonb AS $f$
 SELECT CASE
   WHEN $2 IS NULL THEN $1
   WHEN $1 IS NULL THEN $2
   ELSE $1 || (
     SELECT jsonb_object_agg(  key,  value::int + COALESCE(($1->>key)::int,0)   )
     FROM jsonb_each_text($2)
   ) END
$f$ language SQL IMMUTABLE;


CREATE or replace FUNCTION array_distinct_sort (
  ANYARRAY,
  p_no_null boolean DEFAULT true
) RETURNS ANYARRAY AS $f$
  SELECT CASE WHEN array_length(x,1) IS NULL THEN NULL ELSE x END -- same as  x='{}'::anyarray
  FROM (
  	SELECT ARRAY(
        SELECT DISTINCT x
        FROM unnest($1) t(x)
        WHERE CASE
          WHEN p_no_null  THEN  x IS NOT NULL
          ELSE  true
          END
        ORDER BY 1
   )
 ) t(x)
$f$ language SQL strict IMMUTABLE;

CREATE or replace FUNCTION array_merge_sort(
  ANYARRAY, ANYARRAY, boolean DEFAULT true
) RETURNS ANYARRAY AS $wrap$
  SELECT array_distinct_sort(array_cat($1,$2),$3)
$wrap$ language SQL IMMUTABLE;

DROP AGGREGATE IF EXISTS array_agg_mult(anyarray);
CREATE AGGREGATE array_agg_mult(anyarray) (
  SFUNC=array_cat,
  STYPE=anyarray,
  INITCOND='{}'
);
