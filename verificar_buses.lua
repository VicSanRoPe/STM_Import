local utils = require("utils")
local readXML, writeXML, printTable, fileExists, trace = table.unpack(utils)





if false then
	local a_actualizar = {}
	local por_mapa  = require("paradas_mal_mapa")
	local por_datos = require("paradas_mal_datos")

	for _, p_ref in ipairs(por_mapa) do -- Por cada mala en el mapa
		local esta = false
		for _, p_ref_dat in ipairs(por_datos) do -- Por cada mala en los datos
			if p_ref == p_ref_dat then esta = true break end -- Mal en datos
		end
		if esta == false then -- Mal en el mapa pero no en los datos
			table.insert(a_actualizar, p_ref)
		end
	end

	printTable(a_actualizar, "paradas_a_actualizar.lua")

	os.exit()
end





local rutas_completas = require("way_ids_por_varian_completo")
-- [varian] = {[1] = {id=way_id, fwd=booleano, ang=radianes}}
local ways, nodes = require("ways_cache"), require("nodes_cache")
-- [w_id] = {n_id, n_id, ...}         [n_id] = {lat=..., lon=...}
local paradas, coords = require("rutas_cache"), require("coords_cache")
-- [varian] = {[1] = ref, ...}        [ref] = {lat=..., lon=..., name=...}
local mvd = readXML("MontevideoConBusesReducido.osm")


local ajustar_coords = {}
for var, d in pairs(coords) do
	ajustar_coords[var] = {lat=tonumber(d.lat), lon=tonumber(d.lon)}
end
coords = ajustar_coords


function resumir_relation(rel)
	local info = {tags = {}, role = {}}
	for _, tag in ipairs(rel.kids) do if tag.name == "tag" then
		info.tags[tag.attr[1].value] = tag.attr[2].value
	end end

	for m_i, member in ipairs(rel.kids) do if member.name == "member" then
		local attrs = {} -- Atributos como tabla, solo para leer
		for _, attr in ipairs(member.attr) do
			attrs[attr.name] = attr.value
		end
		info.role[attrs["role"]] = {id=tonumber(attrs["ref"])}
		if attrs["type"] == "node" then info.role[attrs["role"]].node = true
		else info.role[attrs["role"]].way = true end
	end end
	return info
end


-- Recolectar todas las restricciones, y lineas que llegaron al mapa
local restricciones, rutas = {}, {}
for _, rel in ipairs(mvd.kids[2].kids) do if rel.name == "relation" then
	local info = resumir_relation(rel)
	if info.tags["type"] == "restriction" then
		table.insert(restricciones, info)
	elseif info.tags["type"] == "route" and
			info.tags["route"] == "bus" and
			info.tags["mvdgis:variante"] ~= nil then
		local v = tonumber(info.tags["mvdgis:variante"])
		rutas[v] = rutas_completas[v]
	end
end end


local function buscar_con_tags(node, idtag, ...)
	local cuenta, id = 0, nil
	for _, tag in pairs(node.kids) do if tag.name == "tag" then
		local k, v = tag.attr[1].value, tag.attr[2].value
		if k == idtag then id = v end
		for _, val in ipairs(arg) do
			if type(val) == "string" then
				if k == val then cuenta = cuenta + 1 end
			else -- Es un arreglo con k y v
				if k == val[1] and v == val[2] then cuenta = cuenta + 1 end
			end
		end
	end end

	if cuenta == #arg then return id end
end


-- Recolectar todas las paradas en el mapa
local coords_mapa = {}
for _, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	local ref = buscar_con_tags(node, "ref",
		"ref", {"public_transport", "platform"})
	if ref ~= nil then
		local lat, lon = nil, nil
		for _, attr in ipairs(node.attr) do
			if attr.name == "lat" then lat = tonumber(attr.value)
			elseif attr.name == "lon" then lon = tonumber(attr.value) end
		end
		coords_mapa[ref] = {lat=lat, lon=lon}
	end
end end


-- Verificar restricciones de giro
for varian, arr in pairs(rutas) do for i = 1, #arr-1 do
	local way_curr_id, way_next_id = arr[i].id, arr[i+1].id
	if way_curr_id ~= way_next_id then for _, info in ipairs(restricciones) do
		if info.role["from"].id == way_curr_id then
			if (info.tags["restriction"] == "no_straight_on" or
					info.tags["restriction"] == "no_left_turn" or
					info.tags["restriction"] == "no_right_turn" or
					info.tags["restriction"] == "no_u_turn") and
					info.role["to"] and info.role["to"].id == way_next_id then
				print("Variante "..varian.." Giro incorrecto de id:"
						..way_curr_id.." a id:"..way_next_id)
				break
			end
		end
	end end
