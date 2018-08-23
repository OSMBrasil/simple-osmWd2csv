printf "\n------------------"
printf "\n--- Makeing simple-osmWd2csv files and preparing database! ---"
printf "\n------------------\n"
# migrar para makefile. Interartividade conforme https://stackoverflow.com/a/3743821/287948

cp samples/LI*.* /tmp   # only to mount

read -p " Database? (ENTER for 'work') " OSM_DATABASE
if [ "$OSM_DATABASE" = "" ]; then
  OSM_DATABASE="work"
fi

while true; do
    read -p " Restart all at database '$OSM_DATABASE'? (y/n) " yn
    case $yn in
        [Nn]* )
        break;;
        [Yy]* )
        echo "Preparing database '$OSM_DATABASE'..."
        psql -U postgres "$OSM_DATABASE" < src/step0-1-osmWd_libPub.sql
        psql -U postgres "$OSM_DATABASE" < src/step0-2-osmWd_strut.sql
        psql -U postgres "$OSM_DATABASE" < src/step0-3-osmWd_reportLib.sql
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
        read -p "file.osm prefix? " pfx
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
psql -U postgres "$OSM_DATABASE" -c "SELECT wdosm.alter_tmp_raw_csv('TMP')"
echo '-- CSV file, number of rows to be parsed, '
psql -U postgres "$OSM_DATABASE" -c "SELECT COUNT(*) as n_lines FROM wdosm.tmp_raw_csv"

echo '-- INSERTING AND PARSING (..wait..) -- '
psql -U postgres "$OSM_DATABASE" -c "SELECT wdosm.parse_insert( wdosm.get_sid() )"

# not run step3a-osmWd_parseRaw.sql
# empty psql -U postgres work < src/step3b-osmWd_expCsv.sql
psql -U postgres "$OSM_DATABASE" < src/step4-osmWd_statistcs.sql
# later psql -U postgres work < src/step5-osmWd_extraReports.sql

echo ""
echo "done!"
echo "Use psql -U postgres $OSM_DATABASE to check the wdosm SQL schema"
echo ""
# end
