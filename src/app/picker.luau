--!nocheck
--[[
	A searchable list in a sheet over the window: Insert Object's classes and long enums.
	options: Title, Items ({ string }), Current?, ClassIcons?, OnPick (string) -> ().
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Scrollbar = require(Root.ui.scrollbar)
local Env = require(Root.core.env)
local State = require(script.Parent.state)
local ClassIcon = require(script.Parent.classIcon)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local UserInputService = Env.service("UserInputService")

local SHOWN = 150
local ITEM = if State.Touch then 36 else 30

local Picker = {}
local layer = nil
local current = nil

function Picker.setLayer(frame: GuiObject)
	layer = frame
end

function Picker.close()
	if current then
		local scope = current
		current = nil
		Fusion.doCleanup(scope)
	end
end

function Picker.open(options)
	Picker.close()
	if layer == nil then
		return
	end
	local scope = Fusion.scoped(Fusion)
	current = scope
	local query = scope:Value("")
	local shown = scope:Computed(function(use)
		local text = string.lower(use(query))
		local list = {}
		for _, item in options.Items do
			if text == "" or string.find(string.lower(item), text, 1, true) then
				table.insert(list, item)
				if #list >= SHOWN then
					break
				end
			end
		end
		return list
	end)

	local function pick(item)
		Picker.close()
		task.spawn(options.OnPick, item)
	end

	local field, box = Controls.Field(
		scope,
		{
			Name = "Filter",
			Text = query,
			Placeholder = "Filter",
			Icon = "search",
			Height = 34,
			OnSubmit = function()
				local first = peek(shown)[1]
				if first then
					pick(first)
				end
			end,
		}
	)
	field.Position = UDim2.fromOffset(12, 52)
	field.Size = UDim2.new(1, -24, 0, 34)

	scope:New("TextButton")({
		Name = "PickerShade",
		Parent = layer,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 400,
		[OnEvent("Activated")] = Picker.close,
		[Children] = scope:New("TextButton")({
			Name = "Sheet",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0.9, 0, 0.8, 0),
			BackgroundColor3 = Theme.Surface,
			AutoButtonColor = false,
			Text = "",
			[Children] = {
				scope:New("UISizeConstraint")({ MaxSize = Vector2.new(380, 480) }),
				scope:New("UICorner")({ CornerRadius = UDim.new(0, 16) }),
				scope:New("UIStroke")({
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Theme.Ink,
					Transparency = 0.86,
				}),
				Controls.Label(
					scope,
					{
						Position = UDim2.fromOffset(16, 0),
						Size = UDim2.new(1, -60, 0, 48),
						Text = options.Title,
						TextSize = 14,
					}
				),
				Controls.IconButton(
					scope,
					{
						Name = "Close",
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, -10, 0, 10),
						Icon = "x",
						Size = 28,
						OnActivated = Picker.close,
					}
				),
				field,
				Scrollbar.attach(
					scope,
					scope:New("ScrollingFrame")({
						Name = "Items",
						Position = UDim2.fromOffset(8, 94),
						Size = UDim2.new(1, -16, 1, -102),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						CanvasSize = UDim2.new(),
						ScrollingDirection = Enum.ScrollingDirection.Y,
						[Children] = {
							scope:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
							scope:ForValues(
								shown,
								function(_, itemScope, item)
									local interaction = Controls.Interaction(itemScope)
									local picked = item == options.Current
									return itemScope:New("TextButton")(
										Controls.merge(
											{
												Name = item,
												LayoutOrder = table.find(peek(shown), item) or 0,
												Size = UDim2.new(1, 0, 0, ITEM),
												BackgroundColor3 = if picked then Theme.Accent
													else Theme.Ink,
												BackgroundTransparency = itemScope:Computed(function(
													use
												)
													return if picked then 0.8
														else 1 - 0.07 * use(interaction.HoverT)
												end),
												AutoButtonColor = false,
												Text = "",
												[OnEvent("Activated")] = function()
													pick(item)
												end,
												[Children] = {
													itemScope:New("UICorner")({
														CornerRadius = UDim.new(0, 8),
													}),
													if options.ClassIcons then ClassIcon.new(
															itemScope,
															item,
															{
																AnchorPoint = Vector2.new(0, 0.5),
																Position = UDim2.new(0, 10, 0.5, 0),
															}
														)
														else nil,
													Controls.Label(
														itemScope,
														{
															Position = UDim2.fromOffset(
																if options.ClassIcons then 34
																	else 12,
																0
															),
															Size = UDim2.new(1, -46, 1, 0),
															Text = item,
															TextSize = 13,
															FontFace = Theme.Body,
														}
													),
												},
											},
											interaction.Events
										)
									)
								end
							),
						},
					})
				),
			},
		}),
	})
	table.insert(
		scope,
		UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Escape then
				Picker.close()
			end
		end)
	)
	if not State.Touch then
		task.defer(function()
			if current == scope then
				box:CaptureFocus()
			end
		end)
	end
end

return Picker
