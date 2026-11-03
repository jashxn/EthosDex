local utils = require(script.Parent.utils)
local hex = utils.hex

-- Nord: Arctic polar night with frost-blue accents.
return {
	name = "nord",
	title = "Nord",
	BgBaseColor = hex("#2e3440"),
	AccentPrimary = hex("#88c0d0"),
	AccentSecondary = hex("#81a1c1"),
	AccentCaution = hex("#ebcb8b"),
	AccentDestructive = hex("#d9868c"),
	Overrides = {
		BgSunken = hex("#2e3440"),
		FgPrimary = hex("#eceff4"),
		FgSecondary = hex("#e5e9f0"),
		FgTertiary = hex("#c0c8d6"),
		FgQuaternary = hex("#a3adbf"),
		FgQuinary = hex("#8e99ad"),
		Success = hex("#a3be8c"),
	},
}
