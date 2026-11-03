--!nocheck
-- Ethos Dex. Running it again closes the previous window first.

-- The Ethos modules carry Luraph annotations; outside a Luraph build they do nothing.
if not LPH_OBFUSCATED then
	local env = getfenv()
	local function pass(...)
		return ...
	end
	env.LPH_ATTRIBUTES = env.LPH_ATTRIBUTES
		or function()
		end
	env.VM = env.VM or pass
	env.PRESET = env.PRESET or pass
	env.ERROR_HANDLING = env.ERROR_HANDLING or pass
	env.UNROLL = env.UNROLL or pass
	env.NONE = env.NONE
	env.FAST = env.FAST
end

local genv = if typeof(getgenv) == "function" then getgenv() else _G

local previous = genv.__ETHOS_DEX
if type(previous) == "table" and type(previous.Destroy) == "function" then
	pcall(previous.Destroy)
end

local App = require(script.app)
local Internal = require(script.packages.internal)
local Images = require(script.ui.images)

local app = App.start()

local handle = {}
function handle.Destroy()
	if genv.__ETHOS_DEX == handle then
		genv.__ETHOS_DEX = nil
	end
	app.Destroy()
	pcall(function()
		Images:cleanup()
	end)
	pcall(function()
		Internal.Scope:doCleanup()
	end)
end
handle.Gui = app.Gui
handle.State = app.State
handle.Tree = app.Tree
handle.Window = app.Window
handle.Dock = app.Dock
handle.Settings = require(script.core.settings)
handle.History = require(script.app.history)
handle.Version = "1.0.0"

genv.__ETHOS_DEX = handle
return handle
