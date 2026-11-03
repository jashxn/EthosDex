local utils = require(script.Parent.utils)
local hex = utils.hex

-- Cobalt: Ink-blue surfaces with a vivid cobalt accent.
return {
	name = "cobalt",
	title = "Cobalt",
	BgBaseColor = hex("#0d1220"),
	AccentPrimary = hex("#3d7bfd"),
	AccentSecondary = hex("#22c3e6"),
	AccentCaution = hex("#f0b44c"),
	AccentDestructive = hex("#f45d6e"),
	Overrides = {
		FgPrimary = hex("#eef2fb"),
		FgSecondary = hex("#c4cde2"),
		FgTertiary = hex("#8f9bb7"),
		FgQuaternary = hex("#73809c"),
		FgQuinary = hex("#64708c"),
		Success = hex("#4fd08a"),
	},
}
