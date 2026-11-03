-- Colours and type shared by the dock panels, from the Ethos theme: its ink tiers on its sunken
-- surface, so the dock follows Library:SetTheme like the window does. The colours are theme
-- states; read them with `use` inside a Computed. Overlays are Ink at a transparency so they
-- read the same on the panel's gradient.

local Root = script.Parent.Parent
local EthosTheme = require(Root.ui.theme)

local FONT_ID = "rbxassetid://12187365364" -- Inter

return table.freeze({
	Ink = EthosTheme.FgPrimary,
	Ink2 = EthosTheme.FgSecondary,
	Muted = EthosTheme.FgTertiary,
	Faint = EthosTheme.FgQuinary,
	-- The panel and bar: the sunken surface, lifting to the second tier toward the bottom.
	Surface = EthosTheme.BgSunken,
	SurfaceLow = EthosTheme.BgSecondary,
	-- A switch's track while off, then the theme accent and its ink while on, as the window's
	-- checkboxes and sliders use it.
	Track = EthosTheme.BgQuaternary,
	Accent = EthosTheme.AccentPrimary,
	AccentInk = EthosTheme.AccentPrimaryFgPrimary,
	Success = EthosTheme.Success,
	Caution = EthosTheme.AccentCaution,
	Danger = EthosTheme.AccentDestructive,
	-- Tints that tell items of one kind apart, such as the parry builder's moves, in order.
	Hues = table.freeze({
		EthosTheme.AccentPrimary,
		EthosTheme.Violet,
		EthosTheme.Orange,
		EthosTheme.Green,
		EthosTheme.Cyan,
		EthosTheme.Pink,
	}),
	-- Ink overlay transparencies.
	Fill = 0.95, -- resting control
	FillHover = 0.92,
	FillPress = 0.9,
	Line = 0.93, -- hairlines and control edges
	Selected = 0.86, -- the selected segment
	Body = Font.new(FONT_ID, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	Title = Font.new(FONT_ID, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	Strong = Font.new(FONT_ID, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
})
