--!nocheck

local AssetCache = require(script.Parent.assetCache)
local Manifest = require(script.Parent.Parent.assets.runtimeManifest)
local RuntimeAssets = {}
local cache: any = nil

local function getCache()
	if cache == nil then
		cache = AssetCache.new({
			isfile = isfile,
			readfile = readfile,
			writefile = writefile,
			isfolder = isfolder,
			makefolder = makefolder,
			getcustomasset = getcustomasset,
			request = request or http_request or (syn and syn.request),
			httpGet = function(url)
				LPH_ATTRIBUTES(VM(NONE), PRESET(FAST), ERROR_HANDLING(false))
				return game:HttpGet(url)
			end,
			jsonEncode = function(value)
				return game:GetService("HttpService"):JSONEncode(value)
			end,
		})
	end
	return cache
end

function RuntimeAssets.isSupported()
	return getCache():IsSupported()
end

function RuntimeAssets.fetch(options)
	return getCache():Fetch(options)
end

function RuntimeAssets.createFont(options)
	return getCache():CreateFont(options)
end

function RuntimeAssets.resolve(image)
	if type(image) ~= "string" then
		return image
	end
	local id = string.match(image, "^rbxassetid://(%d+)$")
	local asset = id and Manifest.Assets[id]
	if asset == nil then
		return image
	end
	local handle = RuntimeAssets.fetch({
		Name = id,
		Url = Manifest.BaseUrl .. asset.File,
		Version = Manifest.Version,
		Kind = "image",
	})
	return handle or image
end

function RuntimeAssets.getVersion()
	return Manifest.Version
end

function RuntimeAssets.getStats()
	return getCache():GetStats()
end

return table.freeze(RuntimeAssets)
