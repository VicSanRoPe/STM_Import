local utils = require("utils")
local readXML, writeXML, printTable, fileExists, trace = table.unpack(utils)

local mvd = readXML("MontevideoConBuses.osm")


local nombres = require("nombres")
local horarios = require("horarios_nuevos")


function datos_a_variante(ref, from, to, duration) --, interval)
	-- Filtrar según nombres.lua
	local variante = nil
	for var, d in pairs(nombres) do
		if d[1] == ref and d[2] == from and d[3] == to then
			-- Filtrar por la duración y el intervalo
			print("Variante posible "..var)
			if horarios[var] and horarios[var].dur == duration then -- and
--					horarios[var].freq == interval then
				if variante == nil then variante = var
				else print("ERROR: Variante duplicada") end
			else print("ERROR: Variante sin horario") end
		end
	end
	return variante
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


local buscadas, cambiado = 0, 0

for _, rel in ipairs(mvd.kids[2].kids) do if rel.name == "relation" then
	local info = resumir_relation(rel)
	if info.tags["type"] == "route" and info.tags["route"] == "bus" and
			info.tags["from"] and info.tags["to"] and
			info.tags["ref"]  and info.tags["duration"] and
			info.tags["opening_hours"] then
		buscadas = buscadas + 1
		print("Buscando", info.tags["ref"],info.tags["from"], info.tags["to"])
		local var = datos_a_variante(info.tags["ref"], info.tags["from"],
				info.tags["to"], info.tags["duration"])
		for _, tag in ipairs(rel.kids) do
			if tag.name == "tag" and tag.attr[1].value == "opening_hours" then
				tag.attr[2].value = horarios[var].horas
				cambiado = cambiado + 1
			end
		end
	end
end end

print("Buscadas "..buscadas.." variantes")
print("Cambiadas "..cambiado.." variantes")


writeXML(mvd, "MontevideoConBusesNuevo.osm")


















































































os.exit()


local coords = require("coords_cache")



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


local function eliminar_tag(tag)
	-- Eliminar todo adentro del tag
	tag.type, tag.name, tag.kids, tag.attr[1].name, tag.attr[1].value,
			tag.attr[1], tag.attr[2].name, tag.attr[2].value,
			tag.attr[2], tag.attr, tag =
			nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
end


local function terminar_eliminacion(node)
	local valid_kids = {}
	for i, tag in pairs(node.kids) do
		if tag and tag.type then
			valid_kids[#valid_kids+1] = tag
		end
	end
	node.kids = valid_kids
end



for indice, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	local id = buscar_con_tags(node, "ref",
		"ref", {"public_transport", "platform"})

	-- Encontramos la parada y esta en la lista
	if id ~= nil and coords[id] ~= nil then
		print("Quitando ref=", id)
		for i, tag in pairs(node.kids) do if tag.name == "tag" then
			local k, v = tag.attr[1].value, tag.attr[2].value
			if  k == "ref" then eliminar_tag(tag) end
		end end

		terminar_eliminacion(node)
	end
end end



writeXML(mvd, "MontevideoConBusesNuevo.osm")



