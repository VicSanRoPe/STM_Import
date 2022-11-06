local utils = require("utils")
local readXML, writeXML, printTable, fileExists, trace = table.unpack(utils)


local paradas = readXML("paradas.xml")
local mvd = readXML("Montevideo.osm")


-- https://github.com/maxm/osmuy/blob/master/osmuy/Main.cs
local nombres_correjidos = {
	["VAZQUEZ"] = "Vázquez",
	["COPOLA"] = "Cópola",
	["GUILLAMON"] = "Guillamón",
	["ANDRES"] = "Andrés",
	["JOAQUIN"] = "Joaquín",
	["SUAREZ"] = "Suárez",
	["ABAYUBA"] = "Abayubá",
	["BAHIA"] = "Bahía",
	["MARIA"] = "María",
	["ESTACION"] = "Estación",
	["MARTIN"] = "Martín",
	["LIBANO"] = "Líbano",
	["CONCEPCION"] = "Concepción",
	["COLON"] = "Colón",
	["NUMERO"] = "Número",
	["CUALEGON"] = "Cualegón",
	["PARAISO"] = "Paraíso",
	["INGENIERIA"] = "Ingeniería",
	["REPUBLICA"] = "República",
	["ECONOMICAS"] = "Económicas",
	["ADMINISTRACION"] = "Administración",
	["AGRONOMIA"] = "Agronomía",
	["GASTON"] = "Gastón",
	["FUTBOL"] = "Fútbol",
	["MALAGA"] = "Málaga",
	["GERMAN"] = "Germán",
	["QUIMICA"] = "Química",
	["TECNICA"] = "Técnica",
	["INDIGENA"] = "Indígena",
	["HISTORICO"] = "Histórico",
	["SOLIS"] = "Solís",
	["RAMON"] = "Ramón",
	["PITAGORAS"] = "Pitágoras",
	["CASABO,"] = "Casabó,",
	["TELEFONO"] = "Teléfono",
	["PUBLICO"] = "público",
	["OCEANOGRAFICO"] = "Oceanográfico",
	["LYON"] = "Lyón",
	["BATOVI"] = "Batoví",
	["TABARE"] = "Tabaré",
	["YAMANDU"] = "Yamandú",
	["JOSE"] = "José",
	["RODO"] = "Rodó",
	["AMERICO"] = "Américo",
	["CONVENCION"] = "Convención",
	["RODRIGUEZ"] = "Rodríguez",
	["DIAZ"] = "Díaz",
	["GARCIA"] = "García",
	["TOMAS"] = "Tomás",
	["QUINTIN"] = "Quintín",
	["FERNANDEZ"] = "Fernández",
	["SANCHEZ"] = "Sánchez",
	["TIMBO"] = "Timbó",
	["SIMON"] = "Simón",
	["BOLIVAR"] = "Bolívar",
	["MARTI"] = "Martí",
	["PEREZ"] = "Pérez",
	["GOMEZ"] = "Gómez",
	["PAYSANDU"] = "Paysandú",
	["RINCON"] = "Rincón",
	["YACARE"] = "Yacaré",
	["GUARANI"] = "Guaraní",
	["ITUZAINGO"] = "Ituzaingó",
	["AMORIN"] = "Amorín",
	["TACUAREMBO"] = "Tacuarembó",
	["DEMOSTENES"] = "Demóstenes",
	["TRISTAN"] = "Tristán",
	["LIBER"] = "Líber",
	["CONSTITUCION"] = "Constitución",
	["CUFRE"] = "Cufré",
	["ASUNCION"] = "Asunción",
	["PANAMA"] = "Panamá",
	["CESAR"] = "César",
	["FE"] = "Fé",
	["CIVICOS"] = "Cívicos",
	["FARIAS"] = "Farías",
	["CAPITAN"] = "Capitán",
	["RIO"] = "Río",
	["ORDOÑEZ"] = "Ordóñez",
	["MILLAN"] = "Millán",
	["AMERICA"] = "América",
	["POLICIA"] = "Policía",
	["BAUZA"] = "Bauzá",
	["LEGUIZAMON"] = "Leguizamón",
	["AMERICAS"] = "Américas",
	["MARTINEZ"] = "Martínez",
	["LOPEZ"] = "López",
	["ESPINOLA"] = "Espínola",
	["CONTINUACION"] = "Continuación",
	["BARTOLOME"] = "Bartolomé",
	["UNION"] = "Unión",
	["ARBOLES"] = "árboles",
	["PAJAROS"] = "Pájaros",
	["HIPODROMO"] = "Hipódromo",
	["SARANDI"] = "Sarandí",
	["HAITI"] = "Haití",
	["PUBLICA"] = "Pública",
	["JAPON"] = "Japón",
	["CANADA"] = "Canadá",
	["PERU"] = "Perú",
	["CEBOLLATI"] = "Cebollatí",
	["YAGUARON"] = "Yaguarón",
	["GARZON"] = "Garzón",
	["IBIRAPITA"] = "Ibirapitá",
	["CHAJA"] = "Chajá",
	["JUPITER"] = "Júpiter",
	["ALVAREZ"] = "Álvarez",
	["ROSE"] = "Rosé",
	["LAZARO"] = "Lázaro",
	["FEDERACION"] = "Federación",
	["MEDIODIA"] = "Mediodía",
	["RIOS"] = "Ríos",
	["ARQUIMEDES"] = "Arquímedes",
	["OTORGUES"] = "Otorgués",
	["ANASTASIO"] = "Anastásio",
	["REDENCION"] = "Redención",
	["POLVORIN"] = "polvorín",
	["BERNABE"] = "Bernabé",
	["EMANCIPACION"] = "Emancipación",
	["ANGEL"] = "Ángel",
	["RAMIREZ"] = "Ramírez",
	["TURQUIA"] = "Turquía",
	["BOGOTA"] = "Bogotá",
	["BELGICA"] = "Bélgica",
	["MEXICO"] = "México",
	["MALVIN"] = "Malvín",
	["CONCILIACION"] = "Conciliación",
	["PINZON"] = "Pinzón",
	["AGUSTIN"] = "Agustín",
	["MARACANA"] = "Maracaná",
	["SOFIA"] = "Sofía",
	["SEBASTIAN"] = "Sebastián",
	["OLIMPICO"] = "Olímpico",
	["CAMAMBU"] = "Camambú",
	["HUERFANAS"] = "Huérfanas",
	["OMBU"] = "Ombú",
	["LUCIA"] = "Lucía",
	["ÑANGUIRU"] = "Ñanguirú",
	["MANGORE"] = "Mangoré",
	["ARAGON"] = "Aragón",
	["CAAZAPA"] = "Caazapá",
	["TANGARUPA"] = "Tangarupá",
	["CARAPEGUA"] = "Carapeguá",
	["VELODROMO"] = "Velódromo",
	["GUZMAN"] = "Guzmán",
	["GUAYRA"] = "Guayrá",
	["QUINTIN)"] = "Quintín)",
	["ASIS"] = "Asís",
	["JESUS"] = "Jesús",
	["FARAMIÑAN"] = "Faramiñán",
	["JULIAN"] = "Julián",
	["GUAZUCUA"] = "Guazucuá",
	["BOQUERON"] = "Boquerón",
	["TURUBI"] = "Turubí",
	["ABIARU"] = "Abiarú",
	["CAPIATA"] = "Capiatá",
	["NEUQUEN"] = "Neuquén",
	["TUCUMAN"] = "Tucumán",
	["CORDOBA"] = "Córdoba",
	["ITAPE"] = "Itapé",
	["MARMOL"] = "Mármol",
	["DIOGENES"] = "Diógenes",
	["CAONABO"] = "Caonabó",
	["AGUEDA"] = "Águeda",
	["LEON"] = "León",
	["CORDOBES"] = "Cordobés",
	["GARRE"] = "Garré",
	["VAZQUES"] = "Vázques",
	["CADIZ"] = "Cádiz",
	["YAPEYU"] = "Yapeyú",
	["CATALA"] = "Catalá",
	["MONICA"] = "Mónica",
	["FAMAILLA"] = "Famaillá",
	["INDIGENAS"] = "Indígenas",
	["GUTIERREZ"] = "Gutiérrez",
	["BLAS"] = "Blás",
	["TRIAS"] = "Trías",
	["GALAN"] = "Galán",
	["FELIX"] = "Félix",
	["CACERES"] = "Cáceres",
	["ADRIAN"] = "Adrián",
	["GALVAN"] = "Galván",
	["BELTRAN"] = "Beltrán",
	["MENDEZ"] = "Méndez",
	["GONZALEZ"] = "González",
	["PADRON"] = "Padrón",
	["DURAN"] = "Durán",
	["SAA"] = "Saá",
	["AMEZAGA"] = "Amézaga",
	["MARMARAJA"] = "Marmarajá",
	["PATRON"] = "Patrón",
	["YAGUARI"] = "Yaguarí",
	["CUÑAPIRU"] = "Cuñapirú",
	["EJERCITO"] = "Ejército",
	["CARAGUATA"] = "Caraguatá",
	["HEMOGENES"] = "Hemógenes",
	["GUAVIYU"] = "Guaviyú",
	["CARAPE"] = "Carapé",
	["CAICOBE"] = "Caicobé",
	["COMANDIYU"] = "Comandiyú",
	["TRAPANI"] = "Trápani",
	["GONZALES"] = "Gonzáles",
	["TREBOL"] = "Trébol",
	["TUYUTI"] = "Tuyutí",
	["ZUBIRIA"] = "Zubiría",
	["VICTOR"] = "Víctor",
	["JARDIN"] = "Jardín",
	["JAPONES"] = "Japonés",
	["BOTANICO"] = "Botánico",
	["MAXIMO"] = "Máximo",
	["ROSALIA"] = "Rosalía",
	["SALONICA"] = "Salónica",
	["JUCUTUJA"] = "Jucutujá",
	["MOLIERE"] = "Moliére",
	["VELAZQUEZ"] = "Velázquez",
	["MARQUEZ"] = "Márquez",
	["DOMINGUEZ"] = "Domínguez",
	["PANTALEON"] = "Pantaleón",
	["GOYEN"] = "Goyén",
	["CORCEGA"] = "Córcega",
	["MEDITERRANEO"] = "Mediterráneo",
	["RAUL"] = "Raúl",
	["CAMARA"] = "Cámara",
	["TECNOLOGICO"] = "Tecnológico",
	["CUARAHI"] = "Cuarahí",
	["PIRARAJA"] = "Pirarajá",
	["GUAZUNAMBI"] = "Guazunambí",
	["YUQUERI"] = "Yuquerí",
	["TAMANDUA"] = "Tamanduá",
	["TACUMBU"] = "Tacumbú",
	["TIMON"] = "Timón",
	["MATIAS"] = "Matías",
	["CATOLICA"] = "Católica",
	["DAMASO"] = "Dámaso",
	["ARAZATI"] = "Arazatí",
	["NUÑEZ"] = "Núñez",
	["AVALOS"] = "Ávalos",
	["ESTRAZULAS"] = "Estrázulas",
	["ALMIRON"] = "Almirón",
	["OMBUES"] = "Ombúes",
	["PODESTA"] = "Podestá",
	["JACARANDA"] = "Jacarandá",
	["VIA"] = "Vía",
	["ISOLICA"] = "Isólica",
	["ETIOPIA"] = "Etiopía",
	["CAMERUN"] = "Camerún",
	["MARIN"] = "Marín",
	["BALBIN"] = "Balbín",
	["CORUMBE"] = "Corumbé",
	["BERLIN"] = "Berlín",
	["ALTANTICO"] = "Altántico",
	["ALMERIA"] = "Almería",
	["ACEGUA"] = "Aceguá",
	["CORTES"] = "Cortés",
	["SORIN"] = "Sorín",
	["GURUYA"] = "Guruyá",
	["ERRIA"] = "Erría",
	["ARAMBURU"] = "Aramburú",
	["TURIN"] = "Turín",
	["PIRAN"] = "Pirán" ,
	["MARIAS"] = "Marías" ,
	["LANUS"] = "Lanús" ,
	["FENIX"] = "Fénix" ,
	["IGUA"] = "Iguá" ,

	["BV"] = "Bulevar" ,
	["AV"] = "Avenida" ,
	["GRAL"] = "General" ,
	["CNO"] = "Camino" ,
	["TTE"] = "Teniente" ,
	["ARQ"] = "Arquitecto" ,
	["DUQ"] = "Duque" ,
	["FCO"] = "Francisco" ,
	["PTE"] = "Presidente" ,
	["PSJE"] = "Pasaje" ,
	["PLA"] = "paralela" ,
	["1RA"] = "primera" ,
	["1ER"] = "primer" ,
	["2DA"] = "segunda" ,
	["3RA"] = "tercera" ,
	["4TA"] = "cuarta" ,
	["5TA"] = "quinta" ,
	["BEL"] = "Belloni" ,
	["PDRE"] = "Padre" ,
	["BO"] = "Barrio" ,
	["SEND"] = "Sendero" ,
	["CAP"] = "Capitán" ,
	["CONT"] = "Continuación" ,
	["PROF"] = "Profesor" ,
	["DR"] = "Doctor" ,
	["DR."] = "Doctor" ,
	["DRA"] = "Doctora",
	["PNAL"] = "Peatonal" ,
	["ASENT"] = "Asentamiento" ,
	["STA"] = "Santa" ,
	["STO"] = "Santo" ,
	["ING"] = "Ingeniero" ,
	["MTRO"] = "Maestro" ,
	["MTRA"] = "Maestra" ,
	["GDOR"] = "Gobernador" ,
	["MDRE"] = "Madre" ,
	["CDTE"] = "Comandante" ,
	["ALMTE"] = "Almirante" ,
	["CNEL"] = "Coronel" ,
	["AGRM"] = "Agrimensor" ,
	["RBLA"] = "Rambla" ,
	["MCAL"] = "Mariscal" ,
	["NAL"] = "Nacional" ,
	["ESC"] = "Escuela" ,
	["SDA"] = "Senda" ,
	["AVDA"] = "Avenida",
	["TERM"] = "Terminal",

	["Y"] = "y",
	["DE"] = "de",
	["DEL"] = "del",
	["LA"] = "la",
	["LOS"] = "los",
	["LAS"] = "las",
	["EL"] = "el",
	["AL"] = "al",
	["A"] = "a"
}


