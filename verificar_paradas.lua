local SLAXML = require("slaxdom")

local mvd_file = io.open("MontevideoConParadas.osm", "r")
local mvd_xml = mvd_file:read("*all")
mvd_file:close()
local mvd = SLAXML:dom(mvd_xml, {stripWhitespace=true, simple=true})
print("Mapa leído")




local todas = {name="root", type="element", kids = {}}
local noref = {name="root", type="element", kids = {}}
local malas = {name="root", type="element", kids = {}}
local doble = {name="root", type="element", kids = {}}

local refs  = {}


for _, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	for _, tag in ipairs(node.kids) do if tag.name == "tag" then
		local k, v = tag.attr[1].value, tag.attr[2].value
		if  k == "public_transport" and v == "platform" then
			todas.kids[#todas.kids+1] = node break end
	end end
end end

print("Encontradas: ", #todas)

------------------------------------------------------------------------------

--Para obtener paradas incorrectas
local good_tags = {"public_transport", "ref", -- Debe estar
-- Anticuadas
"source:pkey", "source", "mvdgis:cod_varian", "mvdgis:desc_linea", "mvdgis:ordinal", "mvdgis:source",
-- Opcionales
"network", "bus", "highway", "name", "operator", "shelter", "bench", "lit", "bin"}

for _, node in ipairs(todas.kids) do
	local falta = true
	local ref = 0
	local lat, lon = 0, 0

	for _, attr in ipairs(node.attr) do
		if attr.name == "lat" then lat = attr.value
		elseif attr.name == "lon" then lon = attr.value end
	end

	for _, tag in ipairs(node.kids) do
		local k, v = tag.attr[1].value, tag.attr[2].value
		if k == "ref" then ref = v end
	end


	for _, tag in ipairs(node.kids) do
		local k, v = tag.attr[1].value, tag.attr[2].value
		for _, tname in pairs(good_tags) do
			if tname == k then falta = false break end end
		if falta == true then malas.kids[#malas.kids+1] = node break end

	end


	if ref == 0 then
		local deleted = false
		for _, attr in ipairs(node.attr) do
			--print(attr.name, attr.value)
			if attr.name == "action" and attr.value == "delete" then
				deleted = true break end
		end
		if deleted == false then noref.kids[#noref.kids+1] = node end
	elseif refs[ref] == nil then
		refs[ref] = 1
	else
		refs[ref] = refs[ref] + 1
		doble.kids[#doble.kids+1] = node
	end
end

print("Sin referencia: ", #noref.kids)
print("Etiquetas malas:", #malas.kids)
print("Ref. duplicadas:", #doble.kids)

------------------------------------------------------------------------------



local out_str = SLAXML:xml(noref, {indent = "\t"})
local out = io.open("paradas_noref.xml", "w")
out:write(out_str)
out:close()
local out_str = SLAXML:xml(malas, {indent = "\t"})
local out = io.open("paradas_malas.xml", "w")
out:write(out_str)
out:close()
local out_str = SLAXML:xml(doble, {indent = "\t"})
local out = io.open("paradas_doble.xml", "w")
out:write(out_str)
out:close()


