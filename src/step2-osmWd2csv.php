<?php
/**
 * OSM XML file with Wikidata tags, convert to CSV file after pre-parse filter.
 * The pre-parse pass only node/way/relation with optional wikidata and id-refs as content.
 * @depends osmWd2csv_pre.sh
 */
include 'GeoHash.php';
print "osm_type,osm_id,other_ids";
define("ND",'n'); // 'node' or 'n'

$r = new XMLReader; // any fast XML-Pull or SAX parser (not DOM!)
if (!$r->open("php://stdin"))  die("\nFailed to open file\n");
$r->read();
if ($r->name!='osm')  die("\n XML is not OSM\n");

for( $lastLine=$tx=$lastCentroid='',$nm=ND;  $r->read();  )
  if ($r->nodeType == XMLReader::ELEMENT) {
    printLine($lastLine.$lastCentroid, $tx, $nm);
    $tx='';
    $nm = substr($r->localName,0,1); // results in n=node, w=way, r=relation
    $lat = $r->getAttribute('lat');  // on node element, coordinates as centroid
    $lastCentroid = $lat? ('c'.GeoHash::encode($r->getAttribute('lon'),$lat).' '): '';
    $lastLine = "$nm,". $r->getAttribute('id') .',';
  } elseif ($r->nodeType == XMLReader::TEXT) {
    $tx .= trim( preg_replace('/\s+/s',' ',$r->value) );
    if (strpos($tx,' ')===false && substr($tx,0,1)=='l') $tx=''; // is empty node.
  }
printLine($lastLine,$tx,$nm);
$r->close();

// // // LIB

function printLine($line,$tx,$nm) {
  if ($nm!=ND || $tx) // exclude empty nodes
    print "\n".trim("$line$tx");
}
