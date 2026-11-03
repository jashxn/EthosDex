local utils = require(script.Parent.utils)
local hex = utils.hex

-- Horizon: Warm dark with a rose accent.
return {
	name = "horizon",
	title = "Horizon",
	BgBaseColor = hex("#1c1e26"),
	AccentPrimary = hex("#e95678"),
	AccentSecondary = hex("#fab795"),
	AccentCaution = hex("#fac29a"),
	AccentDestructive = hex("#f6661e"),
	Overrides = {
		BgSunken = hex("#1c1e26"),
		FgPrimary = hex("#e0e0e0"),
		FgSecondary = hex("#cbced0"),
		FgTertiary = hex("#9ea2a8"),
		FgQuaternary = hex("#878b92"),
		FgQuinary = hex("#777b82"),
		Success = hex("#29d398"),
	},
}
