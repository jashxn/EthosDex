local utils = require(script.Parent.utils)
local hex = utils.hex

-- Sandstone: Light sand with a terracotta accent.
return {
	name = "sandstone",
	title = "Sandstone",
	BgBaseColor = hex("#f3ece2"),
	AccentPrimary = hex("#b5532f"),
	AccentSecondary = hex("#5a7a3a"),
	AccentCaution = hex("#8f5d00"),
	AccentDestructive = hex("#b3261e"),
	Overrides = {
		BgSunken = hex("#f3ece2"),
		FgPrimary = hex("#2b231c"),
		FgSecondary = hex("#4a3f35"),
		FgTertiary = hex("#665a4e"),
		FgQuaternary = hex("#7c7064"),
		FgQuinary = hex("#8c8073"),
		Success = hex("#3d7034"),
	},
}
