local utils = require(script.Parent.utils)
local hex = utils.hex

-- Crimson: Charcoal with a crimson accent. Errors lean orange to stay apart from it.
return {
	name = "crimson",
	title = "Crimson",
	BgBaseColor = hex("#161214"),
	AccentPrimary = hex("#e0344f"),
	AccentSecondary = hex("#e88a5a"),
	AccentCaution = hex("#eab24c"),
	AccentDestructive = hex("#ff7a45"),
	Overrides = {
		FgPrimary = hex("#f7f2f3"),
		FgSecondary = hex("#d3c7ca"),
		FgTertiary = hex("#a3959a"),
		FgQuaternary = hex("#85777c"),
		FgQuinary = hex("#75686c"),
		Success = hex("#56c97c"),
	},
}
