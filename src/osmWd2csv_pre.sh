
sed -r 's#<tag\s+k="(wikidata|(t)ype)" v="([^"]+)"\s*/?># \2\3 #' \
  | sed -r 's#<nd\s+ref="([0-9]+)".+$# n\1 #' \
  | sed -r 's#<member\s+type="([a-z])[a-z]+"\s+ref="([0-9]+)".+/># \1\2 #' \
  | sed -r 's#<.+/>$##' | grep -v -e '^[[:space:]]*$'  \
  | sed -r 's#(<[a-z]+\s+id="[0-9]+").*>$#\1>#'
