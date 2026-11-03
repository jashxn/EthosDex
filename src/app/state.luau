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
-- The floating window (Script, Console, Preview, Settings): its tab and whether it's open.
State.Tab = scope:Value("Script")
State.WindowOpen = scope:Value(false)
State.ScriptTarget = scope:Value(nil)
State.PreviewTarget = scope:Value(nil)
-- Phones: the dock takes the screen's width and the window fills the screen.
State.Compact = scope:Value(false)
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

-- Opens the floating window on a tab.
function State.open(tab: string)
	State.Tab:set(tab)
	State.WindowOpen:set(true)
end

-- Hooks the panels register so actions can reach them without importing them.
State.Hooks = {}

return State
