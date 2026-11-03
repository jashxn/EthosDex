local utils = require(script.Parent.utils)
local hex = utils.hex

-- Obsidian: Near-black with a soft violet accent, close to the default look but darker.
return {
	name = "obsidian",
	title = "Obsidian",
	BgBaseColor = hex("#101014"),
	AccentPrimary = hex("#8b6cf0"),
	AccentSecondary = hex("#5aa8e0"),
	AccentCaution = hex("#e8a94a"),
	AccentDestructive = hex("#ef5a6a"),
	Overrides = {
		FgPrimary = hex("#f4f4f8"),
		FgSecondary = hex("#c9c9d3"),
		FgTertiary = hex("#9a9aa8"),
		FgQuaternary = hex("#7a7a88"),
		FgQuinary = hex("#6a6a78"),
		Success = hex("#4cc77a"),
	},
}
