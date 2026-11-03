--!nocheck
--[[
	The executor surface. Every executor ships a different subset of the custom functions, under
	different names, so each one is looked up by every name it is known by and given a fallback.
	Nothing outside this module touches an executor global, so a missing function only ever
	disables the feature that needs it.

	Test hook: `getgenv().EthosDexDisable = { "decompile", "gethui", ... }` before loading makes
	those names look missing, to check the fallbacks on a fully featured executor.
]]

local HttpService = game:GetService("HttpService")

local genv = if typeof(getgenv) == "function" then getgenv() else getfenv(0)
local chunkEnv = getfenv(0)

local disabled = {}
if type(genv.EthosDexDisable) == "table" then
	for _, name in genv.EthosDexDisable do
		disabled[name] = true
	end
end

local function lookup(path: string)
	if disabled[path] then
		return nil
	end
	local ok, value = pcall(function()
		local current = nil
		for part in string.gmatch(path, "[^%.]+") do
			if current == nil then
				current = genv[part]
				if current == nil then
					current = chunkEnv[part]
				end
			else
				current = if type(current) == "table" then current[part] else nil
			end
			if current == nil then
				return nil
			end
		end
		return current
	end)
	return if ok then value else nil
end

-- The first of the names that resolves to a function.
local function pick(...): any
	for index = 1, select("#", ...) do
		local value = lookup((select(index, ...)))
		if type(value) == "function" then
			return value
		end
	end
	return nil
end

local Env = {}

local cloneref = pick("cloneref", "clonereference")
Env.cloneref = function(instance)
	if cloneref == nil or typeof(instance) ~= "Instance" then
		return instance
	end
	local ok, clone = pcall(cloneref, instance)
	return if ok and clone ~= nil then clone else instance
end

local services = {}
function Env.service(name: string): any
	local cached = services[name]
	if cached then
		return cached
	end
	local ok, service = pcall(game.GetService, game, name)
	if not ok or service == nil then
		ok, service = pcall(game.FindService, game, name)
	end
	if ok and service then
		service = Env.cloneref(service)
		services[name] = service
		return service
	end
	return nil
end

local identify = pick("identifyexecutor", "getexecutorname", "whatexecutor")
Env.executor = (function()
	if identify then
		local ok, name, version = pcall(identify)
		if ok and type(name) == "string" then
			return if type(version) == "string" then `{name} {version}` else name
		end
	end
	return "Unknown executor"
end)()

-- Raw functions, by what Dex++ and the UNC call them. nil means unsupported.
local raw = {
	gethui = pick("gethui", "get_hidden_gui"),
	protectGui = pick("protect_gui", "syn.protect_gui", "protectgui"),
	getcustomasset = pick("getcustomasset", "getsynasset"),
	decompile = pick("decompile"),
	getscriptbytecode = pick("getscriptbytecode", "dumpstring"),
	getscripthash = pick("getscripthash"),
	saveinstance = pick("saveinstance", "syn.saveinstance"),
	getnilinstances = pick("getnilinstances", "get_nil_instances"),
	getinstances = pick("getinstances", "get_instances"),
	getloadedmodules = pick("getloadedmodules", "get_loaded_modules"),
	getrunningscripts = pick("getrunningscripts", "get_running_scripts"),
	gethiddenproperty = pick("gethiddenproperty", "gethiddenprop"),
	sethiddenproperty = pick("sethiddenproperty", "sethiddenprop"),
	getproperties = pick("getproperties"),
	setclipboard = pick(
		"setclipboard",
		"toclipboard",
		"set_clipboard",
		"Clipboard.set",
		"writeclipboard",
		"setrbxclipboard"
	),
	readfile = pick("readfile"),
	writefile = pick("writefile"),
	appendfile = pick("appendfile"),
	isfile = pick("isfile"),
	isfolder = pick("isfolder"),
	makefolder = pick("makefolder"),
	listfiles = pick("listfiles"),
	delfile = pick("delfile"),
	request = pick("request", "http_request", "syn.request", "http.request", "fluxus.request"),
	loadstring = pick("loadstring"),
	base64encode = pick(
		"crypt.base64encode",
		"crypt.base64.encode",
		"base64_encode",
		"base64encode"
	),
	getsenv = pick("getsenv"),
	getconnections = pick("getconnections", "get_signal_cons"),
	firesignal = pick("firesignal"),
	fireclickdetector = pick("fireclickdetector"),
	fireproximityprompt = pick("fireproximityprompt"),
	firetouchinterest = pick("firetouchinterest"),
	getthreadidentity = pick("getthreadidentity", "getidentity", "get_thread_identity"),
	setthreadidentity = pick("setthreadidentity", "setidentity", "set_thread_identity"),
}
Env.raw = raw

