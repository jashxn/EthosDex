local function hex(hexString)
	hexString = hexString:gsub("#", "")
	local r = tonumber(hexString:sub(1, 2), 16) or 0
	local g = tonumber(hexString:sub(3, 4), 16) or 0
	local b = tonumber(hexString:sub(5, 6), 16) or 0
	return Color3.fromRGB(r, g, b)
end

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

return {
	hex = hex,
	rgb = rgb,
}
