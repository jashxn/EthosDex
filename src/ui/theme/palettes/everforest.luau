local utils = require(script.Parent.utils)
local hex = utils.hex

-- Everforest: Comfortable forest greens with a green accent.
return {
	name = "everforest",
	title = "Everforest",
	BgBaseColor = hex("#2d353b"),
	AccentPrimary = hex("#a7c080"),
	AccentSecondary = hex("#7fbbb3"),
	AccentCaution = hex("#dbbc7f"),
	AccentDestructive = hex("#e67e80"),
	Overrides = {
		BgSunken = hex("#2d353b"),
		FgPrimary = hex("#d3c6aa"),
		FgSecondary = hex("#c2b89f"),
		FgTertiary = hex("#a7b0a6"),
		FgQuaternary = hex("#939f95"),
		FgQuinary = hex("#859289"),
		Success = hex("#83c092"),
	},
}
