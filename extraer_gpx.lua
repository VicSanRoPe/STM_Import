local utils = require("utils")
local readXML, writeXML, printTable, fileExists, trace = table.unpack(utils)

local nombres = require("nombres")

local lineas = readXML("lineas.xml").kids[2].kids


--[[ Objetivo
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.0">
	<trk><name>Example gpx</name><number>1</number><trkseg>
		<trkpt lat="46.57608333" lon="8.89241667"></trkpt>
		<trkpt lat="46.57619444" lon="8.89252778"></trkpt>
		<trkpt lat="46.57641667" lon="8.89266667"></trkpt>
		<trkpt lat="46.57650000" lon="8.89280556"></trkpt>
		<trkpt lat="46.57638889" lon="8.89302778"></trkpt>
		<trkpt lat="46.57652778" lon="8.89322222"></trkpt>
		<trkpt lat="46.57661111" lon="8.89344444"></trkpt>
	</trkseg></trk>
</gpx>
]]


local variantes = {}



for _, features in pairs(lineas) do if features.name == "features" then
	local xml = {type="document", name="#doc", kids = {
		{type="pi", name="xml", value='version="1.0" encoding="UTF-8"'},
		{type="element", name="gpx", attr={
				{type="attribute", name="version", value="1.0"}}, kids={
			{type="element", name="trk", kids={
				{type="element", name="trkseg", kids={

				}}
			}}
		}}
	}}

	local arr = xml.kids[2].kids[1].kids[1].kids

	local varian = tonumber(features.kids[3].kids[7].kids[1].value)
	if nombres[varian] ~= nil then

		for _, coords in pairs(features.kids[2].kids) do
				if coords.name == "coordinates" then
			local lat = coords.kids[2].kids[1].value
			local lon = coords.kids[1].kids[1].value

			local trkpt = {type="element", name="trkpt", attr={
					{type="attribute", name="lat", value=lat},
					{type="attribute", name="lon", value=lon}}}
			arr[#arr+1] = trkpt
		end end

		local nombre = varian .. ".gpx"
		variantes[varian] = nombre

		-- Descomentar para generar los .gpx --------------------------------
		-- writeXML(xml, "./lineasrutas/" .. nombre)
	end
end end


local comando = "cd lineasrutas && java -jar graphhopper-web-5.3.jar match --file config.yml --profile car --gps_accuracy 25 "

for varian, nombre in pairs(variantes) do
	comando = comando .. '"' .. nombre .. '" '
end


os.execute(comando)






local lineas_procesadas = {}

for varian, nombre in pairs(variantes) do
	local puntos = readXML("./lineasrutas/" .. nombre .. ".res.gpx")
	puntos = puntos.kids[2].kids[2].kids[2].kids

	lineas_procesadas[varian] = {}

	for _, punto in ipairs(puntos) do
		local lat, lon = nil, nil
		for _, attr in ipairs(punto.attr) do
			if attr.name == "lat" then lat = tonumber(attr.value) end
			if attr.name == "lon" then lon = tonumber(attr.value) end
		end
		table.insert(lineas_procesadas[varian], {lat=lat, lon=lon})
	end
end

printTable(lineas_procesadas, "lineas_procesadas.lua")







