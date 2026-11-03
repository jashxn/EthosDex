local utils = require(script.Parent.utils)
local hex = utils.hex

-- Catppuccin Frappé: Catppuccin's muted flavour, mauve accent.
return {
	name = "catppuccin frappé",
	title = "Catppuccin Frappé",
	BgBaseColor = hex("#303446"),
	AccentPrimary = hex("#ca9ee6"),
	AccentSecondary = hex("#8caaee"),
	AccentCaution = hex("#e5c890"),
	AccentDestructive = hex("#e78284"),
	Overrides = {
		BgSunken = hex("#303446"),
		FgPrimary = hex("#c6d0f5"),
		FgSecondary = hex("#b5bfe2"),
		FgTertiary = hex("#a5adce"),
		FgQuaternary = hex("#949cbb"),
		FgQuinary = hex("#838ba7"),
		Success = hex("#a6d189"),
	},
}