function procesar_nombre(nombre)
	if nombre == "FRANCISCO PLA" then
		return "Francisco Pla" end
	if nombre == "B GR MANUEL ORIBE" then
		return "Brigadier General Manuel Oribe" end
	if nombre == "J BATLLE Y ORDOÑEZ" then
		return "Bulevar José Batlle y Ordóñez" end
	if nombre == "RUTA NAL 8 BRIG GRAL J A LAVALLEJA" then
		return "Ruta 8 Brigadier General Juan Antonio Lavalleja" end
	if nombre == "AV DRA MA L SALDUN DE RODRIGUEZ" then
		return "Avenida Doctora María Luisa Saldún de Rodríguez" end
	if nombre == "AV LIB BRIG GRAL LAVALLEJA" then
		return "Avenida Libertador Brigadier General Lavalleja" end
	if nombre == "JOSE A POSOLO" then
		return "José A. Possolo" end

	local res = ""
	for palabra in nombre:gmatch("%S+") do
		if nombres_correjidos[palabra] ~= nil then
			res = res .. nombres_correjidos[palabra] .. " "
		else
			if palabra:len() > 1 then
				res = res .. palabra:sub(1,1) .. palabra:sub(2):lower():gsub("Ñ", "ñ") .. " "
			elseif palabra:find("%a") ~= nil then -- Letras
				res = res .. palabra .. ". "
			else
				res = res .. palabra .. " "
			end
		end
	end
	res = res:gsub(" $", "")
	res = res:sub(1,1):upper()..res:sub(2)
	return res
