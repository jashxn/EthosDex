local utils = require(script.Parent.utils)
local hex = utils.hex

-- Abyss: Deep teal-black with a bright cyan accent.
return {
	name = "abyss",
	title = "Abyss",
	BgBaseColor = hex("#0b1417"),
	AccentPrimary = hex("#2cc4d8"),
	AccentSecondary = hex("#5b8cf0"),
	AccentCaution = hex("#e8b04a"),
	AccentDestructive = hex("#f0607a"),
	Overrides = {
		FgPrimary = hex("#eef6f7"),
		FgSecondary = hex("#c3d3d6"),
		FgTertiary = hex("#8fa5aa"),
		FgQuaternary = hex("#728a8f"),
		FgQuinary = hex("#627a80"),
		Success = hex("#52cc84"),
	},
}
