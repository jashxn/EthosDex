--!nocheck
-- Preferences, as Fusion values, saved to EthosDex/settings.json when the executor has files.

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Internal = require(Root.packages.internal)
local Env = require(script.Parent.env)

local scope = Internal.Scope
local peek = Fusion.peek

local FILE = Env.ROOT .. "/settings.json"

local DEFAULTS = {
	Theme = "eclipse",
	Decompiler = "Auto",
	ShowHidden = false,
	ShowDeprecated = false,
	ShowNil = true,
	ToggleKey = "RightControl",
	ExplorerWidth = 300,
	WindowWidth = 980,
	WindowHeight = 600,
	SaveDecompile = true,
}

local Settings = {}
local values = {}

local saved = {}
local text = Env.readFile(FILE)
if text then
	local ok, decoded = pcall(Env.jsonDecode, text)
	if ok and type(decoded) == "table" then
		saved = decoded
	end
end

for key, default in DEFAULTS do
	local value = saved[key]
	if typeof(value) ~= typeof(default) then
		value = default
	end
	values[key] = scope:Value(value)
end

local pending = false
local function save()
	if pending or not Env.canWrite() then
		return
	end
	pending = true
	task.delay(
		0.5,
		function()
			pending = false
			local out = {}
			for key, value in values do
				out[key] = peek(value)
			end
			Env.writeFile(FILE, Env.jsonEncode(out))
		end
	)
end

for _, value in values do
	scope:Observer(value):onChange(save)
end

function Settings.get(key: string)
	return peek(values[key])
end

function Settings.set(key: string, value)
	values[key]:set(value)
end

function Settings.state(key: string)
	return values[key]
end

Settings.DEFAULTS = table.freeze(DEFAULTS)

return table.freeze(Settings)
