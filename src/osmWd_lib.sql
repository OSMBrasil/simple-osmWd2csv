/**
 * PUBLIC LIB (COMMOM UTILITIES)
 */

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
