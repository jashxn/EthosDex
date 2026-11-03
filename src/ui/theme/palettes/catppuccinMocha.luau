local utils = require(script.Parent.utils)
local hex = utils.hex

-- Catppuccin Mocha: Catppuccin's darkest flavour, mauve accent.
return {
	name = "catppuccin mocha",
	title = "Catppuccin Mocha",
	BgBaseColor = hex("#1e1e2e"),
	AccentPrimary = hex("#cba6f7"),
	AccentSecondary = hex("#89b4fa"),
	AccentCaution = hex("#f9e2af"),
	AccentDestructive = hex("#f38ba8"),
	Overrides = {
		BgSunken = hex("#1e1e2e"),
		FgPrimary = hex("#cdd6f4"),
		FgSecondary = hex("#bac2de"),
		FgTertiary = hex("#a6adc8"),
		FgQuaternary = hex("#9399b2"),
		FgQuinary = hex("#7f849c"),
		Success = hex("#a6e3a1"),
	},
}
