## Examples

Use case and processing exemples of the [project's tools](README.md). For data examples and samble set, see also the [`/data` folder](data).

**Summary of file sizes**

file name | file size | file %s | description
----------|-----------|---------|--------
GE.osm.pbf     | 2.8G      | 100%    |original file, [GE](http://download.geofabrik.de/europe/germany.html), compressed `.osm`
GE.wikidata.osm.pbf | 122M  |100% (4% of original)| extracted by `osmium tags-filter`
GE.wikidata.osm | **1.6G** = 1638M |100% | XML expanded from pbf by osmium
**GE.wdDump.csv**       | **1.5M** | 0,0093% of osm| final format for wikidata tags
GE.wdDump.csv.zip   | 451K = 0.44M |0,4% of osm.pbf, ~30% of csv | csv compressed
LI.osm.pbf     | 2.2M      | 100%    |original file, [LI](http://download.geofabrik.de/europe/liechtenstein.html), compressed `.osm`
LI.wikidata.osm.pbf | 245kb = 0,24M |100% (11% of original)| extracted by `osmium tags-filter`
LI.wikidata.osm     | **3,3M** |100% | XML expanded from pbf by osmium
**LI.wdDump.csv**       | **2K** = 0,002M |  0,8% of osm | final format for wikidata tags

### Example 0 - grep

Looking for an **estimation of the number of Wikidata tags** in a country, by its full OSM file.

1. `wget  https://download.geofabrik.de/europe/germany-latest.osm.pbf`
2. `osmium tags-filter germany-latest.osm.pbf nwr/wikidata -o wikidata-germany-latest.osm`

```sh
grep wikidata wikidata-germany.osm | wc -l # = 76572
  # is the exact number of wikidata tags, but not check repeated
  # and not say the context of member or not-member use,

grep wikidata wikidata-germany.osm | uniq -u | wc -l # = 67934
  # something wrong with "unique lines" but valid as estimation.
```

### Example 1 - info

```sh
ls -lh wikidata-liechtenstein.osm
#-rw-r--r-- 1 user user 3.2M Aug  4 18:18
osmium fileinfo -e wikidata-liechtenstein.osm
```
```
File:
  Name: wikidata-liechtenstein.osm
  Format: XML
  Compression: none
  Size: 3317955
Header:
  Bounding boxes:
    (9.47108,47.0477,9.63622,47.2713)
  With history: no
  Options:
    generator=osmium/1.7.1
    version=0.6
Data:
  Bounding box: (5.04557,43.4945,16.5914,48.4093)
  Timestamps:
    First: 2006-11-21T22:48:53Z
    Last: 2018-08-03T07:07:37Z
  Objects ordered (by type and id): yes
  Multiple versions of same object: no
  CRC32: cb86841f
  Number of changesets: 0
  Number of nodes: 20779
  Number of ways: 696
  Number of relations: 55
  Largest changeset ID: 0
  Largest node ID: 5796405767
  Largest way ID: 611809461
  Largest relation ID: 5418969
```

With a bigger file, as `wikidata-germany.osm` (using in this example a  version with first timestamp 2005-07-05 and last 2018-08-03), the `-e` is time-consuming. To a fast check use default,
```sh
ls -lh wikidata-in-germany.osm
#-rw-r--r-- 1 user user 1.6G Aug  4 18:18

osmium fileinfo wikidata-germany.osm
```
```
File:
  Name: wikidata-germany.osm
  Format: XML
  Compression: none
  Size: 1676191840
Header:
  Bounding boxes:
    (5.86442,47.2654,15.0508,55.1478)
  With history: no
  Options:
    generator=osmium/1.7.1
    version=0.6
```

### Example 2 - pre-parsing

Using [LI](https://download.geofabrik.de/europe/liechtenstein.html) files.

```
cat wikidata-liechtenstein.osm | php  distincTags.php
-------------
Counting elements (elapsed time: 0.1 seconds)
 - 1:bounds = 1
 - 1:node = 20779
 - 2:tag = 6678
 - 1:way = 696
 - 2:nd = 21547
 - 1:relation = 55
 - 2:member = 5151
 num. of IDs = 21530
 num. of ID-refs = 26698

sh preparse.sh < wikidata-liechtenstein.osm | php  distincTags.php
-------------
Counting elements (elapsed time: 0.4 seconds)
 - 1:node = 410
 - 1:way = 696
 - 1:relation = 55
 num. of IDs = 1161
 num. of ID-refs = 0
```

Using [GE](https://download.geofabrik.de/europe/germany.html) files.
```
# file size 1.6G = 1676191840 bytes
cat wikidata-germany.osm  | php distincTags.php
-------------
Counting elements (elapsed time: 58.8 seconds)
 - 1:bounds = 1
 - 1:node = 9483898
 - 2:tag = 6827286
 - 1:way = 750675
 - 2:nd = 10264253
 - 1:relation = 33328
 - 2:member = 1776639
 num. of IDs = 10267901
 num. of ID-refs = 12040892

sh preparse.sh < wikidata-germany.osm | php distincTags.php
-------------
Counting elements (elapsed time: 3,24 minutes)
 - 1:node = 383177
 - 1:way = 750675
 - 1:relation = 33328
 num. of IDs = 1167180
 num. of ID-refs = 0
```
### Example 3 - parsing

```
sh src/osmWd2csv_pre.sh < data/wikidata-liechtenstein.osm \
  | php src/osmWd2csv.php > data/LI_wdDump.raw.csv

cp data/LI_wdDump.raw.csv /tmp

psql -U postgres work < src/osmWd_lib.sql

  CREATE FUNCTION
  CREATE FUNCTION
  CREATE FUNCTION
  DROP AGGREGATE
  CREATE AGGREGATE

psql -U postgres work < src/osmWd_raw-transform.sql
  ...
  DROP SCHEMA
  CREATE SCHEMA
  CREATE FOREIGN TABLE
  SELECT 789
  CREATE INDEX
  CREATE INDEX
  CREATE FUNCTION
  CREATE FUNCTION
  CREATE FUNCTION
  DELETE 0
  UPDATE 751
  UPDATE 55
  UPDATE 55
  UPDATE 789
  DELETE 687
  CREATE VIEW
  COPY 7
  COPY 95

cp /tmp/LI_wdDump.csv  data
cp /tmp/LI_noWdId.csv  data
```

## Example 4 - analysing \_noWdId.csv

After parse GE (as LI in the example 3) we get some suspect cases at  `data/GE_noWdId.csv`... The most commom quality problem is [part/whole references](https://wiki.openstreetmap.org/wiki/Talk:Relations/Relations_are_not_Categories#No_category.2Fobject_ambiguity_when_Wikidata_in_use), where there are a need for enveloping parts into a whole.

Use `grep -v ":1"`  (workaround to filter lines with multiple ids) to check possible cases of "many Wikidata-IDs for same OSM feature".

```
grep -v ":1" data/GE_noWdId.csv

r,27662,Q661002:2
...
r,74824,Q1327299:4
r,118059,Q1327299:6 Q1674275:2
r,122633,Q1327299:5 Q1674275:2
r,122634,Q1327299:5 Q1674275:2
r,139020,Q315548:33
r,139021,Q315548:37
r,165847,Q1674275:2
r,190230,Q802272:46
...
r,365393,Q878631:22
...
r,1061707,Q3239584:9
...
r,1717086,Q896564:21
r,1717088,Q896564:56
...
```

## Example 4 - analysing by SQL

GE case of repeatead wd_ids in many elements.

```sql
SELECT wd_ids[1] as wd_id, osm_type,
       count(*) n, max(osm_id) as osm_id_sample
FROM wdosm.li_raw2
GROUP BY 1,2 HAVING count(*)>10
ORDER BY 3 desc
```

wd_id   | osm_type |  n  | osm_id_sample
--------|----------|-----|---------------
 319837 | w        | 197 |     539934418
 315548 | w        | 162 |     418178590
  41150 | r        | 157 |       8448513
1699351 | w        | 125 |     481282152
 314003 | n        | 125 |    4735136612
1642426 | w        | 112 |     506257563
 572498 | w        | 112 |     376709253
1796040 | n        | 104 |    5760272821
 896564 | w        |  95 |     518074303
1562222 | w        |  73 |     415878211
 450204 | w        |  72 |     442768996
 884374 | w        |  59 |     603119891
1302868 | w        |  58 |     536625582
43988627 | w        |  54 |     384662114
 564867 | w        |  53 |     585245679
 870831 | n        |  51 |    3656900028
1786999 | w        |  51 |     355489818
...|...|...|...

Completing the analisis comparing with `GE_noWdId.csv` or its  query. Examples:

`grep Q319837 data/GE_noWdId.csv` shows that there are no envelope candidate.

`grep Q315548` shows that there are some partial enveloping,

```csv
r,139020,Q315548:33
r,139021,Q315548:37
r,1988255,Q315548:86
r,1988258,Q315548:84
r,1988261,Q315548:49
r,1988263,Q315548:50
```
