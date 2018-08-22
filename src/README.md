Tools and algorithms to parse OSM into Wikidata-OSM simple database.

**XML parser**: converts a big [OSM XML file](https://wiki.openstreetmap.org/wiki/OSM_XML) into a lean tabular format, the intermediary CSV "raw" format. The pipeline of [`step1-osmWd2csv_pre.sh`](src/step1-osmWd2csv_pre.sh) and [`step2-osmWd2csv.php`](src/step2-osmWd2csv.php).

**Final parser and SQL database**. It is not so simple, have  medium-complexity SQL processing. See all `step*.sql` files.
