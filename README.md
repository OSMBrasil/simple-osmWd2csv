# simple-osmWd2csv

Simplest and stupid algoritm to convert big big OSM files into **simple CSV file for [Wikidata-tag](https://wiki.openstreetmap.org/wiki/Key:wikidata) analysis**.

This project is suitable for *OSM beginners*, for Unix *agile* pipeline lovers... And for those who do not trust anyone: to *fact checking*.

The target of the "OSM Wikidata-elements CSV file" is to feed PostgreSQL (or SQLite) with complete and reliable data. See eg. [Semantic-bridge OSM-Wikidata](https://github.com/OSMBrasil/semantic-bridge) project.

## Basic results and aims

This project also define two simple data-interchange formats for tests and benchmark of OSM-Wikidata tools.

**`.wdDump.csv` format**: is the best way to dump, **analyse or interchange OSM-Wikidata "bigdata"**. Is a [standard CSV](https://en.wikipedia.org/wiki/Comma-separated_values) file with columns `<osm_type,osm_id,wd_ids,wd_member_ids>`. <br/>The first field, `osm_type`, is the  [OSM element type](https://wiki.openstreetmap.org/wiki/Elements), abbreviated as a letter ("n" for node, "w" for way and "r" for relation); the second its real ID, in the date of the capture; the third its Wikidata ID (a *qid* without the "Q" prefix), sometimes no ID, sometimes more tham one ID; and the fourth, `wd_member_ids`, is a set of space-separed Wikidata IDs of member-elements, that eventually can be assumed as self (parent element). The `.wdDump.csv` is the final format of the parsing process described also in this repo. <br/>Consumes **~0.01% of the XML (`.osm`) format**,  of the wikidata-filtered file, and its zipped file ~0.4% of the  `.osm.pbf` format &mdash; see the [summary of file sizes](example.md).  In CPU time to process or analyse is also a big gain... And for data-analists is a **standard source of the truth** at any SQL tool. Example:

osm_type	|osm_id	|wd_ids|wd_member_ids
----------|-------|------|-----
n	|32011242	|Q49660|
w	|28712148	|Q1792561|
w	|610491098	|Q18482699|Q18482699:2
r	|1988261	|        | Q315548:49
r	|51701	|  Q39	| Q11925:1 Q12746:1
r	|3366718	|  Q386331	| Q386331:15

The same table in SQL can be converted in JSON or JSONb with the following structure:

```sql
TABLE  wdOsm.raw (
   osm_type char NOT NULL, -- reduced to n/w/r
   osm_id bigint NOT NULL,
   wd_ids bigint[],  -- "Q" removed
   member_wd_ids JSONb,  -- e.g. {"315548":49}
  -- option bigint[[key,value]] = array[array[315548,49],array[392600,2]]
  -- and bigint2d_find(a,needle)
   UNIQUE(osm_type,osm_id)
);
```

**`.wdDump.raw.csv` format**: a standard CSV file with columns `<osm_type,osm_id,otherIDs>`.  <br/>Is a intermediary format, with a lot of redundant lines and IDs. Is easy to interchange or feed SQL for final parsing.<br/>The first field, `osm_type`, is the  [OSM element type](https://wiki.openstreetmap.org/wiki/Elements), the second its ID, and `otherIDs` a set of space-separed IDs (node-IDs, way-IDs or Wikidata-IDs).<br/>Consumes ~10% of the XML (`.osm`) format.

So, the following algoritms are also *reference specifications*  of these file formats:

* XML pre-parser, [osmWd2csv_pre.sh](src/osmWd2csv_pre.sh): a simple Unix pipeline where you can easily change or  debug the intermediary XML format.

* XML parser, [osmWd2csv.php](src/osmWd2csv.php): the simplest and stupid algoritm to convert pre-processed OSM into `*_wdDump.raw.csv` format. Good for fact checking (auting process) or statrting point for adaptations.<br/>The ideal algoritm will be C or C++ doing the job of both, pre-parser and parser. Will be easy also to include in the parse the "SQL processing", because it only checks IDs and  refs.

* SQL processing [osmWd_raw-transform.sql](src/osmWd_raw-transform.sql): transforms `*_wdDump.raw.csv` into `*_wdDump.csv`. Is not necessary to be a SQL algoritm, but SQL is the  simplest and most popular standard way to [specify procedures](https://en.wikipedia.org/wiki/Formal_specification) and test.

## Presentation

There are a lot of tools, ranging from the simplest `grep` to counting tags (see also [example](example.md#example-0---grep)), to complicated (but very useful) ones:

* Direct tools:
   * [OPL File Format](https://osmcode.org/opl-file-format) conversors;
   * [Osmconvert](https://wiki.openstreetmap.org/wiki/Osmconvert#Writing_CSV_Files) and its Writing CSV tools.

* Indirect tools:
   * [OSM to GeoJSON](https://github.com/tyrasd/osmtogeojson) complex convertions used by taginfo and others;
   * [`osm2pgsql`](https://wiki.openstreetmap.org/wiki/Osm2pgsql) to feed PostgreSQL;
   * [Osmosis](https://wiki.openstreetmap.org/wiki/Osmosis) also to feed PostgreSQL.

But the problem to be solved here was to track back only one tag (in this case the [`wikidata=*` tag](https://wiki.openstreetmap.org/wiki/Wikidata))...
And by a "dummy user", that never used OPL, Osmconvert, etc. but knows something about XML and CSV formats.
The only external OSM-tool here will be [Osmium](https://osmcode.org/osmium-tool/), to convert [PBF format](https://wiki.openstreetmap.org/wiki/PBF_Format).

The first step in the OSM's Bigdata analysis is to get the file in `.osm` (that is a XML) from "the planet"... For beginners, using Linux:

1. Install. `apt install osmium-tool; osmium --version`, will show "osmium version 1.3.0" for UBUNTU16 and "osmium version 1.7.1 / libosmium version 2.13.1" for UBUNTU18.

2. [Select here the region](http://download.geofabrik.de/), eg. `wget  https://download.geofabrik.de/europe/liechtenstein-latest.osm.pbf`, showing [its with MD5 sum](https://download.geofabrik.de/europe/liechtenstein.html), so compare it with `md5sum  liechtenstein-latest.osm.pbf`.
 <br/>... Or big-data as Europe `wget http://download.geofabrik.de/europe-latest.osm.pbf`

3. See tests and instructions at [Osmium-tool/manual](https://osmcode.org/osmium-tool/manual.html#installation). The main is `osmium fileinfo -e liechtenstein-latest.osm.pbf` to see all details.

## Prepare OSM file

We need a filter (only [elements](https://wiki.openstreetmap.org/wiki/Elements) with Wikidata tag) and a convertion (PBF to OSM).

1. `osmium tags-filter liechtenstein-latest.osm.pbf nwr/wikidata -o wikidata-liechtenstein.osm.pbf`
2. `osmium cat -f osm  wikidata-liechtenstein.osm.pbf -o wikidata-liechtenstein.osm`

So the last output is our XML working-file, in this case `wikidata-liechtenstein.osm`.

## Use

To run samples in your database, the simplest is to `sh src/make.sh`.

There are some examples at [example.md](example.md), starting with the `.osm.pbf` files.

* `cat wikidata-liechtenstein.osm | php src/distincTags.php` is a fact-check for `osmium fileinfo -e`  and to confirm the [DTD](https://en.wikipedia.org/wiki/Document_type_definition) of the OSM file, as well its IDs.

* `sh src/osmWd2csv_pre.sh < wikidata-liechtenstein.osm | more` will show the pre-parsed XML.  

* `sh src/osmWd2csv_pre.sh < wikidata-liechtenstein.osm | php src/osmWd2csv.php > LI_wdDump.csv` the useful thing!

* ... for the complete process, with SQL outputing `LI_wdDump.csv`, see ["example 3 - parsing"](example.md#example-3---parsing).

## License

[&#160; Contents, data and software of this project are dedicated to<br/> ![](assets/CC0-logo-200px.png) ](LICENSE.md)
