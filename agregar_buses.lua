local utils = require("utils")
local readXML, writeXML, printTable, fileExists, trace = table.unpack(utils)


local paradas = readXML("paradas.xml")

local rutas = {}

for _, parada in ipairs(paradas.kids[2].kids) do
	if parada.name == "features" then
		local properties = parada.kids[3].kids
		local ref     = properties[1].kids[1].value
		local varian  = tonumber(properties[3].kids[1].value)
		local ordinal = tonumber(properties[4].kids[1].value)

		rutas[varian] = rutas[varian] or {}
		rutas[varian][ordinal] = ref
	end
end

paradas = nil

local rutas_compactado = {}
-- Hay rutas cuyos ordinales no empiezan en 1
for varian, arr in pairs(rutas) do
	rutas_compactado[varian] = {}

	local size = 0 for _, _ in pairs(arr) do size = size + 1 end

	local arr_i = 1
	for i = 1, size do
		while arr[arr_i] == nil do arr_i = arr_i + 1 end
		rutas_compactado[varian][i] = arr[arr_i]
		arr_i = arr_i + 1
	end
end

rutas = rutas_compactado


printTable(rutas, "rutas_cache.lua")

-----------------------------------------------------------------------------


local nombres = require("nombres") -- [varian] = {numero,origen,destino, por}


-----------------------------------------------------------------------------


local ways_id_por_varian = require("way_ids_por_varian")
-- [varian] = {w_id1, w_id2, ...}


-----------------------------------------------------------------------------

local horarios_datos = require("uptu_pasada_variante")
--var,tipo,frecuencia,ref,ordinal,hora,dia_anterior


local por_var_sal = {}
local horarios = {}

for _, d in pairs(horarios_datos) do
	local var, tipo, salida, ordinal, actual, dia_anterior =
		d[1], d[2], d[3] // 10, d[5], d[6], d[7]
	if dia_anterior == "S" then -- Si es una continuación del día anterior
		actual = actual + 2400 -- Cambiar al formato de más de 24 horas
		if tipo > 1 then tipo = tipo - 1 else tipo = 3 end -- Tipo al anterior
	end

	-- Ignoro si tipo == 0, no se que significa
	if tipo > 0 then -- Guardar todo tiempo por cada salida en una tabla
		por_var_sal[var] = por_var_sal[var] or {}
		por_var_sal[var][tipo] = por_var_sal[var][tipo] or {}
		por_var_sal[var][tipo][salida] = por_var_sal[var][tipo][salida] or {}
		por_var_sal[var][tipo][salida][ordinal] = actual
	end
end

-- Por cada variante, y por cada tipo de día
for var, datos in pairs(por_var_sal) do for tipo, dat in pairs(datos) do
	for salida, arr in pairs(dat) do -- Por cada bus que recorre la línea
		-- Guardar la llegada de cada salida
		por_var_sal[var][tipo][salida] = math.max(table.unpack(arr))
	end
end end



-- por_var_sal = { -- para probar ----------------------------
-- 	[8389] = por_var_sal[8389], -- 183
-- 	[8707] = por_var_sal[8707], -- 174
-- 	[7884] = por_var_sal[7884]  -- 121
-- }



