file 'allCountries.txt'
unique_delimiter "\t"
source_page 'http://download.geonames.org/export/dump/allCountries.zip'
fields  geonameid, name, asciiname, alternatenames, latitude, longitude, \
        feature_class, feature_code, country_code, cc2, admin1_code, \
        admin2_code, admin3_code, admin4_code, population, elevation, \
        gtopo30, timezone, modification_date
indexes name, asciiname
numeric_key geonameid
scheme geoname