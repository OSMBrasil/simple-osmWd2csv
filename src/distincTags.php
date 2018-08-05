<?php
print "-------------\nCounting elements";

$time0 = microtime(true);
$aux=[];
$r = new XMLReader; // any fast XML Pull parser (not DOM)
if (!$r->open("php://stdin"))
  die("\nFailed to open file\n");
$r->read();
if ($r->name!='osm')
  die("\n\tXML is not OSM\n");
$ids=$refs=0;
$ele = [];
$idMax=0; $idMin=99999999999999;
while($r->read()) if ($r->nodeType == XMLReader::ELEMENT) {
  $nm = $r->localName;
  $id = $r->getAttribute('id');
  $rf = $r->getAttribute('ref');
  if ($id) {$ids++; if ($id>$idMax) $idMax=$id; if ($id<$idMin) $idMin=$id;}
  if ($rf) $refs++;
  $enm = "{$r->depth}:$nm";
  if ( !isset($ele[$enm]) ) $ele[$enm]=1;
  else $ele[$enm]++;
} // while if
$r->close();

$time = microtime(true);
$timediff = round($time - $time0,1);
$showTime = ($timediff>60) ? (round($timediff/60,2)." minutes") : "$timediff seconds";
print " (elapsed time: $showTime)";
foreach ($ele as $tag=>$n)
        print "\n - $tag = $n";
print "\n num. of IDs = $ids (ranging from $idMin to $idMax)\n num. of ID-refs = $refs\n";

