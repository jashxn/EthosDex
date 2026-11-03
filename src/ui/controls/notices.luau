local Root = script.Parent.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Theme = require(Root.ui.tokens)
local Surface = require(script.Parent.surface)
local Buttons = require(script.Parent.buttons)

local Children = Fusion.Children

local Controls = {}

function Controls.Banner(scope, props)
	local actions = {}
	for index, action in props.Actions or {} do
		actions[index] = Buttons.Button(
			scope,
			{
				Name = action.Text,
				LayoutOrder = index,
				Text = action.Text,
				Height = 28,
				TextSize = 13,
				PaddingX = 12,
				Ghost = action.Ghost,
				OnActivated = action.OnActivated,
			}
		)
	end
	return scope:New("Frame")({
		Name = props.Name or "Banner",
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Theme.Ink,
		[Children] = {
			Surface.Fill(
				scope,
				scope:Computed(function()
					return 0.08
				end)
			),
			Surface.Edge(scope, nil, UDim.new(0, 14)),
			Surface.Icon(
				scope,
				props.Icon or "info",
				16,
				{
					Position = UDim2.fromOffset(14, 13),
					ImageColor3 = props.Ink or Theme.Ink2,
				}
			),
			scope:New("Frame")({
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				BackgroundTransparency = 1,
				[Children] = {
					scope:New("UIPadding")({
						PaddingTop = UDim.new(0, 12),
						PaddingBottom = UDim.new(0, 12),
						PaddingLeft = UDim.new(0, 40),
						PaddingRight = UDim.new(0, 14),
					}),
					scope:New("UIListLayout")({
						Padding = UDim.new(0, 10),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Surface.Label(
						scope,
						{
							Name = "Text",
							LayoutOrder = 1,
							AutomaticSize = Enum.AutomaticSize.Y,
							Size = UDim2.fromScale(1, 0),
							Text = props.Text,
							TextSize = 13,
							FontFace = Theme.Body,
							TextColor3 = Theme.Ink2,
							TextWrapped = true,
							TextTruncate = Enum.TextTruncate.None,
							LineHeight = 1.15,
						}
					),
					if #actions > 0 then scope:New("Frame")({
							Name = "Actions",
							LayoutOrder = 2,
							Size = UDim2.new(1, 0, 0, 28),
							BackgroundTransparency = 1,
							[Children] = {
								scope:New("UIListLayout")({
									FillDirection = Enum.FillDirection.Horizontal,
									Padding = UDim.new(0, 8),
									SortOrder = Enum.SortOrder.LayoutOrder,
								}),
								actions,
							},
						})
						else nil,
				},
			}),
		},
	})
end

function Controls.Empty(scope, props)
	return scope:New("Frame")({
		Name = props.Name or "Empty",
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		[Children] = {
			scope:New("UIPadding")({
				PaddingTop = UDim.new(0, 20),
				PaddingBottom = UDim.new(0, 20),
			}),
			scope:New("UIListLayout")({
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Surface.Icon(
				scope,
				props.Icon or "info",
				20,
				{ LayoutOrder = 1, ImageColor3 = Theme.Muted }
			),
			Surface.Label(
				scope,
				{
					Name = "Title",
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 18),
					Text = props.Title,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Center,
				}
			),
			if props.Text then Surface.Label(
					scope,
					{
						Name = "Text",
						LayoutOrder = 3,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, -40, 0, 0),
						Text = props.Text,
						TextSize = 13,
						FontFace = Theme.Body,
						TextColor3 = Theme.Muted,
						TextWrapped = true,
						TextTruncate = Enum.TextTruncate.None,
						TextXAlignment = Enum.TextXAlignment.Center,
					}
				)
				else nil,
			if props.Action then Buttons.Button(
					scope,
					{
						Name = "Action",
						LayoutOrder = 4,
						Text = props.Action.Text,
						Icon = props.Action.Icon,
						Height = 30,
						TextSize = 13,
						OnActivated = props.Action.OnActivated,
					}
				)
				else nil,
		},
	})
end

return table.freeze(Controls)
