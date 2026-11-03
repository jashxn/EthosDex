local utils = require(script.Parent.utils)
local hex = utils.hex

-- Solarized Dark: Solarized on base03.
return {
	name = "solarized dark",
	title = "Solarized Dark",
	BgBaseColor = hex("#002b36"),
	AccentPrimary = hex("#268bd2"),
	AccentSecondary = hex("#2aa198"),
	AccentCaution = hex("#b58900"),
	AccentDestructive = hex("#f2625a"),
	Overrides = {
		BgSunken = hex("#002b36"),
		FgPrimary = hex("#eee8d5"),
		FgSecondary = hex("#93a1a1"),
		FgTertiary = hex("#839496"),
		FgQuaternary = hex("#73888c"),
		FgQuinary = hex("#657b83"),
		Success = hex("#859900"),
	},
}
