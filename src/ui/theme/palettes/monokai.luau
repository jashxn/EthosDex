local utils = require(script.Parent.utils)
local hex = utils.hex

-- Monokai: The original Monokai: hot pink, lime and orange on olive-black.
return {
	name = "monokai",
	title = "Monokai",
	BgBaseColor = hex("#272822"),
	AccentPrimary = hex("#a6e22e"),
	AccentSecondary = hex("#66d9ef"),
	AccentCaution = hex("#e6db74"),
	AccentDestructive = hex("#ff4f88"),
	Overrides = {
		BgSunken = hex("#272822"),
		FgPrimary = hex("#f8f8f2"),
		FgSecondary = hex("#d6d6cc"),
		FgTertiary = hex("#a8a593"),
		FgQuaternary = hex("#908d7b"),
		FgQuinary = hex("#7d7a68"),
		Success = hex("#a6e22e"),
	},
}
