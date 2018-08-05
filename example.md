# xmlBig-tools

## distincTags.php
For simple "detect elements" and basic count.

Example1: 
```
# file size 3.2M = 3317955
cat wikidata-in-liechtenstein.osm | php  distincTags.php 
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

sh preparse.sh < wikidata-in-liechtenstein.osm | php  distincTags.php 
-------------
Counting elements (elapsed time: 0.4 seconds)
 - 1:node = 410
 - 1:way = 696
 - 1:relation = 55
 num. of IDs = 1161
 num. of ID-refs = 0
```

Example2:
```
# file size 1.6G = 1676191840
cat wikidata-in-germany.osm  | php distincTags.php
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

sh preparse.sh < wikidata-in-germany.osm | php distincTags.php
-------------
Counting elements (elapsed time: 3,24 minutes)
 - 1:node = 383177
 - 1:way = 750675
 - 1:relation = 33328
 num. of IDs = 1167180
 num. of ID-refs = 0
```
