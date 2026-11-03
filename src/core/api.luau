--!nocheck
--[[
	Roblox's own class reflection: the API dump (classes, inheritance, properties and their
	categories, tags and security) and ReflectionMetadata (Studio's explorer icon index and sort
	order). Both are downloaded once per client version and cached on disk when the executor can
	write files. Without HTTP the explorer still works; the properties panel falls back to the
	executor's getproperties or a short list, and icons fall back to a generic one.
]]

local Env = require(script.Parent.env)

local VERSION_URL = "https://clientsettings.roblox.com/v2/client-version/WindowsStudio64/channel/LIVE"
local DUMP_URLS = {
	"https://setup.rbxcdn.com/%s-API-Dump.json",
	"http://setup.roblox.com/%s-API-Dump.json",
}
local DUMP_MIRROR = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"
local RMD_URL = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/ReflectionMetadata.xml"
local CACHE = Env.ROOT .. "/cache"

local Api = {}

Api.Status = "idle" -- idle, loading, ready, failed
Api.Problem = nil
Api.Version = nil

local classes = {} -- name -> { Name, Superclass, Tags, Properties, Events, Functions, Icon, Order }
local propertyCache = {}
local listeners = {}

local function tagSet(tags)
	local set = {}
	if tags then
		for _, tag in tags do
			if type(tag) == "string" then
				set[tag] = true
			end
		end
	end
	return set
end

function Api.parseDump(dump)
	local parsed = {}
	for _, class in dump.Classes do
		local entry = {
			Name = class.Name,
			Superclass = if class.Superclass ~= "<<<ROOT>>>" then class.Superclass else nil,
			Tags = tagSet(class.Tags),
			Properties = {},
			Events = {},
			Functions = {},
		}
		for _, member in class.Members do
			local kind = member.MemberType
			if kind == "Property" then
				local security = member.Security or {}
				table.insert(
					entry.Properties,
					{
						Name = member.Name,
						Category = member.Category or "Other",
						ValueType = member.ValueType,
						Tags = tagSet(member.Tags),
						Read = if type(security) == "table" then security.Read else security,
						Write = if type(security) == "table" then security.Write else security,
						Class = class.Name,
					}
				)
			elseif kind == "Event" then
				table.insert(entry.Events, member.Name)
			elseif kind == "Function" then
				table.insert(entry.Functions, member.Name)
			end
		end
		parsed[class.Name] = entry
	end
	return parsed
end

-- ReflectionMetadata is XML; each class's own fields come before its nested member items, so
-- the text from one class item to the next item tag holds exactly that class's fields.
function Api.parseMetadata(xml: string)
	local meta = {}
	local marker = '<Item class="ReflectionMetadataClass">'
	local start = string.find(xml, marker, 1, true)
	while start do
		local after = start + #marker
		local nextItem = string.find(xml, "<Item ", after, true) or #xml
		local chunk = string.sub(xml, after, nextItem)
		local name = string.match(chunk, '<string name="Name">([^<]+)</string>')
		if name then
			meta[name] = {
				Icon = tonumber(
					string.match(chunk, '<string name="ExplorerImageIndex">(%d+)</string>')
				),
				Order = tonumber(
					string.match(chunk, '<string name="ExplorerOrder">(%-?%d+)</string>')
				),
			}
		end
		start = string.find(xml, marker, after, true)
	end
	return meta
end

local function cached(name: string): string?
	return Env.readFile(`{CACHE}/{name}`)
end

local function store(name: string, contents: string)
	if Env.canWrite() then
		Env.writeFile(`{CACHE}/{name}`, contents)
	end
end

local function fetchVersion(): string?
	local ok, body = Env.httpGet(VERSION_URL)
	if ok then
		local version = string.match(body, "(version%-%x+)")
		if version then
			return version
		end
	end
	return nil
end

local function fetchDump(version: string?): (string?, string?)
	if version then
		local hit = cached(`api-{version}.json`)
		if hit then
			return hit, nil
		end
		for _, pattern in DUMP_URLS do
			local ok, body = Env.httpGet(string.format(pattern, version))
			if ok and string.sub(body, 1, 1) == "{" then
				store(`api-{version}.json`, body)
				store("api-latest.txt", version)
				return body, nil
			end
		end
	end
	local ok, body = Env.httpGet(DUMP_MIRROR)
	if ok and string.sub(body, 1, 1) == "{" then
		return body, nil
	end
	-- Offline: the newest dump this executor has cached.
	local last = cached("api-latest.txt")
	local hit = last and cached(`api-{last}.json`)
	if hit then
		return hit, nil
	end
	return nil, "Couldn't download the Roblox API dump."
