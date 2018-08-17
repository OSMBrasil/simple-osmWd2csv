echo "\n------------------"
echo "Makeing simple-osmWd2csv files and preparing database!"
echo "-----------"

echo "Copying samples to /tmp"
cp samples/LI*.* /tmp
gunzip /tmp/LI_wd.osm.gz

echo "Preparing database 'work':"
psql -U postgres work < src/step0-1-osmWd_libPub.sql
psql -U postgres work < src/step0-2-osmWd_strut.sql
psql -U postgres work < src/step0-3-osmWd_reportLib.sql

psql -U postgres work < src/step3-osmWd_parseRaw.sql
psql -U postgres work < src/step4-osmWd_statistcs.sql
psql -U postgres work < src/step5-osmWd_extraReports.sql