function Env.has(name: string): boolean
	return raw[name] ~= nil
end

-- What each feature needs, for the settings page and for disabling actions.
Env.FEATURES = table.freeze({
	{ Name = "Hidden UI container", Needs = { "gethui", "protectGui" }, Any = true },
	{ Name = "Decompile scripts", Needs = { "decompile", "getscriptbytecode" }, Any = true },
	{ Name = "Script bytecode", Needs = { "getscriptbytecode" } },
	{ Name = "Save instance", Needs = { "saveinstance", "loadstring" }, Any = true },
	{ Name = "Nil instances", Needs = { "getnilinstances" } },
	{ Name = "Hidden properties", Needs = { "gethiddenproperty" } },
	{ Name = "Clipboard", Needs = { "setclipboard" } },
	{ Name = "Files and cache", Needs = { "writefile", "readfile", "isfile", "makefolder" } },
	{ Name = "Custom assets", Needs = { "getcustomasset" } },
	{ Name = "HTTP requests", Needs = { "request" } },
	{ Name = "Run code (console)", Needs = { "loadstring" } },
	{ Name = "Script environments", Needs = { "getsenv" } },
	{ Name = "Signal connections", Needs = { "getconnections" } },
	{ Name = "Fire click detectors", Needs = { "fireclickdetector" } },
	{ Name = "Fire proximity prompts", Needs = { "fireproximityprompt" } },
	{ Name = "Fire touch interests", Needs = { "firetouchinterest" } },
})

function Env.supports(feature): boolean
	for _, name in feature.Needs do
		local present = raw[name] ~= nil
		if feature.Any and present then
			return true
		elseif not feature.Any and not present then
			return false
		end
	end
	return not feature.Any
end

-- UI ----------------------------------------------------------------------------------------

-- Where the window lives: the executor's hidden container, then CoreGui, then PlayerGui.
function Env.guiParent(): Instance
	if raw.gethui then
		local ok, hui = pcall(raw.gethui)
		if ok and typeof(hui) == "Instance" then
			return hui
		end
	end
	local coreGui = Env.service("CoreGui")
	if coreGui
		and pcall(function()
			return coreGui:GetChildren()
		end) then
		local probe = Instance.new("Folder")
		if pcall(function()
			probe.Parent = coreGui
		end) then
			probe:Destroy()
			return coreGui
		end
		probe:Destroy()
	end
	local player = Env.service("Players").LocalPlayer
	return player:WaitForChild("PlayerGui")
end

function Env.protect(gui: Instance)
	if raw.protectGui then
		pcall(raw.protectGui, gui)
	end
end

function Env.clipboard(text: string): boolean
	if raw.setclipboard == nil then
		return false
	end
	return (pcall(raw.setclipboard, text))
end

-- Files ---------------------------------------------------------------------------------------

Env.ROOT = "EthosDex"

function Env.canWrite(): boolean
	return raw.writefile ~= nil
		and raw.readfile ~= nil
		and raw.isfile ~= nil
		and raw.makefolder ~= nil
end

function Env.ensureFolder(path: string): boolean
	if not Env.canWrite() then
		return false
	end
	local current = ""
	for part in string.gmatch(path, "[^/]+") do
		current = if current == "" then part else `{current}/{part}`
		local exists = raw.isfolder and select(2, pcall(raw.isfolder, current))
		if not exists then
			pcall(raw.makefolder, current)
		end
	end
	return true
end

