--!strict
local HttpService = game:GetService("HttpService")
local Data = require(script.Parent.ethosIconsFont)

local FOLDER = "Ethos Suite/fonts"
local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local VALUES = {}
for index = 1, #ALPHABET do
	VALUES[string.byte(ALPHABET, index)] = index - 1
end

local EthosIcons = {}
EthosIcons.Path = `{FOLDER}/ethos-icons-{Data.Version}`

local face: Font? = nil
local failure: string? = nil

function EthosIcons.decode(text: string): string
	local padding = if string.sub(text, -2) == "==" then 2
		elseif string.sub(text, -1) == "=" then 1
		else 0
	local length = #text // 4 * 3 - padding
	local output = buffer.create(length)
	local offset = 0
	for index = 1, #text, 4 do
		local a, b, c, d = string.byte(text, index, index + 3)
		local value = VALUES[a] * 262144
			+ VALUES[b] * 4096
			+ (VALUES[c] or 0) * 64
			+ (VALUES[d] or 0)
		for shift = 16, 0, -8 do
			if offset < length then
				buffer.writeu8(output, offset, bit32.extract(value, shift, 8))
				offset += 1
			end
		end
	end
	return buffer.tostring(output)
end

local function load(): (Font?, string?)
	if face or failure then
		return face, failure
	end
	local ok, result = pcall(function()
		assert(
			typeof(isfile) == "function"
				and typeof(isfolder) == "function"
				and typeof(makefolder) == "function"
				and typeof(writefile) == "function"
				and typeof(getcustomasset) == "function",
			"Custom assets are unavailable"
		)
		local current = ""
		for _, part in string.split(FOLDER, "/") do
			current = if current == "" then part else `{current}/{part}`
			if not isfolder(current) then
				makefolder(current)
			end
		end
		local ttf = EthosIcons.Path .. ".ttf"
		if not isfile(ttf) then
			writefile(ttf, EthosIcons.decode(Data.Font))
		end
		writefile(
			EthosIcons.Path .. ".json",
			HttpService:JSONEncode({
				name = "Ethos Icons",
				loadStrategy = "sameFamilyOnly",
				faces = {
					{
						name = "Regular",
						weight = 400,
						style = "normal",
						assetId = getcustomasset(ttf),
					},
				},
			})
		)
		return Font.new(getcustomasset(EthosIcons.Path .. ".json"))
	end)
	if ok then
		face = result
	else
		failure = tostring(result)
	end
	return face, failure
end

function EthosIcons.Has(name: string): boolean
	return Data.Icons[name] ~= nil
end

function EthosIcons.Fallback(name: string): string?
	return Data.Icons[name]
end

function EthosIcons.GetFontAsset(name: string)
	if Data.Icons[name] == nil then
		return nil, "Unknown icon."
	end
	local font, message = load()
	if font == nil then
		return nil, message
	end
	return { FontFace = font, Text = name }, nil
end

return table.freeze(EthosIcons)
