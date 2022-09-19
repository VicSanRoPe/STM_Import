local SLAXML = require("slaxdom")


local function readXML(filename)
	local file = io.open(filename, "r")
	local xml = file:read("*all")
	file:close()
	local data = SLAXML:dom(xml, {stripWhitespace=true, simple=true})
	return data
end

local function writeXML(data, filename)
	local out_str = SLAXML:xml(data, {indent = "\t"})
	local out = io.open(filename, "w")
	out:write(out_str)
	out:close()
end

local function printTable(table, filename)
	local function printTableHelper(obj, nivel)
		local nivel = nivel or 0
		if type(obj) == "table" then
			io.write("{\n")
			nivel = nivel + 1
			for k, v in pairs(obj) do
				if type(k) == "string" then
					io.write(string.rep("\t", nivel), '["'..k..'"]', ' = ')
				end
				if type(k) == "number" then
					io.write(string.rep("\t", nivel), "["..k.."]", " = ")
				end
				printTableHelper(v, nivel)
				io.write(",\n")
			end
			nivel = nivel - 1
			io.write(string.rep("\t", nivel), "}")
		elseif type(obj) == "string" then
			io.write(string.format("%q", obj))
		else
			io.write(tostring(obj))
		end
	end

	if filename == nil then
		printTableHelper(table)
	else
		io.output(filename)
		io.write("return ")
		printTableHelper(table)
		io.close()
		io.output(io.stdout)
	end
end

local function fileExists(filename)
	local file = io.open(filename,"r")
	if file ~= nil then io.close(file) return true else return false end
end

local function trace(str)
	--print(str)
end

return {readXML, writeXML, printTable, fileExists, trace}
