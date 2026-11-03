local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Motion = require(Root.ui.motion)
local Surface = require(script.surface)
local Buttons = require(script.buttons)
local Switch = require(script.switch)
local Rows = require(script.rows)
local Inputs = require(script.inputs)
local Notices = require(script.notices)

local peek = Fusion.peek

local function read(value)
	return if type(value) == "table" and value.kind ~= nil then peek(value) else value
end

-- The families' own functions, not wrappers (Field returns two values), listed by name so
-- callers keep their types.
return table.freeze({
	Interaction = Surface.Interaction,
	Edge = Surface.Edge,
	Fill = Surface.Fill,
	FillAlpha = Surface.FillAlpha,
	Icon = Surface.Icon,
	texture = Surface.texture,
	apply = Surface.apply,
	Label = Surface.Label,
	Section = Surface.Section,
	merge = Surface.merge,
	Button = Buttons.Button,
	IconButton = Buttons.IconButton,
	Badge = Buttons.Badge,
	Switch = Switch.Switch,
	SwitchCard = Switch.SwitchCard,
	Row = Rows.Row,
	Group = Rows.Group,
	List = Rows.List,
	Field = Inputs.Field,
	KeyButton = Inputs.KeyButton,
	keyLabel = Inputs.keyLabel,
	ageLabel = Inputs.ageLabel,
	KeyRow = Inputs.KeyRow,
	Banner = Notices.Banner,
	Empty = Notices.Empty,
	read = read,
	snap = Motion.Snap,
	soft = Motion.Soft,
	animate = Motion.Animate,
	peek = peek,
})
