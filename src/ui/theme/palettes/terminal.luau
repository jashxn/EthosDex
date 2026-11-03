local utils = require(script.Parent.utils)
local hex = utils.hex

-- Terminal: Phosphor green on black, like an old CRT.
return {
	name = "terminal",
	title = "Terminal",
	BgBaseColor = hex("#050a06"),
	AccentPrimary = hex("#33ff66"),
	AccentSecondary = hex("#ffcc33"),
	AccentCaution = hex("#ffcc33"),
	AccentDestructive = hex("#ff5f56"),
	Overrides = {
		BgSunken = hex("#050a06"),
		FgPrimary = hex("#c8ffcf"),
		FgSecondary = hex("#9ae6a6"),
		FgTertiary = hex("#6cbd7a"),
		FgQuaternary = hex("#58a166"),
		FgQuinary = hex("#4c9059"),
		Success = hex("#7dff9a"),
	},
}