end


local coords = {}
local cambiadas = {}
local borradas = {}


for _, parada in ipairs(paradas.kids[2].kids) do
	if parada.name == "features" then
		local geometry = parada.kids[2].kids
		local lat = geometry[3].kids[1].value
		local lon = geometry[2].kids[1].value
		local properties = parada.kids[3].kids
		local id = properties[1].kids[1].value
		local calle = properties[5].kids[1].value
		local esquina = properties[6].kids
		if #esquina > 0 then esquina = esquina[1].value else esquina = nil end
		if esquina == "CALLE FICTICIA" or esquina == "S/N" then esquina = nil end
		if coords[id] == nil then
			coords[id] = {lat = lat, lon = lon}
			if calle ~= nil and esquina ~= nil then
				coords[id].name = procesar_nombre(calle) ..
				" y " .. procesar_nombre(esquina)
			elseif calle ~= nil then
				coords[id].name = procesar_nombre(calle)
			end
		end
	end
end


printTable(coords, "coords_cache.lua")


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


local function buscar_tag(node, tagdesc)
	for i, tag in pairs(node.kids) do if tag.name == "tag" then
		local k, v = tag.attr[1].value, tag.attr[2].value
		if type(tagdesc) == "string" then
			if k == tagdesc then return i end
		else -- Es un arreglo con k y v
			if k == tagdesc[1] and v == tagdesc[2] then return i end
		end
	end end
	return nil
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


