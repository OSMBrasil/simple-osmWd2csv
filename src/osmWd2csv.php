<?php
/**
 * OSM XML file with Wikidata tags, convert to CSV file.
 */
print "osm_type,osm_id,otherIDs";
$r = new XMLReader; // any fast XML Pull parser (not DOM)
if (!$r->open("php://stdin"))  die("\nFailed to open file\n");
$r->read();
if ($r->name!='osm')  die("\n XML is not OSM\n");
while($r->read())
  if ($r->nodeType == XMLReader::ELEMENT)
    print "\n{$r->name},". $r->getAttribute('id') .',';
  elseif ($r->nodeType == XMLReader::TEXT)
    print trim( preg_replace('/\s+/s',' ',$r->value) );
$r->close();
