local utils = require(script.Parent.utils)
local hex = utils.hex

-- GitHub Dark: GitHub's dark default.
return {
	name = "github dark",
	title = "GitHub Dark",
	BgBaseColor = hex("#0d1117"),
	AccentPrimary = hex("#4493f8"),
	AccentSecondary = hex("#a371f7"),
	AccentCaution = hex("#d29922"),
	AccentDestructive = hex("#f85149"),
	Overrides = {
		BgSunken = hex("#0d1117"),
		FgPrimary = hex("#e6edf3"),
		FgSecondary = hex("#c9d1d9"),
		FgTertiary = hex("#9198a1"),
		FgQuaternary = hex("#7d8590"),
		FgQuinary = hex("#6e7681"),
		Success = hex("#3fb950"),
	},
}
