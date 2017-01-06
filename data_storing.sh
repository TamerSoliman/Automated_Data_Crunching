#!/usr/bin/env bash
sudo service DB_SERVER_NAME start
csvsql --db DB_SERVER_NAME:///DB_NAME\
--no-create --table TABLE_NAME --insert < ./FILENAME.csv
sudo service DB_SERVER_NAME stop