function Env.readFile(path: string): string?
	if not Env.canWrite() then
		return nil
	end
	local ok, exists = pcall(raw.isfile, path)
	if not ok or not exists then
		return nil
	end
	local read, contents = pcall(raw.readfile, path)
	return if read and type(contents) == "string" then contents else nil
end

function Env.writeFile(path: string, contents: string): (boolean, string?)
	if not Env.canWrite() then
		return false, "This executor can't write files."
	end
	local folder = string.match(path, "^(.*)/[^/]*$")
	if folder then
		Env.ensureFolder(folder)
	end
	local ok, problem = pcall(raw.writefile, path, contents)
	return ok, if ok then nil else tostring(problem)
end

-- Strips characters Windows refuses in file names.
function Env.safeName(name: string): string
	local cleaned = string.gsub(tostring(name), '[%*\\%?:<>|"/]+', "_")
	return string.sub(cleaned, 1, 120)
end

function Env.customAsset(path: string): string?
	if raw.getcustomasset == nil then
		return nil
	end
	local ok, id = pcall(raw.getcustomasset, path)
	return if ok and type(id) == "string" and id ~= "" then id else nil
end

-- HTTP ----------------------------------------------------------------------------------------

function Env.httpGet(url: string): (boolean, string)
	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and type(body) == "string" then
		return true, body
	end
	if raw.request then
		local sent, response = pcall(raw.request, { Url = url, Method = "GET" })
		if sent
			and type(response) == "table"
			and (response.StatusCode == nil or response.StatusCode < 400) then
			return true, response.Body or ""
		end
		return
			false,
			if sent and type(response) == "table" then `HTTP {response.StatusCode}`
				else tostring(response)
	end
	return false, tostring(body)
end

function Env.request(options)
	if raw.request == nil then
		return nil, "This executor has no request function."
	end
	local ok, response = pcall(raw.request, options)
	if not ok then
		return nil, tostring(response)
	end
	return response, nil
end

function Env.jsonDecode(text: string)
	return HttpService:JSONDecode(text)
end

function Env.jsonEncode(value): string
	return HttpService:JSONEncode(value)
end

-- Code ----------------------------------------------------------------------------------------

function Env.compile(source: string, chunkName: string?)
	if raw.loadstring == nil then
		return nil, "This executor has no loadstring."
	end
	local ok, fn, problem = pcall(raw.loadstring, source, chunkName)
	if not ok then
		return nil, tostring(fn)
	end
	return fn, problem
end

-- Scripts the client can hold bytecode for: client and module scripts.
function Env.canDecompile(object: Instance): boolean
	if not (raw.decompile or raw.getscriptbytecode) then
		return false
	end
	if object:IsA("ModuleScript") then
		return true
	end
	if object:IsA("LocalScript") then
		return true
	end
	if object:IsA("Script") then
		local ok, context = pcall(function()
			return object.RunContext
		end)
		return ok and context == Enum.RunContext.Client
	end
	return false
end

function Env.bytecode(object: Instance): (string?, string?)
	if raw.getscriptbytecode == nil then
		return nil, "This executor can't read script bytecode."
	end
	local ok, bytecode = pcall(raw.getscriptbytecode, object)
	if not ok then
		return nil, tostring(bytecode)
	elseif type(bytecode) ~= "string" or bytecode == "" then
		return nil, "The script has no bytecode (it may run on the server)."
	end
	return bytecode, nil
end

local KONSTANT = "https://api.plusgiant5.com/konstant/decompile"
local lastKonstant = 0

