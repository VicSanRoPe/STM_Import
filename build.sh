#!/bin/bash

# paradas.xml de
#	https://intgis.montevideo.gub.uy (o directamente https://geoweb.montevideo.gub.uy/geonetwork/srv/spa/catalog.search#/metadata/c6ea0476-9804-424a-9fae-2ac8ce2eee31)
#	De uso libre según resolución 640/10 del Intendente Municipal de Montevideo de fecha 22/02/2010
#		http://www.montevideo.gub.uy/asl/sistemas/Gestar/resoluci.nsf/WEB/Intendente/640-10

# lineas.xml de
#	https://intgis.montevideo.gub.uy (o directamente https://geoweb.montevideo.gub.uy/geonetwork/srv/spa/catalog.search#/metadata/307ffef2-7ba3-4935-815b-caa7057226ce)
#	De uso libre según resolución 640/10 del Intendente Municipal de Montevideo de fecha 22/02/2010
#		http://www.montevideo.gub.uy/asl/sistemas/Gestar/resoluci.nsf/WEB/Intendente/640-10

# uptu_pasada_variante.lua y uptu_pasada_circular.lua de
#	https://catalogodatos.gub.uy/dataset/intendencia-montevideo-horarios-omnibus-urbanos-por-parada-stm
#	Licencia de DAG de Uruguay
#		https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/sites/agencia-gobierno-electronico-sociedad-informacion-conocimiento/files/documentos/publicaciones/licencia_de_datos_abiertos_0.pdf

# Mayoría de nombres_correjidos (en agregar_paradas.lua) de
#	https://github.com/maxm/osmuy/blob/master/osmuy/Main.cs


# Nota: MontevideoParaGPX.osm tiene todos las restricciones de acceso eliminadas con
# ./osmfilter "Montevideo.osm" --drop-author --keep= --keep-relations="restriction" \
#     --keep-ways="highway=" --drop-way-tags="access=" --drop-way-tags="motorcar=" \
#     --drop-way-tags="motorcycle=" --drop-way-tags="vehicle=" \
#     --drop-way-tags="motor_vehicle=" -o="MontevideoParaGPX.osm"
# Las calles interiores de Avenida de las Leyes, vías de servicio cercanas a
# Avenida Wilson Ferreira Aldunate (justo afuera de Montevideo),
# algunas calles privadas en Melilla: también eliminadas.
# No hace falta actualizarlo...




# Descargar el mapa si ya no está
if [ ! -f "Montevideo.osm" ]; then wget -O "Montevideo.osm" \
	"https://overpass-api.de/api/map?bbox=-56.4780,-34.9560,-55.8133,-34.6260"
fi


#-------------------------------- PARADAS --------------------------------#


# Depende de: Montevideo.osm lineas.xml, nombres.lua
# Genera: MontevideoConParadas.osm .gpx
lua agregar_paradas.lua

# Depende de: MontevideoConParadas.osm
# Genera: al parecer, nada notable
lua verificar_paradas.lua


#-------------------------------- RUTAS --------------------------------#


# Depende de: lineas.xml nombres.lua MontevideoParaGPX.osm
# Genera: .gpx .gpx.res.gpx lineas_procesadas.lua
lua extraer_gpx.lua

# Preparar el mapa inicial para usar menos memoria
./osmfilter "MontevideoConParadas.osm" --drop-author --keep= \
	--keep-ways="highway=" -o="MontevideoReducido.osm"

# Depende de: MontevideoReducido.osm (original) lineas_procesadas.lua
# Genera: ways_a_partir.lua
lua recorrer_camino.lua

# Depende de: MontevideoConParadas.osm ways_a_partir.lua
# Genera: MontevideoPartido.osm
lua partir_ways.lua

# Preparar el mapa partido para usar menos memoria
./osmfilter "MontevideoPartido.osm" --drop-author --keep= \
	--keep-ways="highway=" -o="MontevideoReducido.osm"

# Depende de: MontevideoReducido.osm (partido) lineas_procesadas.lua
# Genera: way_ids_por_varian.lua
lua recorrer_camino.lua

# Depende de: paradas.xml nombres.lua uptu_pasada_variante.lua
#             way_ids_por_varian.lua MontevideoPartido.osm
# Genera: MontevideoConBuses.osm
lua agregar_buses.lua





# rm -rf lineasrutas/graph-cache/ lineasrutas/logs/ lineasrutas/*.res.gpx lineas_procesadas.lua MontevideoConBuses.osm MontevideoConParadas.osm MontevideoPartido.osm MontevideoReducido.osm nodes_cache.lua salida1.txt salida3.txt salida4.txt salida5.txt salida6.txt salida7.txt way_ids_por_varian.lua ways_a_partir.lua ways_cache.lua

