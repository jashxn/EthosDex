local utils = require(script.Parent.utils)
local hex = utils.hex

-- Ayu Mirage: Ayu's mid-tone variant.
return {
	name = "ayu mirage",
	title = "Ayu Mirage",
	BgBaseColor = hex("#1f2430"),
	AccentPrimary = hex("#ffcc66"),
	AccentSecondary = hex("#5ccfe6"),
	AccentCaution = hex("#ffad66"),
	AccentDestructive = hex("#ff6666"),
	Overrides = {
		BgSunken = hex("#1f2430"),
		FgPrimary = hex("#e6e1cf"),
		FgSecondary = hex("#cccac2"),
		FgTertiary = hex("#a0a3ab"),
		FgQuaternary = hex("#8a8e98"),
		FgQuinary = hex("#7a7e88"),
		Success = hex("#d5ff80"),
	},
}
