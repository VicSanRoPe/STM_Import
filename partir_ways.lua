local utils = require("utils")
local readXML, writeXML, printTable, fileExists, trace = table.unpack(utils)


------------------------------ Leer datos ----------------------------------

local ways, nodes = require("ways_cache"), require("nodes_cache")

local ways_a_partir = require("ways_a_partir")
-- ways_a_partir = {[1002] = {103, 104}, [1007] = {107}}
--                    way       node       way     node

local mvd = readXML("MontevideoConParadas.osm")

----------------------------------------------------------------------------


local agregadas = {}
local way_actual_id, ways_nuevas_id = 0, {}



function w_id_member(member)
	local m_id, node_way = nil, nil
	for _, attr in ipairs(member.attr) do
		if attr.name == "ref" then m_id = tonumber(attr.value) end
		if attr.name == "type" then node_way = attr.value end
	end
	if node_way == "way" then return m_id
	else --[[trace("\t\t\t\tIGNORANDO node")]] end
end


function insertar_members(rel, m_i, role, invertir)
	local incremento = 1
	if invertir == true then incremento = 0 end
	local indice = m_i + incremento
	for _, w_nuevo in ipairs(ways_nuevas_id) do
		local member = {type="element", name = "member", kids = {}, attr = {
			{type="attribute", name = "type", value = "way"},
			{type="attribute", name = "ref", value = tostring(w_nuevo)},
			{type="attribute", name = "role", value = role}
		}}
		table.insert(rel.kids, indice, member)
		indice = indice + incremento
	end
end


