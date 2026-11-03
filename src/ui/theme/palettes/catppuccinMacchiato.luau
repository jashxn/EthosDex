local utils = require(script.Parent.utils)
local hex = utils.hex

-- Catppuccin Macchiato: Catppuccin's medium-dark flavour, mauve accent.
return {
	name = "catppuccin macchiato",
	title = "Catppuccin Macchiato",
	BgBaseColor = hex("#24273a"),
	AccentPrimary = hex("#c6a0f6"),
	AccentSecondary = hex("#8aadf4"),
	AccentCaution = hex("#eed49f"),
	AccentDestructive = hex("#ed8796"),
	Overrides = {
		BgSunken = hex("#24273a"),
		FgPrimary = hex("#cad3f5"),
		FgSecondary = hex("#b8c0e0"),
		FgTertiary = hex("#a5adcb"),
		FgQuaternary = hex("#939ab7"),
		FgQuinary = hex("#8087a2"),
		Success = hex("#a6da95"),
	},
}
