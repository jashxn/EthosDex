local utils = require(script.Parent.utils)
local hex = utils.hex

-- Sakura: Rose-grey with a cherry-blossom accent.
return {
	name = "sakura",
	title = "Sakura",
	BgBaseColor = hex("#1a1519"),
	AccentPrimary = hex("#f49ac1"),
	AccentSecondary = hex("#c3a2f0"),
	AccentCaution = hex("#efb85a"),
	AccentDestructive = hex("#ff6b6b"),
	Overrides = {
		FgPrimary = hex("#fbf2f6"),
		FgSecondary = hex("#dcc9d2"),
		FgTertiary = hex("#ab95a0"),
		FgQuaternary = hex("#8c7782"),
		FgQuinary = hex("#7b6772"),
		Success = hex("#6fd29a"),
	},
}
