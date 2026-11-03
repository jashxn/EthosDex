local utils = require(script.Parent.utils)
local hex = utils.hex

-- Catppuccin Latte: Catppuccin's light flavour, mauve accent.
return {
	name = "catppuccin latte",
	title = "Catppuccin Latte",
	BgBaseColor = hex("#eff1f5"),
	AccentPrimary = hex("#8839ef"),
	AccentSecondary = hex("#1e66f5"),
	AccentCaution = hex("#985a08"),
	AccentDestructive = hex("#d20f39"),
	Overrides = {
		BgSunken = hex("#eff1f5"),
		FgPrimary = hex("#4c4f69"),
		FgSecondary = hex("#5c5f77"),
		FgTertiary = hex("#63667c"),
		FgQuaternary = hex("#74778c"),
		FgQuinary = hex("#84879a"),
		Success = hex("#2f7a1f"),
	},
}
