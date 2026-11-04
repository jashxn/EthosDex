--!nocheck
-- Property values as the properties panel shows them, and text typed back into a value.

local Values = {}

local function num(n: number): string
	if n ~= n then
		return "nan"
	elseif n == math.huge then
		return "inf"
	elseif n == -math.huge then
		return "-inf"
	elseif n == math.floor(n) and math.abs(n) < 1e15 then
		return string.format("%d", n)
	end
	local text = string.format("%.3f", n)
	text = string.gsub(text, "0+$", "")
	return (string.gsub(text, "%.$", ""))
end
Values.num = num

local function join(...)
	local parts = table.pack(...)
	for index = 1, parts.n do
		parts[index] = num(parts[index])
	end
	return table.concat(parts, ", ")
end

function Values.format(value): string
	local kind = typeof(value)
	if kind == "nil" then
		return "nil"
	elseif kind == "string" then
		return value
	elseif kind == "number" then
		return num(value)
	elseif kind == "boolean" then
		return tostring(value)
	elseif kind == "Vector3" or kind == "Vector3int16" then
		return join(value.X, value.Y, value.Z)
	elseif kind == "Vector2" or kind == "Vector2int16" then
		return join(value.X, value.Y)
	elseif kind == "CFrame" then
		return join(value:GetComponents())
	elseif kind == "Color3" then
		return join(math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
	elseif kind == "BrickColor" then
		return value.Name
	elseif kind == "UDim" then
		return join(value.Scale, value.Offset)
	elseif kind == "UDim2" then
		return `\{{join(value.X.Scale, value.X.Offset)}}, \{{join(value.Y.Scale, value.Y.Offset)}}`
	elseif kind == "EnumItem" then
		return value.Name
	elseif kind == "Instance" then
		return value.Name
	elseif kind == "NumberRange" then
		return join(value.Min, value.Max)
	elseif kind == "Rect" then
		return join(value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
	elseif kind == "NumberSequence" then
		local points = {}
		for _, point in value.Keypoints do
			table.insert(points, `{num(point.Time)}: {num(point.Value)}`)
		end
		return table.concat(points, "  ")
	elseif kind == "ColorSequence" then
		local points = {}
		for _, point in value.Keypoints do
			table.insert(points, `{num(point.Time)}: #{point.Value:ToHex()}`)
		end
		return table.concat(points, "  ")
	elseif kind == "Font" then
		local family = string.match(value.Family, "([^/]+)%.json$") or value.Family
		return `{family}, {value.Weight.Name}, {value.Style.Name}`
	elseif kind == "PhysicalProperties" then
		return join(
			value.Density,
			value.Friction,
			value.Elasticity,
			value.FrictionWeight,
			value.ElasticityWeight
		)
	elseif kind == "Ray" then
		return `{join(value.Origin.X, value.Origin.Y, value.Origin.Z)} → {join(value.Direction.X, value.Direction.Y, value.Direction.Z)}`
	elseif kind == "Faces" or kind == "Axes" then
		local names = {}
		for _, name in { "Top", "Bottom", "Left", "Right", "Back", "Front", "X", "Y", "Z" } do
			local ok, on = pcall(function()
				return value[name]
			end)
			if ok and on then
				table.insert(names, name)
			end
		end
		return table.concat(names, ", ")
	elseif kind == "Content" then
		local ok, uri = pcall(function()
			return value.Uri
		end)
		return if ok and uri then uri else tostring(value)
	end
	return tostring(value)
end

local function numbers(text: string): { number }
	local list = {}
	for token in string.gmatch(text, "[^,%s{}()]+") do
		local n = tonumber(token)
		if n == nil then
			local lowered = string.lower(token)
			n = if lowered == "inf" or lowered == "math.huge" then math.huge
				elseif lowered == "-inf" or lowered == "-math.huge" then -math.huge
				else nil
		end
		if n == nil then
			return {}
		end
		table.insert(list, n)
	end
	return list
end
Values.numbers = numbers

-- Types the panel edits as text.
Values.TEXT_TYPES = table.freeze({
	string = true,
	number = true,
	Vector3 = true,
	Vector2 = true,
	Vector3int16 = true,
	Vector2int16 = true,
	CFrame = true,
	Color3 = true,
	BrickColor = true,
	UDim = true,
	UDim2 = true,
	NumberRange = true,
	Rect = true,
	Content = true,
})

-- Text typed for a property back into a value of the current value's type. Returns ok, value.
function Values.parse(text: string, current): (boolean, any)
	local kind = typeof(current)
	local n = numbers(text)
	if kind == "string" then
		return true, text
	elseif kind == "number" then
		return #n == 1, n[1]
	elseif kind == "Vector3" and #n == 3 then
		return true, Vector3.new(n[1], n[2], n[3])
	elseif kind == "Vector3int16" and #n == 3 then
		return true, Vector3int16.new(n[1], n[2], n[3])
	elseif kind == "Vector2" and #n == 2 then
		return true, Vector2.new(n[1], n[2])
	elseif kind == "Vector2int16" and #n == 2 then
		return true, Vector2int16.new(n[1], n[2])
	elseif kind == "CFrame" then
		if #n == 3 then
			return true, current.Rotation + Vector3.new(n[1], n[2], n[3])
		elseif #n == 6 then
			-- Position, then orientation in degrees, the way the Orientation property reads.
			return
				true,
				CFrame.new(n[1], n[2], n[3])
					* CFrame.fromOrientation(math.rad(n[4]), math.rad(n[5]), math.rad(n[6]))
		elseif #n == 12 then
			return true, CFrame.new(table.unpack(n))
		end
	elseif kind == "Color3" then
		local hex = string.match(text, "^%s*#?(%x%x%x%x%x%x)%s*$")
		if hex then
			return true, Color3.fromHex(hex)
		elseif #n == 3 then
			local scale = if n[1] <= 1 and n[2] <= 1 and n[3] <= 1 and string.find(text, "%.") then 1
				else 255
			return true, Color3.new(n[1] / scale, n[2] / scale, n[3] / scale)
		end
	elseif kind == "BrickColor" then
		local ok, color = pcall(BrickColor.new, tonumber(text) or text)
		return ok, color
	elseif kind == "UDim" and #n == 2 then
		return true, UDim.new(n[1], n[2])
	elseif kind == "UDim2" and #n == 4 then
		return true, UDim2.new(n[1], n[2], n[3], n[4])
	elseif kind == "NumberRange" and (#n == 1 or #n == 2) then
		return true, NumberRange.new(n[1], n[2] or n[1])
	elseif kind == "Rect" and #n == 4 then
		return true, Rect.new(n[1], n[2], n[3], n[4])
	elseif kind == "Content" then
		local ok, content = pcall(function()
			return Content.fromUri(text)
		end)
		return ok, content
	end
	return false, nil
end

-- Compound types the panel opens into one number row per component, in this order.
local COMPONENTS = {
	Vector3 = { "X", "Y", "Z" },
	Vector3int16 = { "X", "Y", "Z" },
	Vector2 = { "X", "Y" },
	Vector2int16 = { "X", "Y" },
	CFrame = {
		"Position X",
		"Position Y",
		"Position Z",
		"Orientation X",
		"Orientation Y",
		"Orientation Z",
	},
	UDim2 = { "X Scale", "X Offset", "Y Scale", "Y Offset" },
	UDim = { "Scale", "Offset" },
}
local BUILD = {
	Vector3 = Vector3.new,
	Vector3int16 = Vector3int16.new,
	Vector2 = Vector2.new,
	Vector2int16 = Vector2int16.new,
	UDim2 = UDim2.new,
	UDim = UDim.new,
}

local function parts(value): { number }
	local kind = typeof(value)
	if kind == "CFrame" then
		local x, y, z = value:ToOrientation()
		return { value.X, value.Y, value.Z, math.deg(x), math.deg(y), math.deg(z) }
	elseif kind == "UDim2" then
		return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
	elseif kind == "UDim" then
		return { value.Scale, value.Offset }
	elseif #COMPONENTS[kind] == 3 then
		return { value.X, value.Y, value.Z }
	end
	return { value.X, value.Y }
end

-- The components of a compound value as { Name, Value } in order, or nil for other types.
function Values.components(value): { { Name: string, Value: number } }?
	local names = COMPONENTS[typeof(value)]
	if names == nil then
		return nil
	end
	local list = {}
	for index, n in parts(value) do
		table.insert(list, { Name = names[index], Value = n })
	end
	return list
end

-- The value with one named component replaced, or nil if it has no such component.
function Values.withComponent(value, name: string, n: number): any
	local kind = typeof(value)
	local index = COMPONENTS[kind] and table.find(COMPONENTS[kind], name)
	if index == nil then
		return nil
	end
	local p = parts(value)
	p[index] = n
	if kind ~= "CFrame" then
		return BUILD[kind](table.unpack(p))
	elseif index <= 3 then
		-- Keep the exact rotation instead of rebuilding it from degrees.
		return value.Rotation + Vector3.new(p[1], p[2], p[3])
	end
	return CFrame.new(p[1], p[2], p[3])
		* CFrame.fromOrientation(math.rad(p[4]), math.rad(p[5]), math.rad(p[6]))
end

-- Luau that rebuilds a value, for "Copy value".
function Values.code(value): string
	local kind = typeof(value)
	if kind == "string" then
		return string.format("%q", value)
	elseif kind == "Vector3"
		or kind == "Vector2"
		or kind == "UDim"
		or kind == "NumberRange"
		or kind == "Vector3int16"
		or kind == "Vector2int16" then
		return `{kind}.new({Values.format(value)})`
	elseif kind == "UDim2" then
		return `UDim2.new({join(value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)})`
	elseif kind == "CFrame" then
		return `CFrame.new({Values.format(value)})`
	elseif kind == "Color3" then
		return `Color3.fromRGB({Values.format(value)})`
	elseif kind == "BrickColor" then
		return `BrickColor.new("{value.Name}")`
	elseif kind == "EnumItem" then
		return tostring(value)
	elseif kind == "Rect" then
		return `Rect.new({Values.format(value)})`
	end
	return Values.format(value)
end

return table.freeze(Values)
