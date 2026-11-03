local utils = require(script.Parent.utils)
local hex = utils.hex

-- Moss: Forest-floor greens with a sage accent.
return {
	name = "moss",
	title = "Moss",
	BgBaseColor = hex("#121611"),
	AccentPrimary = hex("#8fbf6a"),
	AccentSecondary = hex("#d6b25e"),
	AccentCaution = hex("#e8a24a"),
	AccentDestructive = hex("#ec6a5e"),
	Overrides = {
		FgPrimary = hex("#eef3ea"),
		FgSecondary = hex("#c9d2c2"),
		FgTertiary = hex("#97a28e"),
		FgQuaternary = hex("#7a8571"),
		FgQuinary = hex("#6b7562"),
		Success = hex("#5fcf9a"),
	},
}