function intentar_insertar_cosas(rel, m_i, role)
	local arr, indices = {}, {}
	for i, member in ipairs(rel.kids) do
		if member.name == "member" and w_id_member(member) and -- Es un way
				ways[w_id_member(member)] then -- y está descargado
			arr[#arr+1] = member
			indices[m_i] = #arr
		end
	end

	-- Único way, no hay que alinear con ningún otro way, solo insertar
	if #arr == 1 then return false end
	trace("\t\t\t\trelation con "..#arr.." ways y "..#rel.kids.." elementos")

	local m_pre, m_pos = arr[indices[m_i]-1], arr[indices[m_i]+1]

	-- Ajustar los miembros anteriores y siguientes a unos válidos
	-- Si estamos en el primero, el way anterior es el último
	if indices[m_i] == 1 then m_pre = arr[#arr]
	-- Si estamos en el último, el way siguiente es el primero
	elseif indices[m_i] == #arr then m_pos = arr[1] end
	trace("\t\t\t\tm_pre id:"..w_id_member(m_pre),
			"m_pos id:"..w_id_member(m_pos))

	local w_pre, w_pos = ways[w_id_member(m_pre)], ways[w_id_member(m_pos)]
	w_pre = {inicio = w_pre[1], final = w_pre[#w_pre]}
	w_pos = {inicio = w_pos[1], final = w_pos[#w_pos]}

	-- Los ways a coincidir son, el original y el último de los partidos
	trace("\t\t\t\tTrataremos de insertar cosas: " ..
			way_actual_id, ways_nuevas_id[#ways_nuevas_id])
	local w_orig  = ways[way_actual_id]
	local w_nuevo = ways[ways_nuevas_id[#ways_nuevas_id]]

	w_orig = {inicio = w_orig[1], final = w_orig[#w_orig]}
	w_nuevo = {inicio = w_nuevo[1], final = w_nuevo[#w_nuevo]}

	trace("\t\t\t\tInfo: ".." "..w_pre.inicio.." "..w_pre.final.." "..
			w_orig.inicio.." "..w_orig.final.." "..
			w_nuevo.inicio.." "..w_nuevo.final.." "..
			w_pos.inicio.." "..w_pos.final)

	-- El anterior de la relación "coincide" con el original
	--       pre       orig   nuevo      post
	--    I/F----I/F  I----F  I----F  I/F----I/F
	if w_pre.final == w_orig.inicio or w_pre.inicio == w_orig.inicio or
		w_pos.inicio == w_nuevo.final or w_pos.final == w_nuevo.final then
		-- Añadir después
		trace("\t\t\t\tAñadiendo después")
		insertar_members(rel, m_i, role, false)
		return true
	end
	-- El anterior de la relación "coincide" con el nuevo
	--       post      orig   nuevo      pre
	--    I/F----I/F  I----F  I----F  I/F----I/F
	if w_pre.inicio == w_nuevo.final or w_pre.final == w_nuevo.final or
		w_pos.inicio == w_orig.inicio or w_pos.final == w_orig.inicio then
		-- Añadir antes, invertidos
		trace("\t\t\t\tAñadiendo antes, invertidos")
		insertar_members(rel, m_i, role, true)
		return true
	end

	return false
end


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


-- Entrada: la relación, y el índice de elemento (el way miembro encontrado)
-- Agrega a la relación todas los los nuevos ways
function actualizar_agregar(rel, m_i, role)
	local res = intentar_insertar_cosas(rel, m_i, role)

	if res == false then -- Los street no parecen estar ordenados
		trace("\t\t\t\tInsertando simple")
		insertar_members(rel, m_i, role, false)
	end
end


function actualizar_restriction(rel, m_i)
	local info = resumir_relation(rel)
	local id_adecuado = way_actual_id

	local function buscar_inicio_final(via_id)
		local way = ways[way_actual_id] -- Arreglo con nodos en orden
		if way[1] == via_id or way[#way] == via_id then -- Way original
			return
		else -- Hay que buscar en las nuevas ways
			for _, id_nuevo in ipairs(ways_nuevas_id) do
				way = ways[id_nuevo]
				if way[1] == via_id or way[#way] == via_id then
					id_adecuado = id_nuevo -- Este es el way
				end
			end
		end
	end

	-- Es el inicio o final de la relación, pasa por via, sea un way o nodo
	if info.role["from"].id == way_actual_id or
			info.role["to"].id == way_actual_id then
		-- Sencillo, via es un nodo
		if info.role["via"].node == true then
			buscar_inicio_final(info.role["via"].id)
		else -- Es un way
			local via_way = ways[info.role["via"].id]
			buscar_inicio_final(via_way[1])
			buscar_inicio_final(via_way[#via_way])
		end
	end



	for i, d in ipairs(rel.kids[m_i].attr) do if d.name == "ref" then
		rel.kids[m_i].attr[i].value = tostring(id_adecuado)
	end end
end



-- Para optimizar, funciona porque añadimos todos los ways al final,
-- después de manejar todas las relaciones.
local primer_relation = nil
for indice, rel in ipairs(mvd.kids[2].kids) do if rel.name == "relation" then
	primer_relation = indice break
end end


for indice = primer_relation, #mvd.kids[2].kids do
	local rel = mvd.kids[2].kids[indice]
	if rel.name == "relation" then

end end

function actualizar_relaciones()
	--for _, rel in ipairs(mvd.kids[2].kids) do if rel.name == "relation" then
	for indice = primer_relation, #mvd.kids[2].kids do
			local rel = mvd.kids[2].kids[indice]
			if rel.name == "relation" then
		local rel_type = nil
		for _, tag in ipairs(rel.kids) do if tag.name == "tag" then
			local k, v = tag.attr[1].value, tag.attr[2].value
			if k == "type" then rel_type = v end
		end end

		local prev_w_id_member = 0
		for m_i, mem in ipairs(rel.kids) do if mem.name == "member" then
			-- Encontramos el way actual, distinto del anterior
			if w_id_member(mem) == way_actual_id and
					prev_w_id_member ~= w_id_member(mem)then
				prev_w_id_member = w_id_member(mem)
				if rel_type == "street" then
					print("\t\t\tActualizando relación street")
					actualizar_agregar(rel, m_i, "street")
				elseif rel_type == "boundary" then
					print("\t\t\tActualizando relación boundary")
					actualizar_agregar(rel, m_i, "outer")
				elseif rel_type == "multipolygon" then
					-- Barque Batlle, Lezica, Pérez Castellanos, y 6683968
					print("\t\t\tActualizando relación multipolygon")
					actualizar_agregar(rel, m_i, "outer")
				elseif rel_type == "route" then
					print("\t\t\tActualizando relación route")
					actualizar_agregar(rel, m_i, "")
				elseif rel_type == "restriction" then
					print("\t\t\tActualizando relación restriction")
					actualizar_restriction(rel, m_i)
				else
					print("ERROR, relación desconocida: "..
							"type="..rel_type, "id="..way_actual_id)
				end
			end
		end end
	end end
end





function way_con_tags(way, id)
	local copia = {type="element", name = "way", kids = {}, attr = {
		{type="attribute", name = "id",
				value = tostring(-501754 - #agregadas*3)},
		{type="attribute", name = "action", value = "modify"},
		{type="attribute", name = "visible", value = "true"}
	}}

	for _, tag in ipairs(way.kids) do if tag.name == "tag" then
		copia.kids[#copia.kids+1] = tag
	end end

	ways_nuevas_id[#ways_nuevas_id+1] = -501754 - #agregadas*3

	return copia, -501754 - #agregadas*3
end



local primer_way = nil -- Aquí insertaremos todos los ways partidos


for indice, way in ipairs(mvd.kids[2].kids) do if way.name == "way" then
	primer_way = primer_way or indice -- Guardar el primer node

	local id = 0
	for _, attr in ipairs(way.attr) do
		if attr.name == "id" then id = tonumber(attr.value) end
	end
	local arr = ways_a_partir[id]
	trace("Estamos en way id:"..id)
	if arr ~= nil then -- Hay que partir el way
		trace("Hay que partir este way")
		way_actual_id, ways_nuevas_id = id, {}
		local w_nuevo, w_nuevo_id, w_nuevo_i = nil, 0, 0
		local nodos_por_way_original, nodos_por_way_nuevo = {}, {}

		way.attr[#way.attr+1] =
				{type = "attribute", name = "action", value = "modify"}

		local function agregar_node(n_id)
			trace("\t\tAgregando node al nuevo way en "..w_nuevo_i)
			table.insert(w_nuevo.kids, w_nuevo_i, {
				type = "element", name = "nd", kids = {},
				attr = {{type = "attribute",
					name = "ref", value = tostring(n_id)}}})
			table.insert(nodos_por_way_nuevo[w_nuevo_id], n_id)
		end

		local function eliminar_node(nd)
			trace("\t\tEliminando node en viejo way")
			-- Eliminar todo adentro del nd
			nd.type, nd.name, nd.kids, nd.attr[1].name, nd.attr[1].value,
					nd.attr[1], nd.attr, nd =
					nil, nil, nil, nil, nil, nil, nil, nil, nil
		end


		-- Recorremos todos las referencias a nodos (nd)
		for _, nd in ipairs(way.kids) do if nd.name == "nd" then
			local n_id = tonumber(nd.attr[1].value)

			trace("\tEstamos en node id:"..n_id)

			if w_nuevo_i == 0 then
				table.insert(nodos_por_way_original, n_id)
			end

			-- Si el nd actual está en la lista, partir el way aquí
			for _, n_id_tmp in pairs(arr) do if n_id_tmp == n_id then
				trace("\t\tEncontramos el nodo a partir")
				-- Encontramos un segundo nodo a partir
				if w_nuevo then -- Si ya hay un way nuevo
					eliminar_node(nd) -- Eliminar el último nodo anterior
					agregar_node(n_id) -- Agregar un último nodo al nuevo
					agregadas[#agregadas+1] = w_nuevo -- Guardar el way
				end

				w_nuevo, w_nuevo_id = way_con_tags(way, id)
				w_nuevo_i = 1
				nodos_por_way_nuevo[w_nuevo_id] = {}
			end end

			if w_nuevo_i >= 1 then
				agregar_node(n_id)
			end
			if w_nuevo_i > 1 then -- Segundo nd a partir del way partido
				eliminar_node(nd)
			end
			if w_nuevo_i >= 1 then w_nuevo_i = w_nuevo_i + 1 end
		end end
		-- Guardar el último way
		if w_nuevo then
			agregadas[#agregadas+1] = w_nuevo
		end

		-- Agregar el way/nodo a la tabla de ways para las relaciones
		for w_id, arr in pairs(nodos_por_way_nuevo) do ways[w_id] = arr end
		-- Actualizar el way original
		ways[id] = nodos_por_way_original
		actualizar_relaciones()
		trace("Tamaño "..#agregadas)
		ways_a_partir[id] = nil -- Terminamos con este way
	end
end end

for _, w_nuevo in ipairs(agregadas) do
	table.insert(mvd.kids[2].kids, primer_way, w_nuevo)
	primer_way = primer_way + 1
end


---------------------------- Guardar resultado -----------------------------

writeXML(mvd, "MontevideoPartido.osm")

----------------------------------------------------------------------------

