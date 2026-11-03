local utils = require(script.Parent.utils)
local rgb = utils.rgb

-- Midnight: deep navy surfaces with a sky-blue accent.
return {
	name = "midnight",
	BgBaseColor = rgb(11, 16, 28),
	AccentPrimary = rgb(78, 178, 250),
	AccentSecondary = rgb(110, 130, 240),
	AccentCaution = rgb(230, 165, 60),
	AccentDestructive = rgb(229, 72, 77),
}
