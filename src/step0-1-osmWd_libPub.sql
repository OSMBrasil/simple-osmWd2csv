/**
 * PUBLIC LIB (COMMOM UTILITIES)
 */

CREATE or replace FUNCTION array_fillto(
  -- see https://stackoverflow.com/a/10518236/287948
  anyarray,integer,anyelement DEFAULT NULL
) RETURNS anyarray AS $$
 DECLARE
   i integer;
   len integer;
   ret ALIAS FOR $0;
 BEGIN
   len = array_length($1,1);
   ret = $1;
   IF len<$2 THEN
       FOR i IN 1..($2-len) LOOP
         ret = ret || $3;
       END LOOP;
   END IF;
   RETURN ret;
 END;
$$ LANGUAGE plpgsql IMMUTABLE;

/**
 * Transforms 2 simple non-aligned arrays into a "duo" array of arrays of same size.
 */
CREATE or replace FUNCTION array_fillto_duo(
  anyarray,anyarray,anyelement DEFAULT NULL
) RETURNS table (a anyarray, b anyarray) AS $f$
  SELECT CASE WHEN l1>=l2 THEN $1 ELSE array_fillto($1,l2,$3) END a,
   CASE WHEN l1<=l2 THEN $2 ELSE array_fillto($2,l1,$3) END b
  FROM (SELECT array_length($1,1) l1, array_length($2,1) l2) t
$f$ language SQL IMMUTABLE;


CREATE or replace FUNCTION unnest_2d_1d(
  ANYARRAY, OUT a ANYARRAY
) RETURNS SETOF ANYARRAY AS $func$
 BEGIN
    -- https://stackoverflow.com/a/41405177/287948
    -- IF $1 = '{}'::int[] THEN ERROR END IF;
    FOREACH a SLICE 1 IN ARRAY $1 LOOP
       RETURN NEXT;
    END LOOP;
 END
$func$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE or replace FUNCTION array_sample(
  p_items ANYARRAY,     -- the array to be random-sampled
  p_qt int default NULL -- null is "all" with ramdom order.
) RETURNS ANYARRAY AS $f$
  SELECT array_agg(x)
  FROM (
    SELECT x FROM unnest($1) t2(x)
    ORDER BY random() LIMIT $2
  ) t
$f$ language SQL IMMUTABLE;


CREATE or replace FUNCTION jsonb_rename(
  js JSONB, nmold text, nmnew text
) RETURNS jsonb AS $f$
  SELECT js - nmold || jsonb_build_object(nmnew, js->nmold)
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION array_fastsort (
  -- for future when bigint use CREATE EXTENSION intarray; sort(x)
  ANYARRAY
) RETURNS ANYARRAY AS $f$
  SELECT ARRAY(SELECT unnest($1) ORDER BY 1)
$f$ language SQL strict IMMUTABLE;


CREATE or replace FUNCTION array_is_allsame ( ANYARRAY ) RETURNS boolean AS $f$
  SELECT CASE
           WHEN $1 is NULL OR l=0 THEN NULL
           WHEN l=1 THEN true
           ELSE (
             SELECT bool_and($1[1]=x)
             FROM unnest($1[2:]) t1(x)
           )
           END
  FROM (SELECT array_length($1,1)) t2(l)
$f$ language SQL strict IMMUTABLE;


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

--- JSONb  functions  ---

CREATE or replace FUNCTION jsonb_object_length( jsonb ) RETURNS int AS $f$
  -- Integer because never expect a big JSON, with more tham 10^9 or 2147483647 items
  SELECT count(*)::int FROM jsonb_object_keys($1)  -- faster tham jsonb_each()
$f$ language SQL IMMUTABLE;


---

/**
 * "Merge sum" functions are for JSONb key-intValue objects (ki objects).
 * They are "key counters", so, to merge two keys, the intValues must be added.
 * Change the core of jsonb_merge_sum(jsonb,jsonb) to the correct datatype.
 * The JSON "number" is equivalent to the SQL's ::numeric.
 * Any invalid or empty JSONb object will be represented as SQL NULL.
 * See https://gist.github.com/ppKrauss/679cea825002076c8697e734763076b9
 */

CREATE or replace FUNCTION jsonb_is_summable(jsonb) RETURNS boolean AS $f$
  SELECT not($1 IS NULL OR jsonb_typeof($1)!='object' OR $1='{}'::jsonb)
        AND (SELECT bool_and(jsonb_typeof(value)='number') FROM jsonb_each($1))
        -- for bigint use jsonb_each_text() with regex, value ~ '^\d+$'.
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION jsonb_int_values( jsonb ) RETURNS int[] AS $f$
  SELECT array_agg(value::int) from jsonb_each_text($1)
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION jsonb_int_maxval( jsonb ) RETURNS int AS $f$
  SELECT max(value::int) from jsonb_each_text($1) -- faster tham ::text::int jsonb_each()
