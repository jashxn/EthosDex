local utils = require(script.Parent.utils)
local hex = utils.hex

-- Lagoon: Blue-green surfaces with a turquoise accent.
return {
	name = "lagoon",
	title = "Lagoon",
	BgBaseColor = hex("#0f1a1c"),
	AccentPrimary = hex("#1fb8a4"),
	AccentSecondary = hex("#4aa3e8"),
	AccentCaution = hex("#e6b450"),
	AccentDestructive = hex("#ef6670"),
	Overrides = {
		FgPrimary = hex("#edf7f6"),
		FgSecondary = hex("#c2d6d4"),
		FgTertiary = hex("#8ea9a6"),
		FgQuaternary = hex("#71908d"),
		FgQuinary = hex("#62807d"),
		Success = hex("#6ccf6a"),
	},
}
