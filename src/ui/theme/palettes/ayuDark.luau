local utils = require(script.Parent.utils)
local hex = utils.hex

-- Ayu Dark: Ayu's deep dark variant with its golden accent.
return {
	name = "ayu dark",
	title = "Ayu Dark",
	BgBaseColor = hex("#0d1017"),
	AccentPrimary = hex("#e6b450"),
	AccentSecondary = hex("#39bae6"),
	AccentCaution = hex("#ff8f40"),
	AccentDestructive = hex("#f26d78"),
	Overrides = {
		BgSunken = hex("#0d1017"),
		FgPrimary = hex("#e6e1cf"),
		FgSecondary = hex("#bfbdb6"),
		FgTertiary = hex("#8f939a"),
		FgQuaternary = hex("#767b83"),
		FgQuinary = hex("#666b73"),
		Success = hex("#aad94c"),
	},
}
