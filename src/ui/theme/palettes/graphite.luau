local utils = require(script.Parent.utils)
local rgb = utils.rgb

-- Graphite: neutral near-black with a white accent, for an all-monochrome window.
return {
	name = "graphite",
	BgBaseColor = rgb(14, 14, 14),
	AccentPrimary = rgb(230, 230, 230),
	AccentSecondary = rgb(150, 150, 156),
	AccentCaution = rgb(230, 165, 60),
	AccentDestructive = rgb(229, 72, 77),
}