end end

function to_obj(nodo)
	if type(nodo) == "number" then return nodes[nodo]
	else return nodo end
end
function angulo(origen, destino) -- Radianes
	local orig, dest = to_obj(origen), to_obj(destino)
	return math.atan2(dest.lat - orig.lat, dest.lon - orig.lon)
end
function distancia(origen, destino) -- Metros
	local orig, dest = to_obj(origen), to_obj(destino)
	return --[[100000 *]] math.sqrt(
			(dest.lat - orig.lat)^2 + (dest.lon - orig.lon)^2)
end


-- Ejecutar una vez con true otra vez con false
local usar_datos_del_mapa = true


function angulo_p(orig, parada_ref) -- Radianes
	if usar_datos_del_mapa then
		return angulo(to_obj(orig), coords_mapa[parada_ref])
	else
		return angulo(to_obj(orig), coords[parada_ref])
	end
end
function distancia_p(orig, parada_ref) -- Metros
	if usar_datos_del_mapa then
		return distancia(to_obj(orig), coords_mapa[parada_ref])
	else
		return distancia(to_obj(orig), coords[parada_ref])
	end
end






function w_arr_to_n_arr(w_arr)
	local n_id_arr = {} -- Para reunir todos los nodos reales
	for _, obj in ipairs(w_arr) do
		table.insert(n_id_arr, ways[obj.id][obj.i])
	end

	local n_arr = {} --Hacer subdivisiones de 10 cm
	for i = 1, #n_id_arr-1 do
		local n_id_curr, n_id_next = n_id_arr[i], n_id_arr[i+1]
		local ang = angulo(n_id_curr, n_id_next)
		local dist = distancia(n_id_curr, n_id_next)

		local paso, divs = dist, 1
		while paso > 0.000001 do -- Dividir cada ~10cm
			divs = divs + 1
			paso = dist / divs
		end

		local node = nodes[n_id_curr]
		table.insert(n_arr, {lat=node.lat, lon=node.lon, id=n_id_curr})

		for n = 1, divs do
			local lat = node.lat + n * paso * math.sin(ang)
			local lon = node.lon + n * paso * math.cos(ang)
			table.insert(n_arr, {lat=lat, lon=lon})
		end
	end

	local node = nodes[n_id_arr[#n_id_arr]] -- Insertar último nodo
	table.insert(n_arr, {lat=node.lat, lon=node.lon, id=n_id_arr[#n_id_arr]})

	local arr = {n_arr[1]} -- Para desduplicar puntos
	for _, d in ipairs(n_arr) do
		if d.lat ~= arr[#arr].lat and d.lon ~= arr[#arr].lon then
			table.insert(arr, d)
		end
	end

	return arr
end

local paradas_mal, paradas_bien = {}, {}

-- Convertir a arreglo de nodos falsos y reales
for var, w_arr in pairs(rutas) do
	local n_arr = w_arr_to_n_arr(w_arr)
	for _, p_ref in ipairs(paradas[var]) do if paradas_bien[p_ref] == nil then

		local ang_diff = 0
		local min_dist, min_dist_i = 999999, 1

		local function encontrar_angulo()
			min_dist_i = 1
			for i = 1, #n_arr-1 do -- Buscar el nodo (real o no) más cercano
				local dist = distancia_p(n_arr[i], p_ref)
				if dist < min_dist then min_dist = dist min_dist_i = i end
			end

-- 			print(#n_arr, min_dist_i)

			local n_curr, n_next = n_arr[min_dist_i], n_arr[min_dist_i+1]

-- 			printTable(n_curr) print()
-- 			printTable(n_next) print()

			local ang_siguiente = angulo(n_curr, n_next)
			local ang_a_parada = angulo_p(n_curr, p_ref)

			ang_diff = ang_a_parada - ang_siguiente -- Diferencia
			-- Ajustar ángulo
			if ang_diff > math.pi then ang_diff = ang_diff - 2 * math.pi
			elseif ang_diff < -math.pi then ang_diff = ang_diff+2*math.pi end
		end

		local mal = 0
		for intentos = 1, 4 do
			encontrar_angulo()
			if ang_diff > 0 then -- Está a la izquierda
				print("Variante "..var.." Parada "..p_ref.." mal")
				table.remove(n_arr, min_dist_i)
				mal = mal + 1
			else
				print("Variante "..var.." Parada "..p_ref.. " bien")
				paradas_bien[p_ref] = true
				break;
			end
		end
		if mal == 4 then table.insert(paradas_mal, p_ref) end
	end end
end






if usar_datos_del_mapa then
	printTable(paradas_mal, "paradas_mal_mapa.lua")
else
	printTable(paradas_mal, "paradas_mal_datos.lua")
end