-- Sends the bytecode to the Konstant web decompiler, at most twice a second as its API asks.
local function konstant(object: Instance): (string?, string?)
	local bytecode, problem = Env.bytecode(object)
	if bytecode == nil then
		return nil, problem
	end
	if raw.request == nil then
		return nil, "This executor has no request function for the web decompiler."
	end
	local wait = 0.5 - (os.clock() - lastKonstant)
	if wait > 0 then
		task.wait(wait)
	end
	lastKonstant = os.clock()
	local response, failure = Env.request({
		Url = KONSTANT,
		Method = "POST",
		Body = bytecode,
		Headers = { ["Content-Type"] = "text/plain" },
	})
	if response == nil then
		return nil, failure
	elseif response.StatusCode == 0 or response.StatusCode == nil then
		return nil, "Couldn't reach the Konstant web decompiler; it may be down."
	elseif response.StatusCode ~= 200 then
		return nil, `Konstant answered {response.StatusCode}: {response.Body}`
	end
	return response.Body, nil
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- The executor's base64 when it has one, else this one.
function Env.base64(data: string): string
	if raw.base64encode then
		local ok, out = pcall(raw.base64encode, data)
		if ok and type(out) == "string" then
			return out
		end
	end
	local out = table.create(math.ceil(#data / 3))
	for index = 1, #data, 3 do
		local a, b, c = string.byte(data, index, index + 2)
		local n = a * 65536 + (b or 0) * 256 + (c or 0)
		local function at(shift)
			local i = bit32.extract(n, shift, 6) + 1
			return string.sub(B64, i, i)
		end
		table.insert(
			out,
			at(18) .. at(12) .. (if b then at(6) else "=") .. (if c then at(0) else "=")
		)
	end
	return table.concat(out)
end

local LUA_EXPERT = "https://api.lua.expert/decompile"

-- The lua.expert web decompiler (what VEX Explorer uses): base64 bytecode in, source out.
local function luaExpert(object: Instance): (string?, string?)
	local bytecode, problem = Env.bytecode(object)
	if bytecode == nil then
		return nil, problem
	end
	if raw.request == nil then
		return nil, "This executor has no request function for the web decompiler."
	end
	local response, failure = Env.request({
		Url = LUA_EXPERT,
		Method = "POST",
		Body = Env.jsonEncode({ script = Env.base64(bytecode) }),
		Headers = { ["Content-Type"] = "application/json" },
	})
	if response == nil then
		return nil, failure
	elseif response.StatusCode == 0 or response.StatusCode == nil then
		return nil, "Couldn't reach lua.expert; it may be down."
	elseif response.StatusCode ~= 200 then
		return
			nil,
			`lua.expert answered {response.StatusCode}: {string.sub(tostring(response.Body), 1, 200)}`
	end
	return response.Body, nil
end

local function native(object: Instance): (string?, string?)
	if raw.decompile == nil then
		return nil, "This executor has no decompiler."
	end
	local ok, source = pcall(raw.decompile, object)
	if not ok then
		return nil, tostring(source)
	elseif type(source) ~= "string" or source == "" then
		return nil, "The decompiler returned nothing."
	end
	return source, nil
end

-- Advanced Decompiler V3 (the one Dex++ ships): decompiles the bytecode on this machine. Loaded
-- from GitHub the first time it's needed.
local ADVANCED = "https://raw.githubusercontent.com/AZYsGithub/Advanced-Decompiler-V3/refs/heads/main/init.lua"
local advancedFn = nil

local function advanced(object: Instance): (string?, string?)
	if raw.getscriptbytecode == nil then
		return nil, "This executor can't read script bytecode."
	end
	if advancedFn == nil then
		local ok, source = Env.httpGet(ADVANCED)
		if not ok then
			return nil, "Couldn't download Advanced Decompiler: " .. source
		end
		local chunk, problem = Env.compile(source, "=AdvancedDecompiler")
		if chunk == nil then
			return nil, problem
		end
		-- It looks for getscriptbytecode by that name; hand it whichever alias this executor has.
		pcall(
			setfenv,
			chunk,
			setmetatable({ getscriptbytecode = raw.getscriptbytecode }, { __index = genv })
		)
		local loaded, result = pcall(chunk)
		if not loaded or type(result) ~= "function" then
			return nil, "Advanced Decompiler didn't load: " .. tostring(result)
		end
		advancedFn = result
	end
	local ok, source = pcall(advancedFn, object, "optdec")
	if not ok then
		return nil, tostring(source)
	elseif type(source) ~= "string" or source == "" then
		return nil, "Advanced Decompiler returned nothing."
	elseif not string.find(source, "\n") and string.sub(source, 1, 2) == "--" then
		-- It reports failures (e.g. unsupported bytecode) as a lone comment instead of erroring.
		return nil, "Advanced Decompiler: " .. string.lower(string.gsub(source, "^%-%-%s*", ""))
	end
	return source, nil
end

Env.DECOMPILERS = table.freeze({ "Auto", "Executor", "Advanced", "lua.expert", "Konstant" })
local DECOMPILE = {
	Executor = native,
	Advanced = advanced,
	["lua.expert"] = luaExpert,
	Konstant = konstant,
}

-- `mode`: "Auto" tries the executor's decompiler, then Advanced Decompiler (local), then the two
-- web decompilers; the others use only that one.
function Env.decompile(object: Instance, mode: string?): (string?, string?)
	local only = DECOMPILE[mode or "Auto"]
	if only then
		return only(object)
	end
	local problems = {}
	for _, attempt in { native, advanced, luaExpert, konstant } do
		local source, problem = attempt(object)
		if source then
			return source, nil
		end
		table.insert(problems, problem)
	end
	return nil, table.concat(problems, " ")
end

local USSI = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/saveinstance.luau"
local ussi = nil

local function loadUssi()
	if ussi then
		return ussi, nil
	end
	local ok, source = Env.httpGet(USSI)
	if not ok then
		return nil, "Couldn't download SynSaveInstance: " .. source
	end
	local fn, problem = Env.compile(source, "saveinstance")
	if fn == nil then
		return nil, problem
	end
	local loaded, result = pcall(fn)
	if not loaded or type(result) ~= "function" then
		return nil, "SynSaveInstance didn't load: " .. tostring(result)
	end
	ussi = result
	return ussi, nil
end

-- Saves `options.Object` (or the place) through the executor's saveinstance, falling back to
-- SynSaveInstance, whose options every common saveinstance shares.
function Env.saveInstance(options): (boolean, string?)
	if raw.saveinstance then
		local ok, problem = pcall(raw.saveinstance, options)
		if ok then
			return true, nil
		end
		-- Older saveinstances take (instance, path, options).
		ok = pcall(raw.saveinstance, options.Object or game, options.FilePath, options)
		if ok then
			return true, nil
		end
		if raw.loadstring == nil then
			return false, tostring(problem)
		end
	end
	local save, problem = loadUssi()
	if save == nil then
		return false, problem
	end
	local ok, failure = pcall(save, options)
	return ok, if ok then nil else tostring(failure)
end

-- Instances ------------------------------------------------------------------------------------

function Env.nilInstances(): { Instance }?
	if raw.getnilinstances == nil then
		return nil
	end
	local ok, list = pcall(raw.getnilinstances)
	return if ok and type(list) == "table" then list else nil
end

-- Reads a property, then retries it as a hidden one. Returns ok, value.
function Env.getProperty(object: Instance, name: string): (boolean, any)
	local ok, value = pcall(function()
		return object[name]
	end)
	if ok then
		return true, value
	end
	if raw.gethiddenproperty then
		local hidden, result = pcall(raw.gethiddenproperty, object, name)
		if hidden then
			return true, result
		end
	end
	return false, value
end

function Env.setProperty(object: Instance, name: string, value: any): (boolean, string?)
	local ok, problem = pcall(function()
		object[name] = value
	end)
	if ok then
		return true, nil
	end
	if raw.sethiddenproperty then
		local hidden, result = pcall(raw.sethiddenproperty, object, name, value)
		if hidden then
			return true, nil
		end
		problem = result
	end
	return false, tostring(problem)
end

function Env.fire(kind: string, object: Instance): (boolean, string?)
	local fn = raw[kind]
	if fn == nil then
		return false, "This executor doesn't support that."
	end
	local ok, problem
	if kind == "firetouchinterest" then
		local player = Env.service("Players").LocalPlayer
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root == nil then
			return false, "Your character has no HumanoidRootPart."
		end
		ok, problem = pcall(function()
			fn(root, object, 0)
			task.wait()
			fn(root, object, 1)
		end)
	else
		ok, problem = pcall(fn, object)
	end
	return ok, if ok then nil else tostring(problem)
end

return table.freeze(Env)
