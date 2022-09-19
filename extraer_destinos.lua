local SLAXML = require("slaxdom")






local paradas_file = io.open("paradas.xml", "r")
local paradas_xml = paradas_file:read("*all")
paradas_file:close()
local paradas = SLAXML:dom(paradas_xml, {stripWhitespace=true, simple=true})
paradas_file, paradas_xml = nil, nil

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


local rutas_compactado = {}

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

paradas = nil

local destinos = {}

for variante, datos in pairs(rutas) do
	destinos[variante] =
			{inicio = tonumber(datos[1]), final = tonumber(datos[#datos])}
end

rutas = nil













--[[ Para generar los comandos de nominatim


local mvd_file = io.open("MontevideoModificado.osm", "r")
local mvd_xml = mvd_file:read("*all")
mvd_file:close()
local mvd = SLAXML:dom(mvd_xml, {stripWhitespace=true, simple=true})
mvd_file, mvd_xml = nil, nil

local idents = {}

for _, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	local id, lat, lon = 0, 0, 0
	for _, attr in ipairs(node.attr) do
		if     attr.name == "id"  then id  = attr.value
		elseif attr.name == "lat" then lat = tonumber(attr.value)
		elseif attr.name == "lon" then lon = tonumber(attr.value) end
	end

	local cuenta, ref = 0, 0
	for _, tag in ipairs(node.kids) do if tag.name == "tag" then
		local k, v = tag.attr[1].value, tag.attr[2].value
		if  k == "ref" then ref = v end
		if (k == "public_transport" and v == "platform") or
			k == "ref" then cuenta = cuenta + 1 end
		if cuenta == 2 then idents[ref] = {id=id, lat=lat, lon=lon} end
	end end

end end



local nombres = require("nombres") -- [varian] = {numero,origen,destino, por}

for varian, datos in pairs(destinos) do if nombres[varian] ~= nil and
        nombres[varian][1] ~= "145" and nombres[varian][1] ~= "409" then
	
	local function viewbox(dato)
		return "&viewbox=" .. dato.lon-0.0069 .. "," .. dato.lat-0.011 .. "," .. dato.lon+0.0069 .. "," .. dato.lat+0.011
	end
	-- https://tutorialspots.com/lua-urlencode-and-urldecode-5528.html
	local function urlencode(str)
		str = string.gsub (str, "([^0-9a-zA-Z !'()*._~-])", -- locale independent
		function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
		return str
	end

	local comando1 = 'sleep 2 ; curl "https://nominatim.openstreetmap.org/search?countrycodes=uy&format=jsonv2&bounded=1&q=' .. urlencode(nombres[varian][2]) .. viewbox(idents[datos.inicio]) .. '" > ' .. varian .. '_inicio_inicio.json'
	local comando2 = 'sleep 2 ; curl "https://nominatim.openstreetmap.org/search?countrycodes=uy&format=jsonv2&bounded=1&q=' .. urlencode(nombres[varian][3]) .. viewbox(idents[datos.inicio]) .. '" > ' .. varian .. '_inicio_final.json'
	local comando3 = 'sleep 2 ; curl "https://nominatim.openstreetmap.org/search?countrycodes=uy&format=jsonv2&bounded=1&q=' .. urlencode(nombres[varian][2]) .. viewbox(idents[datos.final]) .. '" > ' .. varian .. '_final_inicio.json'
	local comando4 = 'sleep 2 ; curl "https://nominatim.openstreetmap.org/search?countrycodes=uy&format=jsonv2&bounded=1&q=' .. urlencode(nombres[varian][3]) .. viewbox(idents[datos.final]) .. '" > ' .. varian .. '_final_final.json'

	print(comando1) print(comando2) print(comando3) print(comando4)
end end

]]























--[[ Para guardar idents en un archivo

local mvd_file = io.open("MontevideoModificado.osm", "r")
local mvd_xml = mvd_file:read("*all")
mvd_file:close()
local mvd = SLAXML:dom(mvd_xml, {stripWhitespace=true, simple=true})
mvd_file, mvd_xml = nil, nil

local idents = {}

for _, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	local id, lat, lon = 0, 0, 0
	for _, attr in ipairs(node.attr) do
		if     attr.name == "id"  then id  = attr.value
		elseif attr.name == "lat" then lat = tonumber(attr.value)
		elseif attr.name == "lon" then lon = tonumber(attr.value) end
	end

	local cuenta, ref = 0, 0
	for _, tag in ipairs(node.kids) do if tag.name == "tag" then
		local k, v = tag.attr[1].value, tag.attr[2].value
		if  k == "ref" then ref = v end
		if (k == "public_transport" and v == "platform") or
			k == "ref" then cuenta = cuenta + 1 end
		if cuenta == 2 then
			--idents[ref] = {id=id, lat=lat, lon=lon}
			print("["..ref.."] = {id="..id..", lat="..lat..", lon="..lon.."}")
		end
	end end

end end

]]











local nombres = require("nombres") -- [varian] = {numero,origen,destino, por}

local idents = require("idents") -- [ref] = {id=id, lat=lat, lon=lon}

local correcto = {}

for varian, datos in pairs(nombres) do
	function imprimir(varian, datos, invertir)
		io.write("[", varian, "] = {")
		if invertir == false then
			if datos[4] == nil then io.write(datos[1], ", ", datos[2], ", ", datos[3], "},\n")
			else io.write(datos[1], ", ", datos[2], ", ", datos[3], ", ", datos[4], "},\n") end
		elseif invertir == true then
			if datos[4] == nil then io.write(datos[1], ", ", datos[3], ", ", datos[2], "},\n")
			else io.write(datos[1], ", ", datos[3], ", ", datos[2], ", ", datos[4], "},\n") end
		end
	end
	correcto[varian] = {}

	local file = io.open("./resultados/"..varian.."_inicio_inicio.json", "r")
	if file ~= nil then
		local i_i = file:read("*all")
		file:close()
		file = io.open("./resultados/"..varian.."_inicio_final.json", "r")
		local i_f = file:read("*all")
		file:close()
		file = io.open("./resultados/"..varian.."_final_final.json", "r")
		local f_f = file:read("*all")
		file:close()
		file = io.open("./resultados/"..varian.."_final_inicio.json", "r")
		local f_i = file:read("*all")
		file:close()

		if (#i_i>2  and #i_f==2 and #f_f>2  and #f_i==2) or   -- Normal
		   (#i_i>2  and #i_f==2 and #f_f==2 and #f_i==2) or   -- Origen
		   (#i_i==2 and #i_f==2 and #f_f>2  and #f_i==2) then -- Destino
			imprimir(varian, datos, false) -- No hay que hacer nada especial
		elseif (#i_i==2 and #i_f>2  and #f_f==2 and #f_i>2 ) or -- Invertido
		       (#i_i==2 and #i_f>2  and #f_f==2 and #f_i==2) or
		       (#i_i==2 and #i_f==2 and #f_f==2 and #f_i>2 ) then
			imprimir(varian, datos, true) -- Hay que invertir origen y destino
		else
			local ref_i = destinos[varian].inicio
			local ref_f = destinos[varian].final
			print("-- Dudoso:", varian, "origen", ref_i, "destino", ref_f)

			print("-- ¿Es esto '" .. datos[2] .. "'? (otra opción: '"..datos[3].."')")
			os.execute('xdg-open "openstreetmap.org/#map=19/' ..
					idents[ref_i].lat.."/"..idents[ref_i].lon..'"')
			if io.read() == "s" then
				imprimir(varian, datos, false) -- No hay que hacer nada especial
			else
				print("-- ¿¿Es esto '" .. datos[3] .. "'??")
				if io.read() == "s" then
					imprimir(varian, datos, true) -- Hay que invertir origen y destino
				else
					print("-- ¿¿¿Es esto '" .. datos[3] .. "'???")
					os.execute('xdg-open "openstreetmap.org/#map=19/' ..
							idents[ref_f].lat.."/"..idents[ref_f].lon..'&layers=O"')
					if io.read() == "s" then
						imprimir(varian, datos, false) -- No hay que hacer nada especial
					else
						print("-- ¿¿¿¿Es esto '" .. datos[2] .. "'????")
						if io.read() == "s" then
							imprimir(varian, datos, true) -- Hay que invertir origen y destino
						end
					end
				end
			end
		end
	end
end
