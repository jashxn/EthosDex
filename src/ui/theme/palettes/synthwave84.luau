local utils = require(script.Parent.utils)
local hex = utils.hex

-- Synthwave '84: The Synthwave '84 neon palette.
return {
	name = "synthwave '84",
	title = "Synthwave '84",
	BgBaseColor = hex("#262335"),
	AccentPrimary = hex("#ff7edb"),
	AccentSecondary = hex("#36f9f6"),
	AccentCaution = hex("#fede5d"),
	AccentDestructive = hex("#fe5562"),
	Overrides = {
		BgSunken = hex("#262335"),
		FgPrimary = hex("#f0eff1"),
		FgSecondary = hex("#d7d2e4"),
		FgTertiary = hex("#ab9fc4"),
		FgQuaternary = hex("#9488ad"),
		FgQuinary = hex("#83789c"),
		Success = hex("#72f1b8"),
	},
}
