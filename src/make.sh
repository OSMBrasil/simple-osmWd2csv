printf "\n------------------"
printf "\n--- Makeing simple-osmWd2csv files and preparing database! ---"
printf "\n------------------\n"
# migrar para makefile. Interartividade conforme https://stackoverflow.com/a/3743821/287948

cp samples/LI*.* /tmp   # only to mount

WAIT="..wait.." #"..wait.." #please copy/paste and do yourself
OSM_DATABASE2="postgres://postgres:postgres@localhost:5432/work"
OSM_DATABASE=$OSM_DATABASE2

read -p " (ENTER for '$OSM_DATABASE') Database full connection-string? " OSM_DATABASE
if [ "$OSM_DATABASE" = "" ]; then
  OSM_DATABASE=$OSM_DATABASE2
fi

read -p "General name/abbreviation prefix for the new source? (ENTER for no) " PFX_GENERAL
if [ "$PFX_GENERAL" = "" ]; then
  PFX_GENERAL="TMP"
fi

while true; do
    read -p " Restart all at database '$OSM_DATABASE'? (y/n) " yn
    case $yn in
        [Nn]* )
        break;;
        [Yy]* )
        echo "Preparing database '$OSM_DATABASE'..."
        psql "$OSM_DATABASE" < src/step0-1-osmWd_libPub.sql
        psql "$OSM_DATABASE" < src/step0-2-osmWd_strut.sql
        psql "$OSM_DATABASE" < src/step0-3-osmWd_reportLib.sql
        break;;
        * ) echo "Please answer yes or no. ";;
    esac
done

printf "\n (check all fine, no erros above?) \n"
while true; do
    read -p " Do you wish to parse an .osm file? (y/n) " yn
    case $yn in
        [Yy]* )
        echo " Check the file prefixes at /tmp and select one: "
        ls /tmp/*_wd.osm
        read -p "file.osm prefix? (ENTER for '$PFX_GENERAL')" pfx
        if [ "$pfx" = "" ]; then
          pfx=$PFX_GENERAL
        #else PFX_GENERAL=$pfx
        fi
        sh src/step1-osmWd2csv_pre.sh < /tmp/${pfx}_wd.osm | php src/step2-osmWd2csv.php > /tmp/TMP.wdDump.raw.csv
        break;;
        [Nn]* )
        read -p "file to be used as TMP.wdDump.raw.csv? (ENTER to default) " fraw
        if [ "$fraw" != "" ]; then
          cp ${fraw} /tmp/TMP.wdDump.raw.csv
        fi
        break;;
        * ) echo "Please answer yes or no. ";;
    esac
done

echo "Final parsing process at database '$OSM_DATABASE'..."
echo '-- Creating main table from wdDump.raw.csv ... '
psql "$OSM_DATABASE" -c "SELECT wdosm.alter_tmp_raw_csv('TMP')"
echo '-- CSV file, number of rows to be parsed, '
psql "$OSM_DATABASE" -c "SELECT COUNT(*) as n_lines FROM wdosm.tmp_raw_csv"

echo "-- INSERTING AND PARSING ($WAIT) --"
if [ "$WAIT" = "..wait.." ]; then
  psql "$OSM_DATABASE" -c "SELECT wdosm.parse_insert( wdosm.get_sid('$PFX_GENERAL') )"
  psql "$OSM_DATABASE" < src/step4-osmWd_statistcs.sql
else
  echo "psql \"$OSM_DATABASE\" -c \"SELECT wdosm.parse_insert( wdosm.get_sid('$PFX_GENERAL') )\" & "
fi

# not run step3a-osmWd_parseRaw.sql
# empty psql work < src/step3b-osmWd_expCsv.sql
# later psql work < src/step5-osmWd_extraReports.sql

echo ""
echo "done!"
echo "Use psql $OSM_DATABASE to check the wdosm SQL schema"
echo ""
# end