for var, datos in pairs(por_var_sal) do
	trace("Variante: "..var)
	local horas_total = {}
	local freq_total = {}
	local dur_total = {}
	for tipo, dat in pairs(datos) do
		local tipos = {"Mo-Fr", "Sa", "Su"}
		trace("\tTipo de día: "..tipos[tipo])
		local horas = {}

		local arr_salidas = {} -- Para ordenar según salida
		for salida, _ in pairs(dat) do table.insert(arr_salidas, salida) end
		table.sort(arr_salidas)

		function tomin(t) return (t//100)*60+(t%100) end -- Minutos en la hora

		-- Reorganizar (ahora ordenado)
		for _, salida in ipairs(arr_salidas) do
			table.insert(horas, {sal=salida, des=dat[salida]})
			dur_total[#dur_total+1] = tomin(dat[salida]) - tomin(salida)
		end

		trace("\t\tCantidad de idas: "..#horas)

		-- Tiempo final menos tiempo inicial sobre cantidad de tiempos
		local freq = (tomin(horas[#horas].sal)-tomin(horas[1].sal))/(#horas-1)
		if freq == freq then freq_total[#freq_total+1] = freq end
		local maximo, max_i, minimo, min_i = 0, 1, 9999, 1
		for i = 1, #horas - 1 do
			local diff = tomin(horas[i+1].sal) - tomin(horas[i].sal)
			if diff > maximo then maximo = diff max_i = i end
			if diff < minimo then minimo = diff min_i = i end
		end

		trace("\t\tFrecuencia promedio: "..freq)
		trace("\t\tMínimo: "..minimo.." en "..horas[min_i].sal..
				"\tMáxmimo: "..maximo.." en "..horas[max_i].sal)

		local tol = 4 * freq -- 4 (valor arbitrario) por el intervalo promedio

		-- Combinar horass si: Uno sale antes que el anterior llegue
		for i = 2, #horas do if horas[i].sal <= horas[i-1].des or (
				-- De lo contrario: no están demasiado lejos (tol o 1 hora)
				(tomin(horas[i].sal) - tomin(horas[i-1].des)) < tol and
				(tomin(horas[i].sal) - tomin(horas[i-1].des)) < 60) then
			horas[i].sal = horas[i-1].sal -- La salida es el anterior
			horas[i-1] = nil -- Borrar el anterior (la llegada es el actual)
		end end

		horas_total[tipo] = horas
	end



	local texto = "" -- Para formatear los horarios
	local function agregar_horarios(tipo)
		for _, d in pairs(horas_total[tipo]) do
			local str = string.format("%02d:%02d-%02d:%02d",
					d.sal//100, d.sal%100, d.des//100, d.des%100)
			texto = texto .. str .. ","
		end
		texto = texto:sub(1, -2) -- Elmimar coma sobrante
	end
	if horas_total[1] ~= nil then
		texto = texto .. "; Mo-Fr " agregar_horarios(1) end
	if horas_total[2] ~= nil then
		texto = texto .. "; Sa "    agregar_horarios(2) end
	if horas_total[3] ~= nil then
		texto = texto .. "; Su "    agregar_horarios(3) end

	texto = texto:gsub("^; ", "")
	horarios[var] = {horas=texto}

	local function formatear_tiempos(arr)
		local val = 0 -- La frecuencia sería un valor medio
		for _, f in pairs(arr) do val = val + f end
		val = val / #arr

		if val == val and val > 0 then -- ¿esto ya está arreglado?
			val = math.ceil(val)
			return string.format("%02d:%02d", val//60, val%60)
		end
	end

	print(freq_total)
	horarios[var].freq = formatear_tiempos(freq_total)
	print(dur_total)
	horarios[var].dur  = formatear_tiempos(dur_total)
end


local prob_actualizado = {}
for _, d in pairs(horarios_datos) do prob_actualizado[d[1]] = true end


-----------------------------------------------------------------------------


local mvd = readXML("MontevideoPartido.osm")

local idents = {}

for _, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	local id = 0
	for _, attr in ipairs(node.attr) do
		if attr.name == "id" then id = attr.value end
	end

	local cuenta, ref = 0, 0
	for _, tag in ipairs(node.kids) do if tag.name == "tag" then
		local k, v = tag.attr[1].value, tag.attr[2].value
		if  k == "ref" then ref = v end
		if (k == "public_transport" and v == "platform") or
			k == "ref" then cuenta = cuenta + 1 end
		if cuenta == 2 then idents[ref] = id end
	end end

end end




local agregadas = {}
local lineas = {} -- Contiene las variantes por cada número usual de línea
local omitidas = {}

for varian, datos in pairs(rutas) do if nombres[varian] ~= nil then
	local numero = nombres[varian][1]
	if numero ~= "145" and numero ~= "409" then

	local origen, destino = nombres[varian][2], nombres[varian][3]
	local via = nombres[varian][4]
	print("Agregando", varian)
	agregadas[#agregadas+1] = varian


	local mal = false -- Para omitir algunas lineas
	local rel = {type="element", name="relation",
		attr = {
			{type="attribute", name = "id",
					value = tostring(-201754 - #agregadas*3)},
			{type="attribute", name = "action", value = "modify"},
			{type="attribute", name = "visible", value = "true"}
		},
		kids = {
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "type"},
				{type="attribute", name = "v", value = "route"}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "route"},
				{type="attribute", name = "v", value = "bus"}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k",
						value = "public_transport:version"},
				{type="attribute", name = "v", value = "2"}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "network"},
				{type="attribute", name = "v", value = "STM"}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "ref"},
				{type="attribute", name = "v", value = numero}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "mvdgis:variante"},
				{type="attribute", name = "v", value = tostring(varian)}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "from"},
				{type="attribute", name = "v", value = origen}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "to"},
				{type="attribute", name = "v", value = destino}
			}}
		}
	}

	-- Insertar el nombre y via de la ruta, si tiene un destino intermedio
	if via ~= nil then
		table.insert(rel.kids, {type="element", name="tag", attr = {
			{type="attribute", name = "k", value = "via"},
			{type="attribute", name = "v", value = via}
		}})
		table.insert(rel.kids, {type="element", name="tag", attr = {
			{type="attribute", name = "k", value = "name"},
			{type="attribute", name = "v", value = numero .. ": " ..
				origen .. " => " .. via .. " => " .. destino}
		}})
	else -- Y si solo tiene origen y destino
		table.insert(rel.kids, {type="element", name="tag", attr = {
			{type="attribute", name = "k", value = "name"},
			{type="attribute", name = "v", value = numero .. ": " ..
				origen .. " => " .. destino}
		}})
	end
	trace('\tNombre: "'..rel.kids[#rel.kids].attr[2].value..'"')

	-- Insertar los horarios y frecuencias, si están disponibles
	if horarios[varian] ~= nil and horarios[varian].horas ~= nil then
		table.insert(rel.kids, {type="element", name="tag", attr = {
			{type="attribute", name = "k", value = "opening_hours"},
			{type="attribute", name = "v", value = horarios[varian].horas}
		}})
		trace('\tHoras: "'..rel.kids[#rel.kids].attr[2].value..'"')
	else
		print("\tNOTA: Variante "..varian.." sin horarios")
	end
	if horarios[varian] ~= nil and horarios[varian].freq ~= nil then
		table.insert(rel.kids, {type="element", name="tag", attr = {
			{type="attribute", name = "k", value = "interval"},
			{type="attribute", name = "v", value = horarios[varian].freq}
		}})
		trace('\tIntervalo: "'..rel.kids[#rel.kids].attr[2].value..'"')
	else
		print("\tNOTA: Variante "..varian.." sin frecuencia")
	end
	if horarios[varian] ~= nil and horarios[varian].dur ~= nil then
		table.insert(rel.kids, {type="element", name="tag", attr = {
			{type="attribute", name = "k", value = "duration"},
			{type="attribute", name = "v", value = horarios[varian].dur}
		}})
		trace('\tDuración: "'..rel.kids[#rel.kids].attr[2].value..'"')
	else
		print("\tNOTA: Variante "..varian.." sin duración")
	end
	if prob_actualizado[varian] == nil then mal = true end

	-- Insertar todas las paradas por las que pasa el bus
	for _, ref in ipairs(datos) do
		table.insert(rel.kids, {type="element", name="member", attr = {
			{type="attribute", name = "type", value = "node"},
			{type="attribute", name = "role", value = "platform"},
			{type="attribute", name = "ref", value = idents[ref]}
		}})
		trace("\t\tPara por parada ref="..ref..", id:"..idents[ref])
	end

	-- Insertar todos los ways por los que pasa el bus
	local ways_ids = ways_id_por_varian[varian]
	if ways_ids then
		for _, w_id in ipairs(ways_ids) do
			table.insert(rel.kids, {type="element", name="member", attr = {
				{type="attribute", name = "type", value = "way"},
				{type="attribute", name = "role", value = ""},
				{type="attribute", name = "ref", value = tostring(w_id)}
			}})
			trace("\t\tPasa por way id:"..w_id)
		end
	else
		print("ERROR: variante "..varian.." sin linea de ruta") mal = true
	end

	if mal == false then
		table.insert(mvd.kids[2].kids, rel) -- Agregar relación
		lineas[numero] = lineas[numero] or {} -- Guardar según número
		table.insert(lineas[numero],
				{varian=varian, id=-201754 - #agregadas*3})
	else
		print("Omitiendo esta variante... para estar seguros")
		omitidas[#omitidas+1] = varian
	end

	end
end end

local conectadas = {}

for linea, lista in pairs(lineas) do
	conectadas[#conectadas+1] = linea

	local rel = {type="element", name="relation",
		attr = {
			{type="attribute", name = "id",
					value = tostring(-301754 - #conectadas*3)},
			{type="attribute", name = "action", value = "modify"},
			{type="attribute", name = "visible", value = "true"}
		},
		kids = {
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "type"},
				{type="attribute", name = "v", value = "route_master"}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "route_master"},
				{type="attribute", name = "v", value = "bus"}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "network"},
				{type="attribute", name = "v", value = "STM"}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "ref"},
				{type="attribute", name = "v", value = linea}
			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "name"},
				{type="attribute", name = "v", value = "Bus "..linea}
			}}
		}
	}

	trace("\tAgrupando Bus "..linea)
	for _, id in ipairs(lista) do
		rel.kids[#rel.kids+1] = {type="element", name="member", attr = {
			{type="attribute", name = "type", value = "relation"},
			{type="attribute", name = "role", value = ""},
			{type="attribute", name = "ref", value = tostring(id.id)}
		}}

		trace("\t\tVariante "..id.varian.." id:"..id.id)
	end

	table.insert(mvd.kids[2].kids, rel)
end


print("Omitimos " .. #omitidas .. " variantes (sin horas, o sin lineas.xml)")


writeXML(mvd, "MontevideoConBuses.osm")

