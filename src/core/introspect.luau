--!nocheck
--[[
	What the Inspect tab reads and does: arguments typed as text, a signal's connections, a
	script's constants and upvalues, calling remotes, and blocking a remote from firing.
	Everything checks for the executor function it needs first.
]]

local Env = require(script.Parent.env)

local raw = Env.raw

local Introspect = {}

-- A value as one line of text.
function Introspect.describe(value): string
	local kind = typeof(value)
	if kind == "string" then
		return value
	elseif kind == "Instance" then
		local ok, name = pcall(value.GetFullName, value)
		return if ok then name else "Instance"
	elseif kind == "function" or kind == "table" or kind == "thread" or kind == "userdata" then
		return kind
	end
	return tostring(value)
end

-- Plain literals, so arguments work without loadstring.
function Introspect.literal(text: string): (boolean, any)
	if text == "nil" then
		return true, nil
	elseif text == "true" or text == "false" then
		return true, text == "true"
	end
	local number = tonumber(text)
	if number then
		return true, number
	end
	if not string.find(text, "\\", 1, true) then
		local quoted = string.match(text, '^"(.*)"$') or string.match(text, "^'(.*)'$")
		if quoted then
			return true, quoted
		end
	end
	return false
end

--[[
	One argument per line: a literal, or any Luau expression when the executor has loadstring.
	`names` are extra globals for expressions (me, char, hrp, sel). Returns args with `n` set
	(nil arguments count), or nil and the problem.
]]
function Introspect.parseArgs(text: string, names: { [string]: any }?)
	local args = { n = 0 }
	for line in string.gmatch(text .. "\n", "(.-)\r?\n") do
		line = string.match(line, "^%s*(.-)%s*$")
		if line == "" then
			continue
		end
		local index = args.n + 1
		local ok, value = Introspect.literal(line)
		if not ok then
			local fn, problem = Env.compile("return " .. line, "=argument")
			if fn == nil then
				return nil, `Line {index}: {problem}`
			end
			if names and setfenv then
				pcall(setfenv, fn, setmetatable(table.clone(names), { __index = getfenv(fn) }))
			end
			local ran, result = pcall(fn)
			if not ran then
				return nil, `Line {index}: {result}`
			end
			value = result
		end
		args[index] = value
		args.n = index
	end
	return args
end

-- Where a function was written: its script (when the environment says) and line.
function Introspect.origin(fn)
	if type(fn) ~= "function" then
		return nil, nil, nil
	end
	local _, source, line = pcall(debug.info, fn, "sl")
	local envOk, env = pcall(getfenv, fn)
	local script = envOk and type(env) == "table" and rawget(env, "script")
	return if typeof(script) == "Instance" then script else nil, source, line
end

-- The signal's connections: { Connection, Function, Script, Source, Line, Enabled }.
function Introspect.connections(signal)
	if raw.getconnections == nil then
		return {}
	end
	local ok, list = pcall(raw.getconnections, signal)
	if not ok or type(list) ~= "table" then
		return {}
	end
	local found = {}
	for _, connection in list do
		local _, fn = pcall(function()
			return connection.Function
		end)
		local _, enabled = pcall(function()
			return connection.Enabled
		end)
		local script, source, line = Introspect.origin(fn)
		table.insert(
			found,
			{
				Connection = connection,
				Function = if type(fn) == "function" then fn else nil,
				Script = script,
				Source = source,
				Line = line,
				Enabled = enabled ~= false,
			}
		)
	end
	return found
end

-- "Foo:12", or what's known.
function Introspect.where(entry): string
	local name = if entry.Script then entry.Script.Name
		elseif entry.Source and entry.Source ~= "" then string.match(entry.Source, "[^%.]+$")
		else nil
	if name == nil then
		return if entry.Function then "Unknown script" else "Engine or another VM"
	end
	return if entry.Line and entry.Line > 0 then `{name}:{entry.Line}` else name
end

local function belongs(fn, target, fullName: string): boolean
	local ok, env = pcall(getfenv, fn)
	if ok and type(env) == "table" and rawget(env, "script") == target then
		return true
	end
	local infoOk, source = pcall(debug.info, fn, "s")
	return infoOk and source == fullName
end

--[[
	The script's functions: its live closures from the garbage collector (these have upvalues),
	plus the main chunk and every nested prototype (constants only), so functions that never ran
	are searched too. Yields between batches.
]]
function Introspect.functionsOf(target)
	local found, seen = {}, {}
	local function add(fn, closure: boolean)
		if type(fn) == "function" and not seen[fn] then
			seen[fn] = true
			table.insert(found, { Function = fn, Closure = closure })
		end
	end
	if raw.getscriptclosure then
		local ok, main = pcall(raw.getscriptclosure, target)
		if ok then
			add(main, false)
		end
	end
	if raw.getgc then
		local fullName = target:GetFullName()
		local ok, objects = pcall(raw.getgc, false)
		if ok and type(objects) == "table" then
			for index, value in objects do
				if index % 20000 == 0 then
					task.wait()
				end
				if type(value) == "function"
					and (raw.islclosure == nil or raw.islclosure(value))
					and belongs(value, target, fullName) then
					add(value, true)
				end
			end
		end
	end
	if raw.getprotos then
		local index = 1
		while index <= #found and index <= 5000 do
			local ok, protos = pcall(raw.getprotos, found[index].Function)
			if ok and type(protos) == "table" then
				for _, proto in protos do
					add(proto, false)
				end
			end
			index += 1
		end
	end
	return found
