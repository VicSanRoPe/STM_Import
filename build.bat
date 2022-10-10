ECHO "Asegurese que el archivo Montevideo.osm existe. Descomprima el incluido."
ECHO "O puede descargar uno actualizado en:"
ECHO "https://overpass-api.de/api/map?bbox=-56.4780,-34.9560,-55.8133,-34.6260"


lua54.exe agregar_paradas.lua | tee salida1.txt
rem lua54.exe verificar_paradas.lua | tee salida2.txt




lua54.exe extraer_gpx.lua | tee salida3.txt


osmfilter "MontevideoConParadas.osm" --drop-author --keep= --keep-ways="highway=" -o="MontevideoReducido.osm"


lua54.exe recorrer_camino.lua | tee salida4.txt


lua54.exe partir_ways.lua | tee salida5.txt


osmfilter "MontevideoPartido.osm" --drop-author --keep= --keep-ways="highway=" -o="MontevideoReducido.osm"


lua54.exe recorrer_camino.lua | tee salida6.txt

lua54.exe agregar_buses.lua | tee salida7.txt

osmfilter "MontevideoConBuses.osm" --drop-author --keep= --keep-ways="highway=" --keep-nodes="public_transport=platform" --keep-relations="route=bus" --keep-relations="restriction=" -o="MontevideoConBusesReducido.osm"
