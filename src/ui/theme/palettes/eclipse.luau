local utils = require(script.Parent.utils)
local rgb = utils.rgb

-- Eclipse: cool slate with an indigo accent. The look window v2 was designed on.
return {
	name = "eclipse",
	BgBaseColor = rgb(18, 18, 22),
	AccentPrimary = rgb(70, 100, 210),
	AccentSecondary = rgb(55, 165, 185),
	AccentCaution = rgb(230, 165, 60),
	AccentDestructive = rgb(229, 72, 77),
}