end

--[[
	Constants and upvalues whose text contains `query` (any case; empty matches all).
	kinds: { Constants = bool, Upvalues = bool }. Returns results and whether it hit `limit`.
	A result: { Kind = "Const" | "Upval", Name, Line, Index, Value, Text }.
]]
function Introspect.search(functions, query: string, kinds, limit: number)
	local results, seen = {}, {}
	local needle = string.lower(query)
	local function consider(kind, entry, index, value): boolean
		local text = Introspect.describe(value)
		if needle ~= "" and not string.find(string.lower(text), needle, 1, true) then
			return false
		end
		local _, name, line = pcall(debug.info, entry.Function, "nl")
		-- A closure and its prototype share constants; list them once.
		local key = `{kind}\0{name}\0{line}\0{index}\0{text}`
		if seen[key] then
			return false
		end
		seen[key] = true
		table.insert(
			results,
			{
				Kind = kind,
				Name = if type(name) == "string" and name ~= "" then name else "anonymous",
				Line = line,
				Index = index,
				Value = value,
				Text = text,
			}
		)
		return #results >= limit
	end
	for _, entry in functions do
		if kinds.Constants and raw.getconstants then
			local ok, constants = pcall(raw.getconstants, entry.Function)
			if ok and type(constants) == "table" then
				for index, value in constants do
					if consider("Const", entry, index, value) then
						return results, true
					end
				end
			end
		end
		if kinds.Upvalues and entry.Closure and raw.getupvalues then
			local ok, upvalues = pcall(raw.getupvalues, entry.Function)
			if ok and type(upvalues) == "table" then
				for index, value in upvalues do
					if consider("Upval", entry, index, value) then
						return results, true
					end
				end
			end
		end
	end
	return results, false
end

-- Remotes and bindables: the method that sends.
function Introspect.sendMethod(object): string?
	if object:IsA("RemoteFunction") then
		return "InvokeServer"
	elseif object:IsA("BaseRemoteEvent") then
		return "FireServer"
	elseif object:IsA("BindableFunction") then
		return "Invoke"
	elseif object:IsA("BindableEvent") then
		return "Fire"
	end
	return nil
end

-- Sends `args` and returns what came back, as text.
function Introspect.call(object, args): (boolean, string)
	local method = Introspect.sendMethod(object)
	if method == nil then
		return false, "Not a remote or bindable."
	end
	local results = table.pack(pcall(object[method], object, table.unpack(args, 1, args.n)))
	if not results[1] then
		return false, tostring(results[2])
	end
	if results.n == 1 then
		return
			true,
			if method == "FireServer" or method == "Fire" then "Sent" else "Returned nothing"
	end
	local parts = {}
	for index = 2, results.n do
		table.insert(parts, Introspect.describe(results[index]))
	end
	return true, table.concat(parts, ", ")
end

-- Blocking: remote -> calls blocked so far. One __namecall hook, installed the first time;
-- our own calls (checkcaller) always go through.
local blocked = setmetatable({}, { __mode = "k" })
local BLOCKS = { FireServer = true, InvokeServer = true, Fire = true, Invoke = true }
local hooked = false

local function hook(): boolean
	if hooked then
		return true
	end
	if raw.hookmetamethod == nil or raw.getnamecallmethod == nil then
		return false
	end
	local getMethod, isOurs = raw.getnamecallmethod, raw.checkcaller
	local original
	local function handler(self, ...)
		if blocked[self] ~= nil and BLOCKS[getMethod()] and not (isOurs and isOurs()) then
			blocked[self] += 1
			return nil
		end
		return original(self, ...)
	end
	local ok, previous = pcall(
		raw.hookmetamethod,
		game,
		"__namecall",
		if raw.newcclosure then raw.newcclosure(handler) else handler
	)
	if not ok then
		return false
	end
	original = previous
	hooked = true
	return true
end

function Introspect.canBlock(): boolean
	return raw.hookmetamethod ~= nil and raw.getnamecallmethod ~= nil
end

function Introspect.setBlocked(object, on: boolean): (boolean, string?)
	if not on then
		blocked[object] = nil
		return true
	end
	if not hook() then
		return false, "Needs hookmetamethod and getnamecallmethod."
	end
	blocked[object] = blocked[object] or 0
	return true
end

-- Calls blocked so far, or nil when it isn't blocked.
function Introspect.blockedCount(object): number?
	return blocked[object]
end

function Introspect.unblockAll()
	table.clear(blocked)
end

return Introspect
