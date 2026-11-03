local utils = require(script.Parent.utils)
local hex = utils.hex

-- Gruvbox Dark: Retro warm browns with cream text and an orange accent.
return {
	name = "gruvbox dark",
	title = "Gruvbox Dark",
	BgBaseColor = hex("#282828"),
	AccentPrimary = hex("#fe8019"),
	AccentSecondary = hex("#83a598"),
	AccentCaution = hex("#fabd2f"),
	AccentDestructive = hex("#fd5f4c"),
	Overrides = {
		BgSunken = hex("#282828"),
		FgPrimary = hex("#ebdbb2"),
		FgSecondary = hex("#d5c4a1"),
		FgTertiary = hex("#bdae93"),
		FgQuaternary = hex("#a89984"),
		FgQuinary = hex("#928374"),
		Success = hex("#b8bb26"),
	},
}
