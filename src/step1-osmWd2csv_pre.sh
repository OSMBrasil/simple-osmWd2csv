
sed -r 's#<tag\s+((k="(h)ighway" v="(primary|secondary|tertiary|residential|motorway|trunk|service|track|path)")|(k="(wikidata|(t)ype)" v="([^"]+)"))\s*/?># \3\4\7\8 #' \
  | sed -r 's#<nd\s+ref="([0-9]+)".+$# n\1 #' \
  | sed -r 's#<member\s+type="([a-z])[a-z]+"\s+ref="([0-9]+)".+/># \1\2 #' \
  | sed -r 's#<.+/>$##'  \
  | sed -r 's#(<node\s+id="[0-9]+").*?lat="(-?[0-9]+\.[0-9]{1,4})[0-9]*" lon="(-?[0-9]+\.[0-9]{1,4})[0-9]*".*?>$#\1> l\2~\3 #' \
  | grep -v -e '^[[:space:]]*$' \
  | sed -r 's#(<(way|relation)\s+id="[0-9]+").*>$#\1>#'

## old sed -r 's#<tag\s+k="(wikidata|(t)ype|(h)ighway)" v="([^"]+)"\s*/?># \2\3\4 #' \

# at AR_wd.osm, highway
#  primary            | 7110
#  secondary          | 4156
#  tertiary           | 1878
#  residential        | 4467
#  motorway           | 1999

#| sed -r 's#(<node\s+id="[0-9]+").*?lat="(-?\d+\.\d{1,4})\d*" lon="(-?\d+\.\d{1,4})\d*".*?>$#\1> l\2~\3 #'
