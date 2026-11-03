local utils = require(script.Parent.utils)
local hex = utils.hex

-- Daylight: Clean cool white with a blue accent.
return {
	name = "daylight",
	title = "Daylight",
	BgBaseColor = hex("#f5f7fa"),
	AccentPrimary = hex("#2563eb"),
	AccentSecondary = hex("#0e8f9f"),
	AccentCaution = hex("#9a6100"),
	AccentDestructive = hex("#c8243a"),
	Overrides = {
		BgSunken = hex("#f5f7fa"),
		FgPrimary = hex("#14181f"),
		FgSecondary = hex("#363d49"),
		FgTertiary = hex("#555e6c"),
		FgQuaternary = hex("#6c7584"),
		FgQuinary = hex("#7f8896"),
		Success = hex("#1d7a3e"),
	},
}
