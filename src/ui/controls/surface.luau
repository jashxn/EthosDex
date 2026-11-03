local Root = script.Parent.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Motion = require(Root.ui.motion)
local Icons = require(Root.ui.icons.dock)
local SharedIcons = require(Root.ui.icons.shared)
local Images = require(Root.ui.images)
local RuntimeAssets = require(Root.utils.runtimeAssets)
local Theme = require(Root.ui.tokens)

local soft = Motion.Soft
local animate = Motion.Animate

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local Controls = {}

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

function Controls.Interaction(scope)
	local hovered = scope:Value(false)
	local pressed = scope:Value(false)
	return {
		Hovered = hovered,
		Pressed = pressed,
		HoverT = animate(
			scope,
			scope:Computed(function(use)
				return if use(hovered) then 1 else 0
			end),
			soft(0.12)
		),
		PressT = animate(
			scope,
			scope:Computed(function(use)
				return if use(pressed) then 1 else 0
			end),
			soft(0.1)
		),
		Events = {
			[OnEvent("MouseEnter")] = function()
				hovered:set(true)
			end,
			[OnEvent("MouseLeave")] = function()
				hovered:set(false)
				pressed:set(false)
			end,
			[OnEvent("InputBegan")] = function(input)
				if isPointer(input) then
					pressed:set(true)
				end
			end,
			[OnEvent("InputEnded")] = function(input)
				if isPointer(input) then
					pressed:set(false)
				end
			end,
		},
	}
end

local function merge(into, from)
	for key, value in from do
		into[key] = value
	end
	return into
end

function Controls.Edge(scope, lit, radius)
	return {
		scope:New("UICorner")({ CornerRadius = radius or UDim.new(0, 12) }),
		scope:New("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			Color = Theme.Ink,
			Thickness = 1,
			[Children] = scope:New("UIGradient")({
				Rotation = 90,
				Transparency = scope:Computed(function(use)
					local t = if lit then use(lit) else 0
					return NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.88 - 0.14 * t),
						NumberSequenceKeypoint.new(0.5, 0.96 - 0.02 * t),
						NumberSequenceKeypoint.new(1, 0.985),
					})
				end),
			}),
		}),
	}
end

function Controls.FillAlpha(level, at)
	return level * (1 - 0.55 * at)
end

function Controls.Fill(scope, level)
	return scope:New("UIGradient")({
		Rotation = 90,
		Transparency = scope:Computed(function(use)
			local top = use(level)
			return NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1 - Controls.FillAlpha(top, 0)),
				NumberSequenceKeypoint.new(1, 1 - Controls.FillAlpha(top, 1)),
			})
		end),
	})
end

function Controls.texture(name: string?): string?
	return if name then Icons[name] or SharedIcons[name] else nil
end

function Controls.apply(label: ImageLabel, name: string?)
	if name and Images:IsIcon(name) then
		Images:Track(name, label)
	else
		Images:Track(nil, label)
		label.Image = RuntimeAssets.resolve(Controls.texture(name) or "")
	end
end

function Controls.Icon(scope, name, size, props)
	props = props or {}
	props.Name = props.Name or "Icon"
	props.Size = UDim2.fromOffset(size, size)
	props.BackgroundTransparency = 1
	props.ImageColor3 = props.ImageColor3 or Theme.Ink
	local label = scope:New("ImageLabel")(props)
	if type(name) == "table" then
		scope:Observer(name):onBind(function()
			Controls.apply(label, peek(name))
		end)
	else
		Controls.apply(label, name)
	end
	table.insert(
		scope,
		function()
			Images:Untrack(label)
		end
	)
	return label
end

function Controls.Label(scope, props)
	props.BackgroundTransparency = 1
	props.FontFace = props.FontFace or Theme.Title
	props.TextSize = props.TextSize or 14
	props.TextColor3 = props.TextColor3 or Theme.Ink
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd
	return scope:New("TextLabel")(props)
end

function Controls.Section(scope, props)
	return scope:New("Frame")({
		Name = props.Name or "Section",
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		[Children] = Controls.Label(
			scope,
			{
				Position = UDim2.fromOffset(props.Inset or 0, 0),
				Size = UDim2.new(1, -(props.Inset or 0), 1, 0),
				Text = props.Text,
				TextSize = 13,
				FontFace = Theme.Title,
				TextColor3 = Theme.Muted,
			}
		),
	})
end
Controls.merge = merge

return table.freeze(Controls)
