#!/usr/bin/env bash
cd /home/USER/DIRECTORY/
./descriptives.R --vanilla --slave
descriptives=$?
./db_storing.sh
storing=$?
./send_email.py $descriptives $storing
#cleaning up by removing csv's & trigger file
if [ $descriptives -eq 0 ] && [ $storing -eq 0 ]
then
files=`ls *.csv`
for file in $files
do
rm $file
done
#delete txt file that triggered current bash script
rm ./success.txt
fi