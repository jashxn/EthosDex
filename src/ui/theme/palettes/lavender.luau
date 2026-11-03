local utils = require(script.Parent.utils)
local hex = utils.hex

-- Lavender: Cool grey with a soft lilac accent.
return {
	name = "lavender",
	title = "Lavender",
	BgBaseColor = hex("#16151c"),
	AccentPrimary = hex("#b49cf5"),
	AccentSecondary = hex("#f0a0d0"),
	AccentCaution = hex("#ebb75a"),
	AccentDestructive = hex("#f36b7f"),
	Overrides = {
		FgPrimary = hex("#f3f1f8"),
		FgSecondary = hex("#cdc9da"),
		FgTertiary = hex("#9d98ae"),
		FgQuaternary = hex("#7f7a90"),
		FgQuinary = hex("#6f6a80"),
		Success = hex("#62cf90"),
	},
}
