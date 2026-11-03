--!strict
--!nolint LocalShadow

local ColorSpace = require(script.Parent.Parent.colorSpace)

local Types = require(script.Parent.types)
local Constants = require(script.Parent.constants)

local CORNER_RADIUS_SM = 3
local CORNER_RADIUS_MD = 6
local CORNER_RADIUS_LG = 9

local BACKGROUND_PALETTE_SIZE = 6
local BACKGROUND_LIGHTNESS_STRENGTH = 0.225
local MAX_BACKGROUND_TINT_CHROMA = 0.035

local SUNKEN_TOWARD_BLACK = 0.14

local GAMUT_SEARCH_ITERATIONS = 12
local MIN_ACCENT_TEXT_CONTRAST = 4.5

local EXTENDED_PALETTE_MIN_LIGHTNESS_OFFSET = 0.18

local LIGHT_TEXT_SURFACE_BLEND = { 0, 0.18, 0.36, 0.46, 0.56 }
local DARK_TEXT_SURFACE_BLEND = { 0, 0.25, 0.5, 0.64, 0.76 }

local function LerpColor(from: Color3, to: Color3, alpha: number): Color3
	return ColorSpace.ToGamutMappedColor3(
		ColorSpace.Oklab.From(from):Lerp(ColorSpace.Oklab.From(to), alpha)
	)
end

local function GenBackgroundPalette(baseColor: Color3, tintColor: Color3): { Color3 }
	local baseOklab = ColorSpace.Oklab.From(baseColor)
	local baseOklch = baseOklab:ToOklch()
	local tintOklch = ColorSpace.Oklch.From(tintColor)
	local targetLightness = if baseOklch:IsDark() then 1 else 0

	local targetChroma = math.min(
		tintOklch.chroma,
		math.max(baseOklch.chroma, MAX_BACKGROUND_TINT_CHROMA)
	)
	local targetTint = ColorSpace.Oklch.new(baseOklch.lightness, targetChroma, tintOklch.hue):ToOklab()

	local palette = table.create(BACKGROUND_PALETTE_SIZE) :: { Color3 }
	palette[1] = baseColor

	for idx = 2, BACKGROUND_PALETTE_SIZE do
		local progress = (idx - 1) / (BACKGROUND_PALETTE_SIZE - 1)
		local newLightness = baseOklab.lightness
			+ (targetLightness - baseOklab.lightness) * progress * BACKGROUND_LIGHTNESS_STRENGTH

		palette[idx] = ColorSpace.ToGamutMappedColor3(
			ColorSpace.Oklab.new(
				newLightness,
				baseOklab.a + (targetTint.a - baseOklab.a) * progress,
				baseOklab.b + (targetTint.b - baseOklab.b) * progress
			)
		)
	end

	return palette
end

