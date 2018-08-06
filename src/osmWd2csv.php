<?php
/**
 * OSM XML file with Wikidata tags, convert to CSV file.
 */
print "osm_type,osm_id,otherIDs";
$r = new XMLReader; // any fast XML Pull parser (not DOM)
if (!$r->open("php://stdin"))
  die("\nFailed to open file\n");
$r->read();
if ($r->name!='osm')
  die("\n XML is not OSM\n");
$tg=''; // taginfo
while($r->read()) {
  if ($r->nodeType == XMLReader::ELEMENT) {
    $id = $r->getAttribute('id');
    if ($r->name!='node' || $tg)
      print "\n{$r->name},$id,$tg"; //".($tg? "\"$tg\"": '');
    $tg = '';
  } elseif ($r->nodeType == XMLReader::TEXT) {
    $tg = trim( preg_replace('/\s+/s',' ',$r->value) );
    //$tg = str_replace('"','""',$tg); // escape of CSV
  }
} // while
$r->close();

