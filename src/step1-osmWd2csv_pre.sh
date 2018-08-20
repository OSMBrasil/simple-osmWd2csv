
sed -r 's#<tag\s+((k="(h)ighway" v="(primary|secondary|tertiary|residential|motorway|trunk|service|track|path)")|(k="(wikidata|(t)ype)" v="([^"]+)"))\s*/?># \3\4\7\8 #' \
  | sed -r 's#<nd\s+ref="([0-9]+)".+$# n\1 #' \
  | sed -r 's#<member\s+type="([a-z])[a-z]+"\s+ref="([0-9]+)".+/># \1\2 #' \
  | sed -r 's#<.+/>$##'  \
  | grep -v -e '^[[:space:]]*$' \
  | sed -r 's#(<(way|relation)\s+id="[0-9]+").*>$#\1>#'
