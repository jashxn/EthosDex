local utils = require(script.Parent.utils)
local hex = utils.hex

-- One Dark: Atom's One Dark with a blue accent.
return {
	name = "one dark",
	title = "One Dark",
	BgBaseColor = hex("#282c34"),
	AccentPrimary = hex("#61afef"),
	AccentSecondary = hex("#c678dd"),
	AccentCaution = hex("#e5c07b"),
	AccentDestructive = hex("#e8747d"),
	Overrides = {
		BgSunken = hex("#282c34"),
		FgPrimary = hex("#d7dae0"),
		FgSecondary = hex("#abb2bf"),
		FgTertiary = hex("#9aa1ad"),
		FgQuaternary = hex("#858b97"),
		FgQuinary = hex("#737985"),
		Success = hex("#98c379"),
	},
}
