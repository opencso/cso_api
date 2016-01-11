# cso_api
## get the data into a database
Read all the cso data from the json-stat api and create csv files of the data and
one sql file creating and adding all the data to a postgres database.
I have chosen to use postgres because I'd like to learn how to
set it up on a server.

This is still a work in progress currently the scraper works but needs documentation
The scraper downloads all the files from the cso web api saves them
in /files.

for each of the files create_database.R generats a csv file in /output
and adds create table command to all_sql.sql and also a COPY command.
all_sql.sql can the be run in psql and it will create populated tables
for each data set that has a json-stat file in /files.

creates the sql and file correctly but my R error handling is not so good
if a bad file is found the program crashes
some files just conatain "datasetname not avalible"

## create the api
once all the data is loaded in cleanly I can start working on the
restful api.

David Morrisroe

