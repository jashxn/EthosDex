local utils = require(script.Parent.utils)
local rgb = utils.rgb

-- Gold: olive-sand surfaces with an amber accent. Warnings turn orange to stay apart from it.
return {
	name = "gold",
	BgBaseColor = rgb(20, 19, 14),
	AccentPrimary = rgb(240, 180, 40),
	AccentSecondary = rgb(190, 140, 80),
	AccentCaution = rgb(240, 130, 60),
	AccentDestructive = rgb(229, 72, 77),
}
