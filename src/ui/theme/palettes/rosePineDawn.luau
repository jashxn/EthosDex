local utils = require(script.Parent.utils)
local hex = utils.hex

-- Rosé Pine Dawn: Rosé Pine's light variant.
return {
	name = "rosé pine dawn",
	title = "Rosé Pine Dawn",
	BgBaseColor = hex("#faf4ed"),
	AccentPrimary = hex("#907aa9"),
	AccentSecondary = hex("#d7827e"),
	AccentCaution = hex("#945c10"),
	AccentDestructive = hex("#a24e68"),
	Overrides = {
		BgSunken = hex("#faf4ed"),
		FgPrimary = hex("#575279"),
		FgSecondary = hex("#625d84"),
		FgTertiary = hex("#6e6a8e"),
		FgQuaternary = hex("#797593"),
		FgQuinary = hex("#8a86a0"),
		Success = hex("#286983"),
	},
}
