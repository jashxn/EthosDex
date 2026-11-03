--!nocheck
--[[
	Explorer search. A query is space-separated terms that must all match:
		class:Part    exact ClassName (any case)
		isa:BasePart  IsA
		tag:Coin      has the CollectionService tag
		attr:Health   has the attribute
		WalkSpeed>16  a property compared: = != > < >= <=, or ~ for "contains" (any case)
		anything else part of the Name (any case, plain text)
	`run` walks the game in slices so a big place never freezes a frame, and returns the
	explorer filter: instance -> 1 for a match, 2 for an ancestor of one, 3 for both.
]]

local Tree = require(script.Parent.tree)

local Search = {}

Search.LIMIT = 3000
local SLICE = 3000

local OPERATORS = {
	["="] = "=",
	["=="] = "=",
	["!="] = "!=",
	["~="] = "!=",
	[">"] = ">",
	["<"] = "<",
	[">="] = ">=",
	["<="] = "<=",
	["~"] = "~",
}

-- `actual` (a property's value) against the typed text, under `operator`.
function Search.compare(actual, operator: string, wanted: string): boolean
	if typeof(actual) == "EnumItem" then
		actual = actual.Name
	end
	local number = tonumber(wanted)
	if operator == ">" or operator == "<" or operator == ">=" or operator == "<=" then
		if type(actual) ~= "number" or number == nil then
			return false
		end
		return if operator == ">" then actual > number
			elseif operator == "<" then actual < number
			elseif operator == ">=" then actual >= number
			else actual <= number
	end
	local text, lowered = string.lower(tostring(actual)), string.lower(wanted)
	if operator == "~" then
		return string.find(text, lowered, 1, true) ~= nil
	end
	local equal = if type(actual) == "number" and number then actual == number else text == lowered
	return if operator == "!=" then not equal else equal
end

function Search.parse(query: string)
	local conditions = {
		Name = nil,
		Class = nil,
		IsA = nil,
		Tag = nil,
		Attribute = nil,
		Compare = {},
	}
	local words = {}
	for term in string.gmatch(query, "%S+") do
		local property, symbol, wanted = string.match(term, "^([%a_][%w_]*)([<>=!~]+)(.*)$")
		local operator = symbol and OPERATORS[symbol]
		local key, value = string.match(term, "^(%a+):(.+)$")
		key = key and string.lower(key)
		if operator then
			table.insert(conditions.Compare, { property, operator, wanted })
		elseif key == "class" then
			conditions.Class = string.lower(value)
		elseif key == "isa" then
			conditions.IsA = value
		elseif key == "tag" then
			conditions.Tag = value
		elseif key == "attr" then
			conditions.Attribute = value
		else
			table.insert(words, term)
		end
	end
	if #words > 0 then
		conditions.Name = string.lower(table.concat(words, " "))
	end
	return conditions
end

function Search.matches(instance: Instance, conditions): boolean
	local ok, result = pcall(
		function()
			if conditions.Name
				and not string.find(string.lower(instance.Name), conditions.Name, 1, true) then
				return false
			end
			if conditions.Class and string.lower(instance.ClassName) ~= conditions.Class then
				return false
			end
			if conditions.IsA and not instance:IsA(conditions.IsA) then
				return false
			end
			if conditions.Tag and not instance:HasTag(conditions.Tag) then
				return false
			end
			if conditions.Attribute and instance:GetAttribute(conditions.Attribute) == nil then
				return false
			end
			-- A missing property throws, so instances without it don't match.
			for _, rule in conditions.Compare do
				if not Search.compare(instance[rule[1]], rule[2], rule[3]) then
					return false
				end
			end
			return true
		end
	)
	return ok and result
end

function Search.mark(filter, instance, game)
	filter[instance] = bit32.bor(filter[instance] or 0, 1)
	local current = instance
	while true do
		local ok, parent = pcall(function()
			return current.Parent
		end)
		if not ok then
			return
		end
		if parent == nil then
			if current ~= game then
				filter[Tree.NIL_ROOT] = 2
			end
			return
		end
		if parent == game then
			return
		end
		local bits = filter[parent] or 0
		if bit32.band(bits, 2) ~= 0 then
			return
		end
		filter[parent] = bit32.bor(bits, 2)
		current = parent
	end
end

-- Yields. `isCancelled()` stops early (a newer query started). Returns filter, count, capped.
function Search.run(
	game: Instance,
	query: string,
	nilInstances: { Instance }?,
	isCancelled: () -> boolean
)
	local conditions = Search.parse(query)
	local filter, count = {}, 0
	local sources = { game:GetDescendants() }
	if nilInstances then
		local list = {}
		for _, object in nilInstances do
			table.insert(list, object)
			local ok, descendants = pcall(object.GetDescendants, object)
			if ok then
				table.move(descendants, 1, #descendants, #list + 1, list)
			end
		end
		table.insert(sources, list)
	end
	local checked = 0
	for _, list in sources do
		for _, instance in list do
			checked += 1
			if checked % SLICE == 0 then
				task.wait()
				if isCancelled() then
					return nil, 0, false
				end
			end
			if Search.matches(instance, conditions) then
				count += 1
				Search.mark(filter, instance, game)
				if count >= Search.LIMIT then
					return filter, count, true
				end
			end
		end
	end
	return filter, count, false
end

return Search
