--!strict
--!nolint LocalShadow

local Fusion = require(script.Parent.Parent.Parent.packages.fusion)

export type BgVariant = "Primary" | "Secondary" | "Tertiary" | "Quaternary" | "Quinary"

export type FgVariant = "Primary" | "Secondary" | "Tertiary" | "Quaternary" | "Quinary"

export type AccentVariant = "Primary" | "Secondary" | "Caution" | "Destructive"

export type HeightVariant = "Sm" | "Md" | "Lg"

export type CornerRadiusVariant = "Sm" | "Md" | "Lg"

export type FontVariant = "Main" | "Mono"

export type FontSizeVariant = "Title" | "Body" | "Caption"

export type ThemeColorModifier = "Hover" | "Press" | "HoverStroke"

-- A theme is fully described by a handful of seed colors plus layout
-- dimensions. Everything else is generated in Oklab by createTheme.
export type ThemeConfig = {
	BgBaseColor: Color3,
	-- Optional hue target for elevated backgrounds. When omitted, tiers
	-- preserve BgBaseColor's hue and neutral themes remain neutral.
	BgTintColor: Color3?,

	AccentPrimary: Color3,
	AccentSecondary: Color3,
	AccentCaution: Color3,
	AccentDestructive: Color3,

	HeightSm: number,
	HeightMd: number,
	HeightLg: number,

	FontMain: Font,
	FontMono: Font,

	FontMainTitleSize: number,
	FontMainBodySize: number,
	FontMainCaptionSize: number,

	FontMonoTitleSize: number,
	FontMonoBodySize: number,
	FontMonoCaptionSize: number,

	[string]: any,
}

export type ThemeSource = {
	BgPrimary: Color3,
	BgSecondary: Color3,
	BgTertiary: Color3,
	BgQuaternary: Color3,
	BgQuinary: Color3,
	BgPrimaryHighlight: Color3,
	BgSecondaryHighlight: Color3,
	BgTertiaryHighlight: Color3,
	BgQuaternaryHighlight: Color3,
	BgQuinaryHighlight: Color3,
	BgSunken: Color3,
	FgPrimary: Color3,
	FgSecondary: Color3,
	FgTertiary: Color3,
	FgQuaternary: Color3,
	FgQuinary: Color3,
	AccentPrimary: Color3,
	AccentSecondary: Color3,
	AccentCaution: Color3,
	AccentDestructive: Color3,
	AccentPrimaryFgPrimary: Color3,
	AccentPrimaryFgSecondary: Color3,
	AccentPrimaryFgTertiary: Color3,
	AccentSecondaryFgPrimary: Color3,
	AccentSecondaryFgSecondary: Color3,
	AccentSecondaryFgTertiary: Color3,
	AccentCautionFgPrimary: Color3,
	AccentCautionFgSecondary: Color3,
	AccentCautionFgTertiary: Color3,
	AccentDestructiveFgPrimary: Color3,
	AccentDestructiveFgSecondary: Color3,
	AccentDestructiveFgTertiary: Color3,
	AccentFgPrimary: Color3,
	AccentFgSecondary: Color3,
	AccentFgCaution: Color3,
	AccentFgDestructive: Color3,
	Success: Color3,
	Blue: Color3,
	Brown: Color3,
	Cyan: Color3,
	Gray: Color3,
	Green: Color3,
	Magenta: Color3,
	Orange: Color3,
	Pink: Color3,
	Purple: Color3,
	Red: Color3,
	Violet: Color3,
	White: Color3,
	Yellow: Color3,
	HeightSm: number,
	HeightMd: number,
	HeightLg: number,
	CornerRadiusSm: number,
	CornerRadiusMd: number,
	CornerRadiusLg: number,
	FontMain: Font,
	FontMono: Font,
	FontMainTitleSize: number,
	FontMainBodySize: number,
	FontMainCaptionSize: number,
	FontMonoTitleSize: number,
	FontMonoBodySize: number,
	FontMonoCaptionSize: number,
	[string]: any,
}

-- The reactive theme object consumed by components: every token is a
-- Fusion state object (Color3 tokens tween in Oklab between themes).
export type Theme = {
	[string]: Fusion.UsedAs<unknown>,
	GetToken: (theme: Theme, scope: Fusion.Scope, tokenName: Fusion.UsedAs<string>) -> Fusion.UsedAs<unknown>,
	GetBg: (theme: Theme, scope: Fusion.Scope, variant: Fusion.UsedAs<BgVariant>, modifier: Fusion.UsedAs<ThemeColorModifier?>) -> Fusion.UsedAs<Color3>,
	GetBgHighlight: (theme: Theme, scope: Fusion.Scope, variant: Fusion.UsedAs<BgVariant>, modifier: Fusion.UsedAs<ThemeColorModifier?>) -> Fusion.UsedAs<Color3>,
	GetFg: (theme: Theme, scope: Fusion.Scope, variant: Fusion.UsedAs<FgVariant>, accentVariant: Fusion.UsedAs<AccentVariant?>?, modifier: Fusion.UsedAs<ThemeColorModifier?>) -> Fusion.UsedAs<Color3>,
	GetAccent: (theme: Theme, scope: Fusion.Scope, variant: Fusion.UsedAs<AccentVariant>, modifier: Fusion.UsedAs<ThemeColorModifier?>) -> Fusion.UsedAs<Color3>,
	GetAccentFg: (theme: Theme, scope: Fusion.Scope, variant: Fusion.UsedAs<AccentVariant>, modifier: Fusion.UsedAs<ThemeColorModifier?>) -> Fusion.UsedAs<Color3>,
	GetHeight: (theme: Theme, scope: Fusion.Scope, variant: Fusion.UsedAs<HeightVariant>) -> Fusion.UsedAs<number>,
	GetCornerRadius: (theme: Theme, scope: Fusion.Scope, variant: Fusion.UsedAs<CornerRadiusVariant>) -> Fusion.UsedAs<number>,
	GetFont: (theme: Theme, scope: Fusion.Scope, variant: Fusion.UsedAs<FontVariant>, weight: Fusion.UsedAs<Enum.FontWeight>?, style: Fusion.UsedAs<Enum.FontStyle>?) -> Fusion.UsedAs<Font>,
	GetFontSize: (theme: Theme, scope: Fusion.Scope, variant: Fusion.UsedAs<FontVariant>, sizeVariant: Fusion.UsedAs<FontSizeVariant>) -> Fusion.UsedAs<number>,
	HighlightGradient: (theme: Theme, scope: Fusion.Scope, transparency: Fusion.UsedAs<number>, gradientColor: Fusion.UsedAs<ColorSequence?>?) -> UIGradient,
}

return nil
