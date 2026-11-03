local utils = require(script.Parent.utils)
local hex = utils.hex

-- GitHub Light: GitHub's light default.
return {
	name = "github light",
	title = "GitHub Light",
	BgBaseColor = hex("#ffffff"),
	AccentPrimary = hex("#0969da"),
	AccentSecondary = hex("#8250df"),
	AccentCaution = hex("#9a6700"),
	AccentDestructive = hex("#d1242f"),
	Overrides = {
		BgSunken = hex("#ffffff"),
		FgPrimary = hex("#1f2328"),
		FgSecondary = hex("#31373d"),
		FgTertiary = hex("#59636e"),
		FgQuaternary = hex("#6e7781"),
		FgQuinary = hex("#818b98"),
		Success = hex("#1a7f37"),
	},
}
