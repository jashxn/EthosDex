local utils = require(script.Parent.utils)
local hex = utils.hex

-- Synthwave: Midnight purple with neon pink and cyan.
return {
	name = "synthwave",
	title = "Synthwave",
	BgBaseColor = hex("#1a1029"),
	AccentPrimary = hex("#ff4fd8"),
	AccentSecondary = hex("#2de2e6"),
	AccentCaution = hex("#ffd319"),
	AccentDestructive = hex("#ff6b6b"),
	Overrides = {
		BgSunken = hex("#160d24"),
		FgPrimary = hex("#fbefff"),
		FgSecondary = hex("#dccbe8"),
		FgTertiary = hex("#ad98bf"),
		FgQuaternary = hex("#8e78a2"),
		FgQuinary = hex("#7e6892"),
		Success = hex("#72f1b8"),
	},
}
