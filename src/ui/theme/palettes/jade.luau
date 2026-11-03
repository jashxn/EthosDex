local utils = require(script.Parent.utils)
local rgb = utils.rgb

-- Jade: green-grey surfaces with a jade accent.
return {
	name = "jade",
	BgBaseColor = rgb(13, 20, 18),
	AccentPrimary = rgb(38, 170, 130),
	AccentSecondary = rgb(70, 170, 200),
	AccentCaution = rgb(230, 165, 60),
	AccentDestructive = rgb(229, 72, 77),
}
