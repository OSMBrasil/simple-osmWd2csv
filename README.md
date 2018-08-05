# simple-osmWd2csv

Simplest and stupid algoritm to convert big big OSM files into **simple CSV file for [Wikidata-tag](https://wiki.openstreetmap.org/wiki/Key:wikidata) analysis**.

This project is for suitable for *OSM beginners*, for Unix *agile* pipeline lovers... And for those who do not trust anyone, to *fact checking*.

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

The first step in the OSM's Bigdata analysis is to get the file in `.osm` (that is a XML) from "the planet"... For beginers, using Linux:

1. Install. `apt install osmium-tool; osmium --version`, will show "osmium version 1.3.0" for UBUNTU16 and "osmium version 1.7.1 / libosmium version 2.13.1" for UBUNTU18.

2. [Select here the region](http://download.geofabrik.de/), eg. `wget  https://download.geofabrik.de/europe/liechtenstein-latest.osm.pbf`, showing [its with MD5 sum](https://download.geofabrik.de/europe/liechtenstein.html): e3519f27fa36c78c1f36e63ac3142e00, so compare it with `md5sum  liechtenstein-latest.osm.pbf`.
 <br/>... Or big-data as Europe `wget http://download.geofabrik.de/europe-latest.osm.pbf   &`

3. See all tests and instructions at [Osmium-tool/manual](https://osmcode.org/osmium-tool/manual.html#installation)

  3.1. `osmium fileinfo -e liechtenstein-latest.osm.pbf` to see all details.
  3.2.  .... https://wiki.openstreetmap.org/wiki/Osm2pgsql  mas talvez https://wiki.openstreetmap.org/wiki/Osmosis  faça isso mais diretamente.


4. Lets start to work really. The `liechtenstein-latest.osm` is the complete XML file.

## Other not-used tools 
* https://wiki.openstreetmap.org/wiki/Osm2pgsql
* https://wiki.openstreetmap.org/wiki/Osmosis 


## Use


## License

[&#160; Contents, data and software of this project are dedicated to<br/> ![](assets/CC0-logo-200px.png) ](LICENSE.md)

