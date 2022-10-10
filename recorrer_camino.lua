local utils = require("utils")
local readXML, writeXML, printTable, fileExists, trace = table.unpack(utils)


----------------------------- Extraer ways ---------------------------------

local mvd = readXML("MontevideoReducido.osm")
local ways, nodes, ways_per_node = {}, {}, {}

for _, way in ipairs(mvd.kids[2].kids) do if way.name == "way" then
	local id = 0
	for _, attr in ipairs(way.attr) do if attr.name == "id" then
		id = tonumber(attr.value) end
	end

	ways[id] = {}
	for _, nd in ipairs(way.kids) do if nd.name == "nd" then
		local n_id = tonumber(nd.attr[1].value)
		table.insert(ways[id], n_id)
		ways_per_node[n_id] = ways_per_node[n_id] or {}
		table.insert(ways_per_node[n_id], id)
	end end
end end


for _, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	local id, lat, lon = 0, 0, 0
	for _, attr in ipairs(node.attr) do
		if     attr.name == "id"  then id  = tonumber(attr.value)
		elseif attr.name == "lat" then lat = tonumber(attr.value)
		elseif attr.name == "lon" then lon = tonumber(attr.value) end
	end

	-- Como el mapa está filtrado solo hay nodos de los ways
	nodes[id] = {lat=lat, lon=lon}
end end

mvd = nil

printTable(ways, "ways_cache.lua")
printTable(nodes, "nodes_cache.lua")

----------------------------------------------------------------------------


local lineas_procesadas = require("lineas_procesadas")
-- lineas_procesadas = {
-- 	[2845] = lineas_procesadas[2845],
-- 	[3347] = lineas_procesadas[3347],
-- 	[24] = lineas_procesadas[24],
-- 	[3303] = lineas_procesadas[3303]
-- }


local ways_a_partir = {
	{way=78100568, node=917584793},
	{way=78110825, node=2124226072},
	{way=245918077, node=648246354}}
local way_ids_por_varian = {}


