brew install wget osrm-backend
wget https://download.geofabrik.de/europe/italy/centro-latest.osm.pbf --directory-prefix=osm_dumps

osrm-extract -p osrm-backend/profiles/car.lua osm_dumps/centro-latest.osm.pbf
osrm-partition osm_dumps/centro-latest.osrm
osrm-customize osm_dumps/centro-latest.osrm
osrm-contract osm_dumps/centro-latest.osrm 

pip install -r requirements.txt