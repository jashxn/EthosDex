local utils = require(script.Parent.utils)
local hex = utils.hex

-- Citrus: Olive-black with a lime accent.
return {
	name = "citrus",
	title = "Citrus",
	BgBaseColor = hex("#121510"),
	AccentPrimary = hex("#a6e22e"),
	AccentSecondary = hex("#e6d046"),
	AccentCaution = hex("#f0a83c"),
	AccentDestructive = hex("#f2606a"),
	Overrides = {
		FgPrimary = hex("#f2f6ec"),
		FgSecondary = hex("#cfd6c4"),
		FgTertiary = hex("#9ea692"),
		FgQuaternary = hex("#7f8874"),
		FgQuinary = hex("#707864"),
		Success = hex("#4fd1a0"),
	},
}
