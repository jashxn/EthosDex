--!nocheck
-- What the panels share: the selection, the open tab, and the device's layout.

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Internal = require(Root.packages.internal)
local Env = require(Root.core.env)

local scope = Internal.Scope
local peek = Fusion.peek

local UserInputService = Env.service("UserInputService")

local State = {}

State.Game = game
State.LocalPlayer = Env.service("Players").LocalPlayer

-- Array of instances; always set a new table.
State.Selection = scope:Value({})
State.Tab = scope:Value("Properties")
State.ScriptTarget = scope:Value(nil)
State.PreviewTarget = scope:Value(nil)
-- Phones: one column, the explorer or the panel.
State.Compact = scope:Value(false)
State.MobileView = scope:Value("explorer")
State.Touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
-- Tap adds to the selection instead of replacing it (touch has no Ctrl).
State.MultiSelect = scope:Value(false)

State.ROW = if State.Touch then 32 else 24

function State.selection(): { Instance }
	return peek(State.Selection)
end

function State.first(): Instance?
	return peek(State.Selection)[1]
end

function State.select(list: { Instance })
	State.Selection:set(table.clone(list))
end

function State.isSelected(instance): boolean
	return table.find(peek(State.Selection), instance) ~= nil
end

-- Opens a panel tab; on phones, also flips to the panel.
function State.open(tab: string)
	State.Tab:set(tab)
	if peek(State.Compact) then
		State.MobileView:set("panel")
	end
end

-- Hooks the panels register so actions can reach them without importing them.
State.Hooks = {}

return State
