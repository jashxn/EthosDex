--!nocheck
-- Cards at the top of the screen for modes that outlast a click, each with a way out: viewing an
-- object (the camera follows it) and pick mode. Escape cancels pick mode.

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Env = require(Root.core.env)
local State = require(script.Parent.state)
local Actions = require(script.Parent.actions)

local Children = Fusion.Children
local peek = Fusion.peek

local UserInputService = Env.service("UserInputService")

local Activity = {}

local function card(scope, props)
	return scope:New("Frame")({
		Name = props.Name,
		LayoutOrder = props.Order,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Surface,
		Visible = props.Visible,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 12) }),
			scope:New("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Theme.Ink,
				Transparency = 0.86,
			}),
			scope:New("UIPadding")({
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 4),
			}),
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Controls.Icon(scope, props.Icon, 16, { LayoutOrder = 1, ImageColor3 = Theme.Accent }),
			Controls.Label(
				scope,
				{
					LayoutOrder = 2,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 40),
					Text = props.Text,
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					[Children] = scope:New("UISizeConstraint")({ MaxSize = Vector2.new(260, 40) }),
				}
			),
			props.Buttons,
		},
	})
end

function Activity.new(scope, layer)
	local function button(text, order, onActivated)
		return Controls.Button(
			scope,
			{
				Name = text,
				Text = text,
				Height = 30,
				TextSize = 13,
				PaddingX = 10,
				LayoutOrder = order,
				OnActivated = onActivated,
			}
		)
	end

	scope:New("Frame")({
		Name = "Activity",
		Parent = layer,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		ZIndex = 60,
		[Children] = {
			scope:New("UIListLayout")({
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			card(
				scope,
				{
					Name = "Viewing",
					Order = 1,
					Icon = "eye",
					Visible = scope:Computed(function(use)
						return use(State.Viewing) ~= nil
					end),
					Text = scope:Computed(function(use)
						local object = use(State.Viewing)
						local ok, name = pcall(function()
							return object.Name
						end)
						return "Viewing " .. (if ok then name else "")
					end),
					Buttons = {
						button(
							"Select",
							3,
							function()
								local object = peek(State.Viewing)
								if object then
									State.Hooks.reveal(object)
								end
							end
						),
						button("Stop", 4, Actions.stopViewing),
					},
				}
			),
			card(
				scope,
				{
					Name = "Picking",
					Order = 2,
					Icon = "crosshair",
					Visible = State.Picking,
					Text = "Click a part in the world to select it",
					Buttons = button(
						"Cancel",
						3,
						function()
							State.Picking:set(false)
						end
					),
				}
			),
		},
	})

	table.insert(
		scope,
		UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Escape and peek(State.Picking) then
				State.Picking:set(false)
			end
		end)
	)
end

return Activity
