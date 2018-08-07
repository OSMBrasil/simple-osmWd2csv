<?php
/**
 * OSM XML file with Wikidata tags, convert to CSV file after pre-parse filter.
 * The pre-parse pass only node/way/relation with optional wikidata and id-refs as content.
 * @depends osmWd2csv_pre.sh
 */
print "osm_type,osm_id,otherIDs";
define("ND",'node'); // 'node' or 'n'

$r = new XMLReader; // any fast XML-Pull or SAX parser (not DOM!)
if (!$r->open("php://stdin"))  die("\nFailed to open file\n");
$r->read();
if ($r->name!='osm')  die("\n XML is not OSM\n");

for( $lastLine=$tx='',$nm=ND;  $r->read();  )
  if ($r->nodeType == XMLReader::ELEMENT) {
    printLine($lastLine,$tx,$nm);
    $tx = '';
    $nm = $r->localName; //substr($r->localName,1); // results in n=node, w=way, r=relation
    $lastLine = "$nm,". $r->getAttribute('id') .',';
  } elseif ($r->nodeType == XMLReader::TEXT)
    $tx = trim( preg_replace('/\s+/s',' ',$r->value) );

printLine($lastLine,$tx,$nm);
$r->close();

function printLine($line,$tx,$nm) {
  if ($nm!=ND || $tx) // exclude empty nodes
    print "\n$line$tx";
}