local function GenLerpedPalette(colors: { Color3 }, alpha: number): { Color3 }
	local palette = table.create(#colors - 1) :: { Color3 }

	for idx = 1, #colors - 1 do
		local thisColor = colors[idx + 1]

		palette[idx] = LerpColor(colors[idx], thisColor, alpha)
	end

	return palette
end

local function GenFgPalette(surfaceColor: Color3, amount: number?): { Color3 }
	local baseFgColor = ColorSpace.Srgb.From(
		ColorSpace.Srgb.From(surfaceColor):BestContrast(
			ColorSpace.Srgb.From(Constants.BASE_LIGHT_TEXT_COLOR),
			ColorSpace.Srgb.From(Constants.BASE_DARK_TEXT_COLOR)
		)
	):ToColor3()
	local baseFg = ColorSpace.Oklab.From(baseFgColor)
	local surface = ColorSpace.Oklab.From(surfaceColor)
	local blendSteps = if baseFg:IsDark() then DARK_TEXT_SURFACE_BLEND else LIGHT_TEXT_SURFACE_BLEND
	local paletteSize = amount or 3

	assert(paletteSize <= #blendSteps, "Foreground palette exceeds configured tiers")

	local palette = table.create(paletteSize) :: { Color3 }
	palette[1] = baseFgColor
	for idx = 2, paletteSize do
		palette[idx] = ColorSpace.ToGamutMappedColor3(baseFg:Lerp(surface, blendSteps[idx]))
	end

	return palette
end

local function GenFgAccent(accentColor: Color3, primaryFgColor: Color3, surfaceColor: Color3): Color3
	local accentOklch = ColorSpace.Oklch.From(accentColor)
	local primaryFg = ColorSpace.Oklch.From(primaryFgColor)
	local candidate = ColorSpace.ToGamutMappedColor3(
		ColorSpace.Oklch.new(
			accentOklch.lightness + (primaryFg.lightness - accentOklch.lightness) * 0.6,
			math.min(math.max(accentOklch.chroma * 0.7, 0.08), 0.16),
			accentOklch.hue
		)
	)

	if ColorSpace.Srgb.From(surfaceColor):CheckContrast(candidate).ratio >= MIN_ACCENT_TEXT_CONTRAST then
		return candidate
	end

	local low = 0
	local high = 1
	local best = primaryFgColor
	for _ = 1, GAMUT_SEARCH_ITERATIONS do
		local midpoint = (low + high) / 2
		local adjusted = LerpColor(candidate, primaryFgColor, midpoint)

		if ColorSpace.Srgb.From(surfaceColor):CheckContrast(adjusted).ratio
			>= MIN_ACCENT_TEXT_CONTRAST then
			high = midpoint
			best = adjusted
		else
			low = midpoint
		end
	end

	return best
end

local function GenExtendedPalette(bgBaseColor: Color3): { [string]: Color3 }
	local baseOklch = ColorSpace.Oklch.From(bgBaseColor)
	local baseLightness = baseOklch.lightness
	local minLightness = baseLightness + EXTENDED_PALETTE_MIN_LIGHTNESS_OFFSET
	local maxLightness = baseLightness - EXTENDED_PALETTE_MIN_LIGHTNESS_OFFSET

	local palette: { [string]: Color3 } = {}
	for rawName, seed in Constants.COLOR_SEEDS do
		local name: string = rawName :: any
		local seedOklch = ColorSpace.Oklch.From(seed)
		local lightness = if baseOklch:IsDark() then math.max(seedOklch.lightness, minLightness)
			else math.min(seedOklch.lightness, maxLightness)

		palette[name] = ColorSpace.ToGamutMappedColor3(
			ColorSpace.Oklch.new(lightness, seedOklch.chroma, seedOklch.hue)
		)
	end
	return palette
end

local function CreateTheme(config: Types.ThemeConfig): Types.ThemeSource
	local bgBaseColor = config.BgBaseColor
	local accentPrimary = config.AccentPrimary
	local accentSecondary = config.AccentSecondary
	local accentCaution = config.AccentCaution
	local accentDestructive = config.AccentDestructive

	local bgColors = GenBackgroundPalette(bgBaseColor, config.BgTintColor or bgBaseColor)
	local bgHighlightColors = GenLerpedPalette(bgColors, 0.5)

	local fgColors = GenFgPalette(bgBaseColor, 5)

	local accentPrimaryFgColors = GenFgPalette(accentPrimary)
	local accentSecondaryFgColors = GenFgPalette(accentSecondary)
	local accentCautionFgColors = GenFgPalette(accentCaution)
	local accentDestructiveFgColors = GenFgPalette(accentDestructive)

	local primaryFgColor = fgColors[1]

	local extendedPalette = GenExtendedPalette(bgBaseColor)

	local source: Types.ThemeSource = {
		BgPrimary = bgColors[1],
		BgSecondary = bgColors[2],
		BgTertiary = bgColors[3],
		BgQuaternary = bgColors[4],
		BgQuinary = bgColors[5],
		BgPrimaryHighlight = bgHighlightColors[1],
		BgSecondaryHighlight = bgHighlightColors[2],
		BgTertiaryHighlight = bgHighlightColors[3],
		BgQuaternaryHighlight = bgHighlightColors[4],
		BgQuinaryHighlight = bgHighlightColors[5],
		BgSunken = LerpColor(bgBaseColor, Color3.new(0, 0, 0), SUNKEN_TOWARD_BLACK),
		FgPrimary = primaryFgColor,
		FgSecondary = fgColors[2],
		FgTertiary = fgColors[3],
		FgQuaternary = fgColors[4],
		FgQuinary = fgColors[5],
		AccentPrimary = accentPrimary,
		AccentSecondary = accentSecondary,
		AccentCaution = accentCaution,
		AccentDestructive = accentDestructive,
		AccentPrimaryFgPrimary = accentPrimaryFgColors[1],
		AccentPrimaryFgSecondary = accentPrimaryFgColors[2],
		AccentPrimaryFgTertiary = accentPrimaryFgColors[3],
		AccentSecondaryFgPrimary = accentSecondaryFgColors[1],
		AccentSecondaryFgSecondary = accentSecondaryFgColors[2],
		AccentSecondaryFgTertiary = accentSecondaryFgColors[3],
		AccentCautionFgPrimary = accentCautionFgColors[1],
		AccentCautionFgSecondary = accentCautionFgColors[2],
		AccentCautionFgTertiary = accentCautionFgColors[3],
		AccentDestructiveFgPrimary = accentDestructiveFgColors[1],
		AccentDestructiveFgSecondary = accentDestructiveFgColors[2],
		AccentDestructiveFgTertiary = accentDestructiveFgColors[3],
		AccentFgPrimary = GenFgAccent(accentPrimary, primaryFgColor, bgBaseColor),
		AccentFgSecondary = GenFgAccent(accentSecondary, primaryFgColor, bgBaseColor),
		AccentFgCaution = GenFgAccent(accentCaution, primaryFgColor, bgBaseColor),
		AccentFgDestructive = GenFgAccent(accentDestructive, primaryFgColor, bgBaseColor),
		Success = extendedPalette.Success,
		Blue = extendedPalette.Blue,
		Brown = extendedPalette.Brown,
		Cyan = extendedPalette.Cyan,
		Gray = extendedPalette.Gray,
		Green = extendedPalette.Green,
		Magenta = extendedPalette.Magenta,
		Orange = extendedPalette.Orange,
		Pink = extendedPalette.Pink,
		Purple = extendedPalette.Purple,
		Red = extendedPalette.Red,
		Violet = extendedPalette.Violet,
		White = extendedPalette.White,
		Yellow = extendedPalette.Yellow,
		HeightSm = config.HeightSm,
		HeightMd = config.HeightMd,
		HeightLg = config.HeightLg,
		CornerRadiusSm = CORNER_RADIUS_SM,
		CornerRadiusMd = CORNER_RADIUS_MD,
		CornerRadiusLg = CORNER_RADIUS_LG,
		FontMain = config.FontMain,
		FontMono = config.FontMono,
		FontMainTitleSize = config.FontMainTitleSize,
		FontMainBodySize = config.FontMainBodySize,
		FontMainCaptionSize = config.FontMainCaptionSize,
		FontMonoTitleSize = config.FontMonoTitleSize,
		FontMonoBodySize = config.FontMonoBodySize,
		FontMonoCaptionSize = config.FontMonoCaptionSize,
	}
	for token, color in config.Overrides or {} do
		if typeof(source[token]) == "Color3" and typeof(color) == "Color3" then
			source[token] = color
		end
	end
	return source
end

return CreateTheme
