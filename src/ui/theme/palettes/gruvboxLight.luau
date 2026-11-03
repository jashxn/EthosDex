local utils = require(script.Parent.utils)
local hex = utils.hex

-- Gruvbox Light: Gruvbox on its cream background.
return {
	name = "gruvbox light",
	title = "Gruvbox Light",
	BgBaseColor = hex("#fbf1c7"),
	AccentPrimary = hex("#af3a03"),
	AccentSecondary = hex("#076678"),
	AccentCaution = hex("#8a5a0f"),
	AccentDestructive = hex("#9d0006"),
	Overrides = {
		BgSunken = hex("#fbf1c7"),
		FgPrimary = hex("#3c3836"),
		FgSecondary = hex("#504945"),
		FgTertiary = hex("#665c54"),
		FgQuaternary = hex("#7c6f64"),
		FgQuinary = hex("#928374"),
		Success = hex("#5f5b0a"),
	},
}