end

local function fetchMetadata(version: string?): string?
	local key = `rmd-{version or "latest"}.xml`
	local hit = cached(key)
	if hit then
		return hit
	end
	local ok, body = Env.httpGet(RMD_URL)
	if ok and string.find(body, "ReflectionMetadataClass", 1, true) then
		store(key, body)
		return body
	end
	return nil
end

function Api.onReady(callback)
	if Api.Status == "ready" or Api.Status == "failed" then
		task.spawn(callback)
	else
		table.insert(listeners, callback)
	end
end

local function finish(status: string, problem: string?)
	Api.Status = status
	Api.Problem = problem
	local waiting = listeners
	listeners = {}
	for _, callback in waiting do
		task.spawn(callback)
	end
end

-- Loads both sources. Yields. `progress(text)` hears each step.
function Api.load(progress: ((string) -> ())?)
	if Api.Status ~= "idle" then
		return
	end
	Api.Status = "loading"
	local say = progress
		or function()
		end
	say("Checking the Roblox version")
	local version = fetchVersion()
	Api.Version = version
	say("Loading the API dump")
	local body, problem = fetchDump(version)
	if body then
		local ok, result = pcall(Env.jsonDecode, body)
		if ok then
			classes = Api.parseDump(result)
		else
			body, problem = nil, "The API dump didn't parse: " .. tostring(result)
		end
	end
	say("Loading class icons")
	local xml = fetchMetadata(version)
	if xml then
		for name, meta in Api.parseMetadata(xml) do
			local class = classes[name]
			if class == nil then
				class = { Name = name, Tags = {}, Properties = {}, Events = {}, Functions = {} }
				classes[name] = class
			end
			class.Icon, class.Order = meta.Icon, meta.Order
		end
	end
	table.clear(propertyCache)
	finish(if body then "ready" else "failed", problem)
end

function Api.class(name: string)
	return classes[name]
end

function Api.hasDump(): boolean
	return next(classes) ~= nil and classes.Instance ~= nil
end

-- The class and its ancestors, nearest first.
function Api.lineage(name: string): { string }
	local chain = {}
	local current = classes[name]
	local guard = 0
	while current and guard < 64 do
		table.insert(chain, current.Name)
		current = current.Superclass and classes[current.Superclass]
		guard += 1
	end
	return chain
end

-- Every property of a class including inherited ones, by name, ancestors' first.
function Api.properties(name: string)
	local hit = propertyCache[name]
	if hit then
		return hit
	end
	local list, seen = {}, {}
	local chain = Api.lineage(name)
	for index = #chain, 1, -1 do
		for _, property in classes[chain[index]].Properties do
			if not seen[property.Name] then
				seen[property.Name] = true
				table.insert(list, property)
			end
		end
	end
	propertyCache[name] = list
	return list
end

function Api.members(name: string, kind: "Events" | "Functions"): { string }
	local list = {}
	for _, className in Api.lineage(name) do
		for _, member in classes[className][kind] do
			table.insert(list, member)
		end
	end
	table.sort(list)
	return list
end

-- Studio's explorer image index, inherited from the nearest ancestor that has one.
function Api.icon(name: string): number?
	local current = classes[name]
	local guard = 0
	while current and guard < 64 do
		if current.Icon then
			return current.Icon
		end
		current = current.Superclass and classes[current.Superclass]
		guard += 1
	end
	return nil
end

function Api.order(name: string): number
	local class = classes[name]
	return class and class.Order or 1000
end

-- Classes Instance.new can make, for Insert Object.
function Api.creatable(): { string }
	local list = {}
	for name, class in classes do
		if class.Superclass ~= nil
			and not class.Tags.NotCreatable
			and not class.Tags.Service
			and not class.Tags.Deprecated
			and not class.Tags.NotBrowsable then
			table.insert(list, name)
		end
	end
	table.sort(list)
	return list
end

return Api