local primer_node = nil -- Aquí insertaremos todas las paradas


--------------------- Paradas rotas (un pkey y un ref) ----------------------

for indice, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	primer_node = primer_node or indice -- Guardar el primer node

	local id = buscar_con_tags(node, "source:pkey",
		"source:pkey", {"public_transport", "platform"})

	-- Encontramos la parada y esta en la lista
	if id ~= nil and coords[id] ~= nil then
		print("Reparando", id)
		for i, tag in pairs(node.kids) do if tag.name == "tag" then
			local k, v = tag.attr[1].value, tag.attr[2].value
			if  k == "ref" then eliminar_tag(tag) end
		end end

		terminar_eliminacion(node)
	end
end end

print("Primer nodo "..primer_node)

------------------------------------------------------------------------------


local tags_a_eliminar = {
	"mvdgis:cod_varian", "mvdgis:desc_linea", "mvdgis:ordinal",
	{"mvdgis:source", "v_uptu"}, {"source", "mvdgis"}
}


--------------------------- Paradas actualizadas ----------------------------


for _, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	local id = buscar_con_tags(node, "ref",
		"ref", {"public_transport", "platform"})

	-- Encontramos la parada
	if id ~= nil then

		if coords[id] == nil then -- Si no existe (verificación algo mala)
			print("Ignorada actualizada", id)
			borradas[#borradas+1] = id

			--[[node.attr[#node.attr+1] =
				{type = "attribute", name = "action", value = "delete"}
			]]

		else --Existe
			print("Encontrada actualizada", id)
			cambiadas[#cambiadas+1] = id

			local cambiado = false

			local name_i = buscar_tag(node, "name")
			-- Si no tiene un nombre, pero nosotros sí lo tenemos
			if name_i == nil and coords[id].name then
				table.insert(node.kids, {type="element", name="tag", attr={
					{type="attribute", name = "k", value = "name"},
					{type="attribute", name = "v", value = coords[id].name}}
				})
				cambiado = true
			end

			for _, info in ipairs(tags_a_eliminar) do
				local eliminar_i = nil
				eliminar_i = buscar_tag(node, info)
				if eliminar_i ~= nil then
					eliminar_tag(node.kids[eliminar_i])
					cambiado = true
				end
			end

			--[[
			-- Agregar tag de parada de bus (la wiki dice obligatorio)
			node.kids[#node.kids+1] = {type="element", name="tag",
				attr = {
					{type = "attribute", name = "k", value = "highway"},
					{type = "attribute", name = "v", value = "bus_stop"}}
			}]]

			if cambiado == true then
				terminar_eliminacion(node)
				node.attr[#node.attr+1] =
					{type="attribute", name = "action", value = "modify"}
			end

			coords[id] = nil -- Terminamos con esta parada
		end
	end

end end


------------------------------------------------------------------------------



for _, node in ipairs(mvd.kids[2].kids) do if node.name == "node" then
	local id = buscar_con_tags(node, "source:pkey",
			"source:pkey", {"public_transport", "platform"}, "source",
			"mvdgis:cod_varian", "mvdgis:ordinal", "mvdgis:source", "network")

	if id ~= nil then
		if coords[id] == nil then -- Si no existe (verificación algo mala)
			print("Borrada", id)
			borradas[#borradas+1] = id

			node.attr[#node.attr+1] =
				{type = "attribute", name = "action", value = "delete"}

		else -- Existe
			print("Encontrada", id)
			cambiadas[#cambiadas+1] = id

			for _, info in ipairs(tags_a_eliminar) do
				local eliminar_i = nil
				eliminar_i = buscar_tag(node, info)
				if eliminar_i ~= nil then
					eliminar_tag(node.kids[eliminar_i])
				end
			end

			-- Reemplazar source:pkey por ref
			for i, tag in pairs(node.kids) do if tag.name == "tag" then
				if  tag.attr[1].value == "source:pkey" then
					tag.attr[1].value = "ref"
				end
			end end

			if coords[id].name then -- Agregar tag de nombre, si lo tenemos
				table.insert(node.kids, {type="element", name="tag", attr={
					{type="attribute", name = "k", value = "name"},
					{type="attribute", name = "v", value = coords[id].name}}
				})
			end

			-- Agregar tag de parada de bus (la wiki dice obligatorio)
-- 			table.insert(node.kids, {type="element", name="tag", attr={
-- 				{type="attribute", name = "k", value = "highway"},
-- 				{type="attribute", name = "v", value = "bus_stop"}}
-- 			})

			local no_cambiar = {"1172","1182","1173","1174","1179","1176"}
			local cambiar = {"4078", "1105", "2959", "5493", "5550", "5620", "5633", "5302"}
			local function contiene(arr, val)
				for i, v in ipairs(arr) do
					if v == val then return true end end
				return false
			end
			for _, attr in ipairs(node.attr) do
			-- Actualizar ubicación si es la primera revisión, y excepciones
				if (attr.name == "version" and attr.value == "1" and
						not contiene(no_cambiar, id)) or
						contiene(cambiar, id) then
					for _, attr in ipairs(node.attr) do
						if attr.name == "lat" then
							attr.value = coords[id].lat
						elseif attr.name == "lon" then
							attr.value = coords[id].lon
						end
					end
				end
			end

			terminar_eliminacion(node)
			node.attr[#node.attr+1] =
				{type="attribute", name = "action", value = "modify"}

			coords[id] = nil -- Terminamos con esta parada
		end
	end
end end



local agregadas = {}

for id, _ in pairs(coords) do
	print("Agregada", id)
	agregadas[#agregadas+1] = id

	local node = {type="element", name="node",
		attr = {
			{type="attribute", name = "id",
					value = tostring(-101754 - #agregadas*3)},
			{type="attribute", name = "action", value = "modify"},
			{type="attribute", name = "visible", value = "true"},
			{type="attribute", name = "lat", value = coords[id].lat},
			{type="attribute", name = "lon", value = coords[id].lon},
		},
		kids = {
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "public_transport"},
				{type="attribute", name = "v", value = "platform"}
			}},
-- 			{type="element", name="tag", attr = {
-- 				{type="attribute", name = "k", value = "highway"},
-- 				{type="attribute", name = "v", value = "bus_stop"}
-- 			}},
			{type="element", name="tag", attr = {
				{type="attribute", name = "k", value = "ref"},
				{type="attribute", name = "v", value = id}
			}}
		}
	}
	if coords[id].name ~= nil then
		table.insert(node.kids, {type="element", name="tag", attr = {
			{type="attribute", name = "k", value = "name"},
			{type="attribute", name = "v", value = coords[id].name}
		}})
	end

	table.insert(mvd.kids[2].kids, primer_node, node) -- ¿Esto es lento?
	primer_node = primer_node + 1
end


--os.exit()


writeXML(mvd, "MontevideoConParadas.osm")

