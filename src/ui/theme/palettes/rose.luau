local utils = require(script.Parent.utils)
local rgb = utils.rgb

-- Rose: plum-black surfaces with a deep rose accent. Errors lean orange-red to stay apart from it.
return {
	name = "rose",
	BgBaseColor = rgb(22, 15, 19),
	AccentPrimary = rgb(200, 45, 105),
	AccentSecondary = rgb(170, 90, 220),
	AccentCaution = rgb(230, 165, 60),
	AccentDestructive = rgb(232, 80, 60),
}