for varian, datos in pairs(lineas_procesadas) do
	print("\nProcesando "..varian)

	-- Lista que contiene los nodos del GPX y su índice
	local nodes_ids, nodes_i = {}, 1

	-- Ángulo entre el nodo destino (el siguiente del GPX) y un origen
	local function angulo(node_id_orig, node_id_dest)
		local ang = math.atan2(
				nodes[node_id_dest].lat - nodes[node_id_orig].lat,
				nodes[node_id_dest].lon - nodes[node_id_orig].lon)
		return ang
	end


	local aprox_orig, aprox_dest = nil, nil

	-- Aquí se hacen coincidir los nodos del GPX con nodos de OSM
	for i, dato in ipairs(datos) do
		local gpx_lat, gpx_lon = dato.lat, dato.lon
		local mejor_opc = {id=nil, dist=999999}
		local segunda_opc = nil

		for node_id, dat in pairs(nodes) do
			local osm_lat, osm_lon = dat.lat, dat.lon
			local dist = (gpx_lat - osm_lat)^2 + (gpx_lon - osm_lon)^2
			if dist < mejor_opc.dist then
				segunda_opc = mejor_opc
				mejor_opc = {id=node_id, dist=dist}
				if dist < 0.00000000000032 then -- 5cm aprox
					trace("Punto seguramente encontrado") break end
			end
		end

		if mejor_opc.dist < 0.000000000018 then -- 43cm aprox
			nodes_ids[#nodes_ids+1] = mejor_opc.id
		else -- No encontramos a que nodo se refiere este punto
			trace("Punto ("..gpx_lat..", "..gpx_lon..
					") no es ningún nodo")
			if i == 1 then
				aprox_orig = {lat=gpx_lat, lon=gpx_lon}
			elseif i == #datos then
				aprox_dest = {lat=gpx_lat, lon=gpx_lon}
			else
				nodes_ids[#nodes_ids+1] = mejor_opc.id
				-- Avisar si la siguiente opción está cerca (doble de dist.)
				if segunda_opc.dist < 2 * mejor_opc.dist then
					print(string.format("ATENCIÓN: Punto intermedio (%f, %f) aproximado a nodo id:%u a %.2f m. Segunda opción id:%u a %.2f m.", gpx_lat, gpx_lon, mejor_opc.id, 100000*math.sqrt(mejor_opc.dist), segunda_opc.id, 100000*math.sqrt(segunda_opc.dist)))
				end
			end
		end
	end


	local function aproximar_extremo(indice, punto_gpx)
		local n_obj = nodes_ids[indice]
		local ang_obj = math.atan2(nodes[n_obj].lat - punto_gpx.lat,
								nodes[n_obj].lon - punto_gpx.lon)
		local dist_obj = math.sqrt((nodes[n_obj].lon - punto_gpx.lon)^2 +
								(nodes[n_obj].lat - punto_gpx.lat)^2)

		if dist_obj < 0.0002 then -- ~10m
			if indice == 1 then trace("Ignorando punto incial")
			else trace("Ignorando punto final") end
		else
			-- Si el último trazo es muy largo, es dificil aproximarlo...
			trace("dist_obj="..dist_obj.." ang_obj="..ang_obj)
			local candidatos = {}
			-- Filtramos todos nodos cercanos y alineados
			for w_id, arr in pairs(ways) do for i, n_id in ipairs(arr) do
				if n_id ~= n_obj then
					local dist = math.sqrt(
							(nodes[n_obj].lon - nodes[n_id].lon)^2 +
							(nodes[n_obj].lat - nodes[n_id].lat)^2)
					if dist <= dist_obj then
						local ang = angulo(n_id, n_obj)
						if math.abs(ang - ang_obj) < math.rad(3) then
							local esta = false
							for _, c in ipairs(candidatos) do
								if c.id == n_id then esta = true break end
							end
							if esta == false then
								candidatos[#candidatos+1] =
									{id=n_id, dist=dist, ang=ang} end
						end
					end
				end
			end end
			if #candidatos == 0 then
				if indice == 1 then trace("Punto inicial irrecuperable")
				else trace("Punto final irrecuperable") end
			else
				-- Ordenar para ver cual es el más lejano
				table.sort(candidatos, function (left, right)
					return left.dist > right.dist
				end)

				-- Si hay varias opciones
				if #candidatos > 1 then
					-- Para filtrar por distancia... preliminar
					local dist_min_obj = candidatos[1].dist / 2

					-- Ordenar por ángulo y que esté a más de la distancia
					table.sort(candidatos, function (left, right)
						return math.abs(left.ang - ang_obj) <
								math.abs(right.ang - ang_obj) and
								left.dist > dist_min_obj
					end)
				end

				trace("Candidatos a extremo")
				for _, d in ipairs(candidatos) do
					trace(d.id, d.dist, d.ang)
				end

				trace("Elejimos node_id="..candidatos[1].id)
				if indice == 1 then
					trace("Punto inicial recuperado")
					table.insert(nodes_ids, 1, candidatos[1].id)
				else
					trace("Punto final recuperado")
					table.insert(nodes_ids, candidatos[1].id)
				end

			end
		end
	end

	trace("Inicio/fin seguros "..nodes_ids[1].."/"..nodes_ids[#nodes_ids])

	if aprox_orig ~= nil then
		aproximar_extremo(1, aprox_orig) end
	if aprox_dest ~= nil then
		aproximar_extremo(#nodes_ids, aprox_dest) end


	trace("Encontrados "..#nodes_ids.." nodos")
	trace("Empezamos en node_id = "..nodes_ids[nodes_i])
	trace("Buscando node_id = "..nodes_ids[nodes_i+1])



	local camino = {}

	local function avanzar_un_nodo(n_orig, n_dest)
		local candidatos = {}
		for _, w_id in pairs(ways_per_node[n_orig]) do -- Ways a buscar
			-- Buscamos el índice del nodo inicial dentro del way actual
			for i, n_id in ipairs(ways[w_id]) do if n_id == n_orig then
				if i < #ways[w_id] then -- Hay espacio hacia "adelante"
					table.insert(candidatos, {id=w_id, i=i, fwd=true,
							ang=angulo(ways[w_id][i], ways[w_id][i+1])})
				end
				if i > 1 then -- Hay espacio hacia "atrás"
					table.insert(candidatos, {id=w_id, i=i, fwd=false,
							ang=angulo(ways[w_id][i], ways[w_id][i-1])})
				end
			end end
		end

		local mejor_opc = {id=nil, i=nil, fwd=nil, ang=9999}
		local ang_obj = angulo(n_orig, n_dest)
		trace("Ángulo objetivo: "..math.deg(ang_obj))

		for _, opc in ipairs(candidatos) do
			trace("\tid="..opc.id.." i="..opc.i..
					" ang="..math.deg(opc.ang))

			local ang_diff = math.abs(opc.ang - ang_obj)
			local mejor_ang_diff = math.abs(mejor_opc.ang - ang_obj)

			trace("\t"..math.deg(ang_diff), math.deg(mejor_ang_diff))

			if math.abs(2*math.pi - ang_diff) < ang_diff then
				ang_diff = math.abs(2*math.pi - ang_diff) end
			if math.abs(2*math.pi - mejor_ang_diff) < mejor_ang_diff then
				mejor_ang_diff = math.abs(2*math.pi - mejor_ang_diff) end

			trace("\t"..math.deg(ang_diff), math.deg(mejor_ang_diff))

			if ang_diff < mejor_ang_diff then mejor_opc = opc end
		end

		-- Si hay un cambio de way
		if #camino >= 1 and camino[#camino].id ~= mejor_opc.id then
			local prev_way = camino[#camino]
			local arr_orig = ways[prev_way.id]
			local arr_dest = ways[mejor_opc.id]
			local n_orig_tmp, n_dest_tmp = nil, nil

			if prev_way.fwd == true then n_orig_tmp = arr_orig[#arr_orig]
			else n_orig_tmp = arr_orig[1] end
			if mejor_opc.fwd == true then n_dest_tmp = arr_dest[1]
			else n_dest_tmp = arr_dest[#arr_dest] end

			if n_orig_tmp == n_dest_tmp then
				mejor_opc.continuacion = true
			else -- Hay que hacer un corte
				-- Si el nodo final del way origen es distinto que el
				-- nodo intersección del recorrido que interessa
				if n_orig_tmp ~= n_orig then
					table.insert(ways_a_partir,
							{way=prev_way.id, node=n_orig})
				end
				-- Si el nodo inicial del way destino es distinto que el
				-- nodo intersección del recorrido que interessa
				if n_dest_tmp ~= n_orig then
					table.insert(ways_a_partir,
							{way=mejor_opc.id, node=n_orig})
				end
			end
		end

		if mejor_opc.fwd == true then mejor_opc.i = mejor_opc.i + 1
		else mejor_opc.i = mejor_opc.i - 1 end

		camino[#camino+1] = mejor_opc

		return mejor_opc
	end

	local node_orig_tmp = nodes_ids[nodes_i]

	while true do
		local res = avanzar_un_nodo(node_orig_tmp, nodes_ids[nodes_i+1])
		-- Si avanzamos hasta el nodo destino
		if ways[res.id][res.i] == nodes_ids[nodes_i+1] then
			print("Nodo encontrado", "id:" .. ways[res.id][res.i])
			nodes_i = nodes_i + 1 -- Avanzar destino
		else
			print("Nodo temporal", "id:" .. ways[res.id][res.i])
		end

		-- Avanzamos el origen el pasito que dio avanzar_un_nodo()
		node_orig_tmp = ways[res.id][res.i]

		if nodes_i == #nodes_ids then break end

		trace("Estamos en way_id = " .. res.id .. ", way_i = " .. res.i)
		trace("Buscando node_id = "..nodes_ids[nodes_i+1].."\n")

	end

	way_ids_por_varian[varian] = camino
end


--------------------- Guardar resultados desduplicados ----------------------


local w_id_varian = {}
for varian, arr in pairs(way_ids_por_varian) do
	w_id_varian[varian] = w_id_varian[varian] or {[1] = arr[1].id}
	local prev_w_id = arr[1].id
	for _, d in ipairs(arr) do
		if d.id ~= prev_w_id then
			prev_w_id = d.id
			table.insert(w_id_varian[varian], d.id)
		end
	end
end

local function arr_tiene_val(arr, valor)
	for _, val in ipairs(arr) do
		if val == valor then return true end end
end

-- Duplicar way entrada al Saint Bois, playa pajas blancas, playa la colorada,
-- calle Camino General Escribano Basilio Muñoz, calle Abrevadero,
-- calle Mártires de la Industria Frigorífica, Camino la Abeja; en rutas necesarias
local ways_duplicables = {
	378358535, 78113193, 78117511, 191450146, 584764538, 78105537, 78110825}
-- Camino Benito Berges (-501988
for varian, arr in pairs(w_id_varian) do
	local insertado = nil
	for i = 2, #arr - 1 do
		local w_id = arr[i]
		if arr_tiene_val(ways_duplicables, w_id) and insertado ~= w_id then
			local node_i, node_f = ways[w_id][1], ways[w_id][#ways[w_id]]
			local arr_prev, arr_next = ways[arr[i-1]], ways[arr[i+1]]
			local n_pi, n_pf = arr_prev[1], arr_prev[#arr_prev]
			local n_ni, n_nf = arr_next[1], arr_next[#arr_next]
			-- Si coincide de alguna manera
			local coincide_i = ((node_i == n_pf and node_i == n_ni) or
								(node_i == n_pi and node_i == n_nf) or
								(node_i == n_pi and node_i == n_ni) or
								(node_i == n_pf and node_i == n_nf))
			local coincide_f = ((node_f == n_pf and node_f == n_ni) or
								(node_f == n_pi and node_f == n_nf) or
								(node_f == n_pi and node_f == n_ni) or
								(node_f == n_pf and node_f == n_nf))
			print("Coincide inicial:", coincide_i,
					"Coincide final:", coincide_f)
			if (coincide_i == true and coincide_f == false) or
				(coincide_f == true and coincide_i == false) then
				-- Duplicar way
				print("Duplicando way "..w_id)
				insertado = w_id
				table.insert(arr, i, w_id)
			end
		end
	end
end


printTable(w_id_varian, "way_ids_por_varian.lua")

printTable(way_ids_por_varian, "way_ids_por_varian_completo.lua")


local w_partir = {}
for _, d in ipairs(ways_a_partir) do
	w_partir[d.way] = w_partir[d.way] or {}
	local visto = false
	for _, n in ipairs(w_partir[d.way]) do
		if d.node == n then visto = true break end
	end
	if visto == false then table.insert(w_partir[d.way], d.node) end
end
printTable(w_partir, "ways_a_partir.lua")

----------------------------------------------------------------------------

