local Root = script.Parent.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Motion = require(Root.ui.motion)
local Theme = require(Root.ui.tokens)
local Surface = require(script.Parent.surface)

local snap = Motion.Snap
local animate = Motion.Animate

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
local merge = Surface.merge

local Controls = {}

function Controls.Switch(scope, onT, pressT)
	return scope:New("Frame")({
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(32, 20),
		BackgroundColor3 = scope:Computed(function(use)
			return use(Theme.Track):Lerp(use(Theme.Accent), use(onT))
		end),
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
			scope:New("Frame")({
				Name = "Thumb",
				AnchorPoint = scope:Computed(function(use)
					return Vector2.new(use(onT), 0.5)
				end),
				Position = scope:Computed(function(use)
					local t = use(onT)
					return UDim2.new(t, 2 - 4 * t, 0.5, 0)
				end),
				Size = scope:Computed(function(use)
					return UDim2.fromOffset(16 + 3 * use(pressT), 16)
				end),
				BackgroundColor3 = scope:Computed(function(use)
					return use(Theme.Ink):Lerp(use(Theme.AccentInk), use(onT))
				end),
				[Children] = scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
			}),
		},
	})
end

function Controls.SwitchCard(scope, props)
	local interaction = Surface.Interaction(scope)
	local on = props.On
	local disabled = props.Disabled
	local isDisabled = scope:Computed(function(use)
		return disabled ~= nil and use(disabled) ~= nil
	end)
	local onT = animate(
		scope,
		scope:Computed(function(use)
			return if use(on) then 1 else 0
		end),
		snap(0.25)
	)
	local level = scope:Computed(function(use)
		return 0.05 + 0.03 * use(interaction.HoverT) + 0.05 * use(onT)
	end)
	return scope:New("TextButton")(
		merge(
			{
				Name = props.Name or props.Text,
				LayoutOrder = props.LayoutOrder,
				BackgroundColor3 = Theme.Ink,
				AutoButtonColor = false,
				Text = "",
				[OnEvent("Activated")] = function()
					if peek(isDisabled) then
						if props.OnBlocked then
							props.OnBlocked(peek(disabled))
						end
						return
					end
					on:set(not peek(on))
					if props.OnToggle then
						props.OnToggle(peek(on))
					end
				end,
				[Children] = {
					Surface.Fill(scope, level),
					Surface.Edge(scope, onT, UDim.new(0, 14)),
					Surface.Icon(
						scope,
						props.Icon,
						16,
						{
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 14, 0.5, 0),
							ImageColor3 = scope:Computed(function(use)
								if use(isDisabled) then
									return use(Theme.Faint)
								end
								return use(Theme.Muted):Lerp(
									use(Theme.Ink),
									math.max(use(onT), use(interaction.HoverT) * 0.6)
								)
							end),
						}
					),
					Surface.Label(
						scope,
						{
							Name = "Label",
							Position = UDim2.fromOffset(40, 0),
							Size = UDim2.new(1, -96, 1, 0),
							Text = props.Text,
							TextColor3 = scope:Computed(function(use)
								if use(isDisabled) then
									return use(Theme.Faint)
								end
								return use(Theme.Ink2):Lerp(use(Theme.Ink), use(onT))
							end),
						}
					),
					scope:Hydrate(Controls.Switch(scope, onT, interaction.PressT))({
						Visible = scope:Computed(function(use)
							return not use(isDisabled)
						end),
					}),
					Surface.Icon(
						scope,
						"lock",
						14,
						{
							Name = "Locked",
							Visible = isDisabled,
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, -11, 0.5, 0),
							ImageColor3 = Theme.Faint,
						}
					),
				},
			},
			interaction.Events
		)
	)
end

return table.freeze(Controls)
