brew install wget osrm-backend
wget https://osmit-estratti.wmcloud.org/output/pbf/regioni/11_Marche.osm.pbf --directory-prefix=osm_dumps

osrm-extract -p osrm-backend/profiles/foot.lua osm_dumps/centro-latest.osm.pbf
osrm-partition osm_dumps/centro-latest.osrm
osrm-customize osm_dumps/centro-latest.osrm
osrm-contract osm_dumps/centro-latest.osrm
osrm-datastore osm_dumps/centro-latest.osrm 

#docker build -t trova_medico -f ./Dockerfile .


pip install -r requirements.txt