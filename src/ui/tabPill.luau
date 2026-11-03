local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Theme = require(Root.ui.tokens)
local Controls = require(Root.ui.controls)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local function pill(scope, title: string, order: number, selected, onSelect)
	local interaction = Controls.Interaction(scope)
	local selectedT = Controls.animate(
		scope,
		scope:Computed(function(use)
			return if use(selected) then 1 else 0
		end),
		Controls.soft(0.18)
	)
	local edge = Controls.Edge(scope, selectedT, UDim.new(0, 9))
	scope:Hydrate(edge[2])({
		Transparency = scope:Computed(function(use)
			return 1 - use(selectedT)
		end),
	})
	return scope:New("TextButton")(
		Controls.merge(
			{
				Name = title,
				LayoutOrder = order,
				Size = UDim2.fromOffset(0, 30),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Theme.Ink,
				AutoButtonColor = false,
				Text = "",
				[OnEvent("Activated")] = onSelect,
				[Children] = {
					Controls.Fill(
						scope,
						scope:Computed(function(use)
							local sel = use(selectedT)
							return 0.075 * sel + 0.04 * use(interaction.HoverT) * (1 - sel)
						end)
					),
					edge,
					scope:New("UIPadding")({
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 12),
					}),
					Controls.Label(
						scope,
						{
							Name = "Sizer",
							Size = UDim2.fromOffset(0, 30),
							AutomaticSize = Enum.AutomaticSize.X,
							Text = title,
							TextSize = 13,
							FontFace = Theme.Title,
							TextTransparency = 1,
							TextTruncate = Enum.TextTruncate.None,
						}
					),
					Controls.Label(
						scope,
						{
							Name = "Title",
							Size = UDim2.fromScale(1, 1),
							Text = title,
							TextSize = 13,
							TextXAlignment = Enum.TextXAlignment.Center,
							FontFace = scope:Computed(function(use)
								return if use(selected) then Theme.Title else Theme.Body
							end),
							TextColor3 = scope:Computed(function(use)
								return use(Theme.Muted):Lerp(
									use(Theme.Ink),
									math.max(use(selectedT), use(interaction.HoverT) * 0.6)
								)
							end),
							TextTruncate = Enum.TextTruncate.None,
						}
					),
				},
			},
			interaction.Events
		)
	)
end

return pill
