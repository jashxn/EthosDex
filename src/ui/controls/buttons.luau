local Root = script.Parent.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Theme = require(Root.ui.tokens)
local Surface = require(script.Parent.surface)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local merge = Surface.merge

local Controls = {}

function Controls.Button(scope, props)
	local interaction = Surface.Interaction(scope)
	local ghost = props.Ghost == true
	local height = props.Height or 32
	local level = scope:Computed(function(use)
		if ghost then
			return 0.06 * use(interaction.HoverT) + 0.03 * use(interaction.PressT)
		end
		return 0.07 + 0.04 * use(interaction.HoverT) + 0.03 * use(interaction.PressT)
	end)
	local ink = props.Ink or Theme.Ink
	local content = {
		scope:New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		scope:New("UIPadding")({
			PaddingLeft = UDim.new(0, props.PaddingX or 14),
			PaddingRight = UDim.new(0, props.PaddingX or 14),
		}),
	}
	if props.Icon then
		table.insert(
			content,
			Surface.Icon(scope, props.Icon, 16, { LayoutOrder = 1, ImageColor3 = ink })
		)
	end
	if props.Text then
		table.insert(
			content,
			Surface.Label(
				scope,
				{
					Name = "Text",
					LayoutOrder = 2,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, height),
					Text = props.Text,
					TextSize = props.TextSize or 14,
					FontFace = Theme.Title,
					TextColor3 = ink,
					TextTruncate = Enum.TextTruncate.None,
				}
			)
		)
	end
	if props.TrailingIcon then
		table.insert(
			content,
			Surface.Icon(scope, props.TrailingIcon, 14, { LayoutOrder = 3, ImageColor3 = ink })
		)
	end
	return scope:New("TextButton")(
		merge(
			{
				Name = props.Name or "Button",
				LayoutOrder = props.LayoutOrder,
				Visible = props.Visible,
				AnchorPoint = props.AnchorPoint,
				Position = props.Position,
				AutomaticSize = if props.Size then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
				Size = props.Size or UDim2.fromOffset(0, height),
				BackgroundColor3 = Theme.Ink,
				AutoButtonColor = false,
				Text = "",
				[OnEvent("Activated")] = function()
					if props.OnActivated then
						props.OnActivated()
					end
				end,
				[Children] = {
					Surface.Fill(scope, level),
					if ghost then scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) })
						else Surface.Edge(scope, nil, UDim.new(0.5, 0)),
					scope:New("UIScale")({
						Scale = scope:Computed(function(use)
							return 1 - 0.03 * use(interaction.PressT)
						end),
					}),
					content,
				},
			},
			interaction.Events
		)
	)
end

function Controls.IconButton(scope, props)
	local interaction = Surface.Interaction(scope)
	local size = props.Size or 28
	return scope:New("TextButton")(
		merge(
			{
				Name = props.Name or "IconButton",
				LayoutOrder = props.LayoutOrder,
				AnchorPoint = props.AnchorPoint,
				Position = props.Position,
				Size = UDim2.fromOffset(size, size),
				Visible = props.Visible,
				BackgroundColor3 = Theme.Ink,
				BackgroundTransparency = scope:Computed(function(use)
					return 1
						- (props.Rest or 0)
						- 0.08 * use(interaction.HoverT)
						- 0.04 * use(interaction.PressT)
				end),
				AutoButtonColor = false,
				Text = "",
				[OnEvent("Activated")] = function()
					if props.OnActivated then
						props.OnActivated()
					end
				end,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
					Surface.Icon(
						scope,
						props.Icon,
						props.IconSize or 16,
						{
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							ImageColor3 = scope:Computed(function(use)
								return use(Theme.Muted):Lerp(
									use(Theme.Ink),
									use(interaction.HoverT)
								)
							end),
						}
					),
				},
			},
			interaction.Events
		)
	)
end

function Controls.Badge(scope, props)
	local tinted = props.Success or props.Color ~= nil
	local tint = props.Color or (if props.Success then Theme.Success else Theme.Ink)
	return scope:New("Frame")({
		Name = props.Text,
		LayoutOrder = props.LayoutOrder,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundColor3 = tint,
		BackgroundTransparency = 0.9,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
			scope:New("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				Color = tint,
				Transparency = if tinted then 0.75 else 0.92,
			}),
			scope:New("UIPadding")({
				PaddingLeft = UDim.new(0, 7),
				PaddingRight = UDim.new(0, 8),
			}),
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			if props.Icon then Surface.Icon(
					scope,
					props.Icon,
					12,
					{
						ImageColor3 = if tinted then tint else Theme.Ink2,
					}
				)
				else nil,
			Surface.Label(
				scope,
				{
					LayoutOrder = 2,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 20),
					Text = props.Text,
					TextSize = 11,
					FontFace = Theme.Title,
					TextColor3 = if tinted then tint else Theme.Ink2,
					TextTruncate = Enum.TextTruncate.None,
				}
			),
		},
	})
end

return table.freeze(Controls)
