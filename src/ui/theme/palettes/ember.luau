local utils = require(script.Parent.utils)
local rgb = utils.rgb

-- Ember: warm brown-black surfaces with an orange accent. Errors lean crimson to stay apart from it.
return {
	name = "ember",
	BgBaseColor = rgb(22, 17, 14),
	AccentPrimary = rgb(240, 110, 40),
	AccentSecondary = rgb(230, 175, 60),
	AccentCaution = rgb(230, 175, 60),
	AccentDestructive = rgb(225, 65, 90),
}
