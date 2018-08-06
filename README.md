# simple-osmWd2csv

Simplest and stupid algoritm to convert big big OSM files into **simple CSV file for [Wikidata-tag](https://wiki.openstreetmap.org/wiki/Key:wikidata) analysis**.

This project is suitable for *OSM beginners*, for Unix *agile* pipeline lovers... And for those who do not trust anyone: to *fact checking*.

The target of the "OSM Wikidata-elements CSV file" is to feed PostgreSQL (or SQLite) with complete and reliable data. See eg. [Semantic-bridge OSM-Wikidata](https://github.com/OSMBrasil/semantic-bridge) project.

## Basic results and aims

This project also define two simple data-interchange formats for tests and benchmark of OSM-Wikidata tools.

**`.wdDump.csv` format**: is the best way to dump, **analyse or interchange OSM-Wikidata "bigdata"**. Is a [standard CSV](https://en.wikipedia.org/wiki/Comma-separated_values) file with columns `<osm_type,osm_id,wd_ids,wd_member_ids>`. <br/>The first field, `osm_type`, is the  [OSM element type](https://wiki.openstreetmap.org/wiki/Elements), abbreviated as a letter ("n" for node, "w" for way and "r" for relation); the second its real ID, in the date of the capture; the third its Wikidata ID (a *qid* without the "Q" prefix), sometimes no ID, sometimes more tham one ID; and the fourth, `wd_member_ids`, is a set of space-separed Wikidata IDs of member-elements, that eventually can be assumed as self (parent element). The `.wdDump.csv` is the final format of the parsing process described also in this repo. <br/>Consumes **~0.01% of the XML (`.osm`) format**,  of the wikidata-filtered file, and its zipped file ~0.4% of the  `.osm.pbf` format.  In CPU time to process or analyse is also a big gain... And for data-analists is a **standard source of the truth** at any SQL tool. Examples:

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

There are some examples at [example.md](example.md).

* `cat wikidata-liechtenstein.osm | php src/distincTags.php` is a fact-check for `osmium fileinfo -e`  and to confirm the [DTD](https://en.wikipedia.org/wiki/Document_type_definition) of the OSM file, as well its IDs.

* `sh src/osmWd2csv_pre.sh < wikidata-liechtenstein.osm | more` will show the pre-parsed XML.  

* `sh src/osmWd2csv_pre.sh < wikidata-liechtenstein.osm | php src/osmWd2csv.php > LI_wdDump.csv` the useful thing!

* ... for the complete process, with SQL outputing `LI_wdDump.csv`, see ["example 3 - parsing"](example.md#example-3---parsing).

## License

[&#160; Contents, data and software of this project are dedicated to<br/> ![](assets/CC0-logo-200px.png) ](LICENSE.md)
