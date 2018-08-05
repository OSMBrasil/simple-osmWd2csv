# simple-osmWd2csv

Simplest and stupid algoritm to convert big big OSM files into **simple CSV file for [Wikidata-tag](https://wiki.openstreetmap.org/wiki/Key:wikidata) analysis**.

This project is suitable for *OSM beginners*, for Unix *agile* pipeline lovers... And for those who do not trust anyone: to *fact checking*.

The target of the "OSM Wikidata-elements CSV file" is to feed PostgreSQL (or SQLite) with complete and reliable data. See eg. [semantic-bridge](https://github.com/OSMBrasil/semantic-bridge).

## Presentation 

There are a lot of tools, ranging from the simplest `grep` to counting tags, to complicated (but very useful) ones:

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

## License

[&#160; Contents, data and software of this project are dedicated to<br/> ![](assets/CC0-logo-200px.png) ](LICENSE.md)

