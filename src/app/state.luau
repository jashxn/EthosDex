--!nocheck
-- What the panels share: the selection, the open tab, and the device's layout.

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Internal = require(Root.packages.internal)
local Env = require(Root.core.env)
local Settings = require(Root.core.settings)

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
State.InspectTarget = scope:Value(nil)
-- Phones: the dock takes the screen's width and the window fills the screen.
State.Compact = scope:Value(false)
State.Touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
-- Tap adds to the selection instead of replacing it (touch has no Ctrl).
State.MultiSelect = scope:Value(false)

-- What's going on that the activity card shows: the instance the camera follows, and pick mode.
State.Viewing = scope:Value(nil)
State.Picking = scope:Value(false)
-- Picking a property's new value in the explorer: { Text, Pick = fn(instance) }, or nil.
State.PickFor = scope:Value(nil)
-- The instance under the pointer in the explorer, for the hover glow.
State.Hovered = scope:Value(nil)

-- Explorer row height for the density setting; touch rows are taller.
local DENSITY = { Compact = 20, Default = 24, Comfortable = 30 }
function State.rowHeight(): number
	return (DENSITY[Settings.get("Density")] or 24) + (if State.Touch then 8 else 0)
end

-- The UI scale; screen pixels divide by it to get layer offsets.
function State.scale(): number
	return math.clamp(Settings.get("UIScale"), 0.5, 2)
end

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
