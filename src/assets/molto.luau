--!strict
-- Molto icon registry adapter: https://github.com/notpoiu/Molto
-- The live loader is required because it must match the live provider data and fonts.

local LOADER_URL = "https://molto.pages.dev/source.lua"

local Molto = {}

local registry: any = nil
local retryAt = 0
local lastError: string? = nil

local function load(): (any, string?)
	if registry then
		return registry, nil
	end
	if os.clock() < retryAt then
		return nil, lastError
	end
	local ok, result = pcall(
		function()
			local loaded = (loadstring :: any)(game:HttpGet(LOADER_URL))()
			loaded.GetIcons() -- Loads the default Lucide provider data.
			return loaded
		end
	)
	if not ok then
		lastError = "Molto could not load: " .. tostring(result)
		retryAt = os.clock() + 3
		return nil, lastError
	end
	registry = result
	return registry, nil
end

-- Names cannot be checked while Molto is unreachable; GetFontAsset reports that failure.
function Molto.IsIcon(name: string): boolean
	local loaded = load()
	return loaded == nil or loaded.HasIcon(name)
end

function Molto.GetFontAsset(name: string)
	local loaded, message = load()
	if loaded == nil then
		return nil, message
	end
	local asset = loaded.GetAsset(name)
	if asset == nil then
		return nil, "Unknown icon."
	end
	if asset.FontFace == nil then
		return nil, "Icon font could not be loaded."
	end
	return asset, nil
end

return table.freeze(Molto)
