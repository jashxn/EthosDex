local Root = script.Parent.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Motion = require(Root.ui.motion)
local Theme = require(Root.ui.tokens)
local Surface = require(script.Parent.surface)
local Switch = require(script.Parent.switch)

local snap = Motion.Snap
local animate = Motion.Animate

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
local merge = Surface.merge

local Controls = {}

function Controls.Row(scope, props)
	local interaction = Surface.Interaction(scope)
	local disabled = props.Disabled
	local isDisabled = scope:Computed(function(use)
		return disabled ~= nil and use(disabled) ~= nil
	end)
	local switch = props.Switch
	local onT = if switch then animate(
			scope,
			scope:Computed(function(use)
				return if use(switch.On) then 1 else 0
			end),
			snap(0.25)
		)
		else nil
	local description = props.Description
	if disabled ~= nil then
		local base = description
		description = scope:Computed(function(use)
			local reason = use(disabled)
			if reason ~= nil then
				return reason
			end
			return if base ~= nil then use(base) else nil
		end)
	end
	local twoLine = scope:Computed(function(use)
		local text = if description ~= nil then use(description) else nil
		return text ~= nil and text ~= ""
	end)
	local trailing = 14
	if switch then
		trailing += 44
	end
	if props.Chevron then
		trailing += 20
	end
	local left = props.Inset or (if props.Icon then 40 else 14)
	local detailWidth = props.DetailWidth or 120
	local detailRight = (if props.Chevron then 34 else 14) + (if switch then 52 else 0)

	return scope:New("TextButton")(
		merge(
			{
				Name = props.Name or "Row",
				LayoutOrder = props.LayoutOrder,
				Visible = props.Visible,
				Size = scope:Computed(function(use)
					return UDim2.new(1, 0, 0, if use(twoLine) then 54 else 44)
				end),
				BackgroundColor3 = Theme.Ink,
				BackgroundTransparency = scope:Computed(function(use)
					if use(isDisabled) then
						return 1
					end
					return 1 - 0.03 * use(interaction.HoverT) - 0.02 * use(interaction.PressT)
				end),
				AutoButtonColor = false,
				Text = "",
				Selectable = true,
				Interactable = scope:Computed(function(use)
					return not use(isDisabled)
				end),
				[OnEvent("Activated")] = function()
					if props.OnActivated then
						props.OnActivated()
					elseif switch then
						switch.Set(not peek(switch.On))
					end
				end,
				[Children] = {
					if props.Icon then Surface.Icon(
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
									local lit = if onT then use(onT) else 0
									return use(Theme.Muted):Lerp(
										use(Theme.Ink),
										math.max(lit, use(interaction.HoverT) * 0.6)
									)
								end),
							}
						)
						else nil,
					Surface.Label(
						scope,
						{
							Name = "Title",
							Position = scope:Computed(function(use)
								return UDim2.fromOffset(left, if use(twoLine) then 9 else 0)
							end),
							Size = scope:Computed(function(use)
								return UDim2.new(
									1,
									-left - trailing - (if props.Detail then detailWidth else 0),
									0,
									if use(twoLine) then 18 else 44
								)
							end),
							Text = props.Title,
							TextColor3 = scope:Computed(function(use)
								return use(if use(isDisabled) then Theme.Faint else Theme.Ink)
							end),
						}
					),
					Surface.Label(
						scope,
						{
							Name = "Description",
							Visible = twoLine,
							Position = UDim2.fromOffset(left, 28),
							Size = scope:Computed(function(use)
								local detail = if props.Detail and not use(isDisabled) then detailWidth
									else 0
								return UDim2.new(1, -left - trailing - detail, 0, 16)
							end),
							Text = scope:Computed(function(use)
								return if description ~= nil then use(description) or "" else ""
							end),
							TextSize = 13,
							FontFace = Theme.Body,
							TextColor3 = Theme.Muted,
						}
					),
					if props.Detail then Surface.Label(
							scope,
							{
								Name = "Detail",
								Visible = scope:Computed(function(use)
									return not use(isDisabled)
								end),
								AnchorPoint = Vector2.new(1, 0),
								Position = UDim2.new(1, -detailRight, 0, 0),
								Size = UDim2.new(0, detailWidth, 1, 0),
								Text = props.Detail,
								TextSize = 13,
								FontFace = Theme.Title,
								TextColor3 = Theme.Muted,
								TextXAlignment = Enum.TextXAlignment.Right,
							}
						)
						else nil,
					if switch then scope:New("TextButton")({
							Name = "Toggle",
							Visible = scope:Computed(function(use)
								return not use(isDisabled)
							end),
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, if props.Chevron then -28 else -2, 0.5, 0),
							Size = UDim2.fromOffset(52, 40),
							BackgroundTransparency = 1,
							Text = "",
							[OnEvent("Activated")] = function()
								switch.Set(not peek(switch.On))
							end,
							[Children] = Switch.Switch(scope, onT, interaction.PressT),
						})
						else nil,
					if props.Chevron then Surface.Icon(
							scope,
							"chevron-right",
							14,
							{
								Visible = scope:Computed(function(use)
									return not use(isDisabled)
								end),
								AnchorPoint = Vector2.new(1, 0.5),
								Position = UDim2.new(1, -12, 0.5, 0),
								ImageColor3 = Theme.Faint,
							}
						)
						else nil,
				},
			},
			interaction.Events
		)
	)
end

local function divider(scope, row)
	scope:New("Frame")({
		Name = "Divider",
		Parent = row,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = Theme.Ink,
		BackgroundTransparency = Theme.Line,
		BorderSizePixel = 0,
	})
end

function Controls.Group(scope, props)
	local rows = {}
	for index, row in props.Rows do
		row.LayoutOrder = index
		if index > 1 then
			divider(scope, row)
		end
		rows[index] = row
	end
	return scope:New("Frame")({
		Name = props.Name or "Group",
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		[Children] = {
			scope:New("UIListLayout")({
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			if props.Title then Surface.Section(
					scope,
					{ LayoutOrder = 1, Text = props.Title, Inset = 2 }
				)
				else nil,
			scope:New("Frame")({
				Name = "Card",
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				BackgroundColor3 = Theme.Ink,
				ClipsDescendants = true,
				[Children] = {
					Surface.Fill(
						scope,
						scope:Computed(function()
							return 0.05
						end)
					),
					Surface.Edge(scope, nil, UDim.new(0, 14)),
					scope:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
					rows,
				},
			}),
		},
	})
end

function Controls.List(scope, props)
	return scope:New("Frame")({
		Name = props.Name or "List",
		LayoutOrder = props.LayoutOrder,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Theme.Ink,
		ClipsDescendants = true,
		Visible = scope:Computed(function(use)
			return #use(props.Items) > 0
		end),
		[Children] = {
			Surface.Fill(
				scope,
				scope:Computed(function()
					return 0.05
				end)
			),
			Surface.Edge(scope, nil, UDim.new(0, 14)),
			scope:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			scope:ForPairs(
				props.Items,
				function(_, rowScope, index, entry)
					local row = props.Row(rowScope, index, entry)
					row.LayoutOrder = index
					if index > 1 then
						divider(rowScope, row)
					end
					return index, row
				end
			),
		},
	})
end

return table.freeze(Controls)
