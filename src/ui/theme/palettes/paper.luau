local utils = require(script.Parent.utils)
local hex = utils.hex

-- Paper: Warm off-white, like a notebook page, with an ink-blue accent.
return {
	name = "paper",
	title = "Paper",
	BgBaseColor = hex("#f7f4ec"),
	AccentPrimary = hex("#2f5bd3"),
	AccentSecondary = hex("#b0532c"),
	AccentCaution = hex("#9a5b00"),
	AccentDestructive = hex("#c0262d"),
	Overrides = {
		BgSunken = hex("#f7f4ec"),
		FgPrimary = hex("#24211c"),
		FgSecondary = hex("#45403a"),
		FgTertiary = hex("#5f5950"),
		FgQuaternary = hex("#77706a"),
		FgQuinary = hex("#8a8379"),
		Success = hex("#2a7a3b"),
	},
}