$f$ language SQL IMMUTABLE;


CREATE or replace FUNCTION jsonb_merge_sum(  jsonb, jsonb ) RETURNS jsonb AS $f$
  SELECT CASE
    WHEN emp1 AND emp2 THEN NULL
    WHEN emp2 THEN $1
    WHEN emp1 THEN $2
    ELSE $1 || (
      -- CHANGE this core operation to enforce ::number or ::float or ::bigint
      SELECT jsonb_object_agg(  key,  value::int + COALESCE(($1->>key)::int,0)   )
      FROM jsonb_each_text($2)
    ) END
  FROM (
   SELECT $1 IS NULL OR jsonb_typeof($1)!='object' OR $1='{}'::jsonb emp1,
          $2 IS NULL OR jsonb_typeof($2)!='object' OR $2='{}'::jsonb emp2
  ) t
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION jsonb_merge_sum(  jsonb[] ) RETURNS jsonb AS $f$
 DECLARE
  x JSONb;
  j JSONb;
 BEGIN
    IF $1 IS NULL OR array_length($1,1)=0 THEN
      RETURN NULL;
    ELSEIF array_length($1,1)=1 THEN
      RETURN $1[1];
    END IF;
    x := $1[1];
    FOREACH j IN ARRAY $1[2:] LOOP
      x:= jsonb_merge_sum(x,j);
    END LOOP;
    RETURN x;
 END
$f$ LANGUAGE plpgsql IMMUTABLE;

CREATE or replace FUNCTION jsonb_merge_sum(  jsonb[], jsonb[] ) RETURNS jsonb[] AS $f$
 SELECT CASE
   WHEN $2 IS NULL THEN $1
   WHEN $1 IS NULL THEN $2
   ELSE (
     SELECT array_agg( jsonb_merge_sum(j1,j2) )
     FROM (
       SELECT unnest(a) j1, unnest(b) j2
       FROM array_fillto_duo($1,$2) t(a,b)
     ) t
   ) END
$f$ language SQL IMMUTABLE;

DROP AGGREGATE IF EXISTS jsonb_agg_mergesum(jsonb) CASCADE;
CREATE AGGREGATE jsonb_agg_mergesum(jsonb) ( -- important!
  SFUNC=jsonb_merge_sum,
  STYPE=jsonb,
  INITCOND=NULL
);

/* DROP AGGREGATE IF EXISTS jsonb_agg_mergesum(jsonb[]) CASCADE;
CREATE AGGREGATE jsonb_agg_mergesum(jsonb[]) ( -- low use
  SFUNC=jsonb_merge_sum,
  STYPE=jsonb[],
  INITCOND='{}' -- test with null
);
*/

-----------


/*
to use array[array[k,v],...]::bigint[]   instead jsonb  ... no real optimization.

CREATE or replace FUNCTION bigint2d_find( bigint[], bigint ) RETURNS bigint AS $f$
  SELECT x[2] -- value
  FROM unnest_2d_1d($1) t(x)
  WHERE x[1]=$2  -- key
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION bigint2d_merge_sum(  bigint[], bigint[] ) RETURNS bigint[] AS $f$
 SELECT CASE
   WHEN $2 IS NULL THEN $1
   WHEN $1 IS NULL THEN $2
   ELSE (
     SELECT array_agg(array[  x[1],  x[2] + COALESCE(bigint2d_find($1,x[1]),0)  ])
     FROM unnest_2d_1d($2) t(x)
   ) END
$f$ language SQL IMMUTABLE;

*/

-----


CREATE or replace FUNCTION base36_encode(
  -- adapted from https://gist.github.com/btbytes/7159902
  IN digits bigint -- positive
) RETURNS text AS $f$
  DECLARE
			chars char[] := ARRAY['0','1','2','3','4','5','6','7','8','9'
  			,'A','B','C','D','E','F','G','H','I','J','K','L','M'
  			,'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
			ret text := '';
			val bigint;
  BEGIN
  val := digits;
  WHILE val != 0 LOOP
  	ret := chars[(val % 36)+1] || ret;
  	val := val / 36;
  END LOOP;
  RETURN ret;
END;
$f$ LANGUAGE 'plpgsql' IMMUTABLE;
