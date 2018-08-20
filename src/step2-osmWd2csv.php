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
    // convert to 64 bits later in the database, and truncate according map_feature type.
    //OLD numMix( numPad() , numPad($r->getAttribute('lon'),3) ).' '): '';
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

/* optional didactic interlace:
function numPad($x,$a_len=2) {
  if (preg_match('/^-?(\d+)(?:\.(\d{1,4})\d*)?$/',$x,$m))
    return str_pad( $m[1], $a_len, '0', STR_PAD_LEFT)
           .str_pad( isset($m[2])?$m[2]:'0' , 4, '0');
  else return '';
}

function numMix($x,$y) {
    $x_len = strlen($x);
    $y_len = strlen($y);
    $x = str_split($x);
    $y = str_split($y);
    for( $i=0, $s='';  $i<$x_len;  $i++ )
      $s.=$x[$i].$y[$i];
    if ($y_len>$x_len) $s.='0'.$y[$y_len-1];
    return $s;
}
*/
