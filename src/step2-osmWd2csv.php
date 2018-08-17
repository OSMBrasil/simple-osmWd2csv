<?php
/**
 * OSM XML file with Wikidata tags, convert to CSV file after pre-parse filter.
 * The pre-parse pass only node/way/relation with optional wikidata and id-refs as content.
 * @depends osmWd2csv_pre.sh
 */
print "osm_type,osm_id,otherIDs";
define("ND",'n'); // 'node' or 'n'

$r = new XMLReader; // any fast XML-Pull or SAX parser (not DOM!)
if (!$r->open("php://stdin"))  die("\nFailed to open file\n");
$r->read();
if ($r->name!='osm')  die("\n XML is not OSM\n");

for( $lastLine=$tx='',$nm=ND;  $r->read();  )
  if ($r->nodeType == XMLReader::ELEMENT) {
    printLine($lastLine,$tx,$nm);
    $tx = '';
    $nm = substr($r->localName,0,1); // results in n=node, w=way, r=relation
    $lastLine = "$nm,". $r->getAttribute('id') .',';
  } elseif ($r->nodeType == XMLReader::TEXT) {
    $tx = trim( preg_replace('/\s+/s',' ',$r->value) );
    if (strpos($tx,' ')===false && substr($tx,0,1)=='l') $tx=''; // is empty node.
    else $tx = preg_replace_callback(
      '/l\-?(\d+\.\d+)~\-?(\d+\.\d+)/'   // lat~long coordinates
      ,function ($m) { return 'l'.numMix( numPad($m[1]) , numPad($m[2],3) ); }
      ,$tx
    );
  }
printLine($lastLine,$tx,$nm);
$r->close();


// // // LIB

function printLine($line,$tx,$nm) {
  if ($nm!=ND || $tx) // exclude empty nodes
    print "\n$line$tx";
}

function numPad($x,$a_len=2) {
  list($a,$b)=explode('.',$x);
  return str_pad($a,$a_len,'0',STR_PAD_LEFT) . str_pad($b,4,'0');
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
