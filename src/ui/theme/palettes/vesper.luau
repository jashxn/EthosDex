local utils = require(script.Parent.utils)
local hex = utils.hex

-- Vesper: Minimal black with a peach accent.
return {
	name = "vesper",
	title = "Vesper",
	BgBaseColor = hex("#101010"),
	AccentPrimary = hex("#ffc799"),
	AccentSecondary = hex("#99ffe4"),
	AccentCaution = hex("#ffc799"),
	AccentDestructive = hex("#ff8080"),
	Overrides = {
		BgSunken = hex("#101010"),
		FgPrimary = hex("#ffffff"),
		FgSecondary = hex("#d4d4d4"),
		FgTertiary = hex("#a0a0a0"),
		FgQuaternary = hex("#878787"),
		FgQuinary = hex("#767676"),
		Success = hex("#99ffe4"),
	},
}
