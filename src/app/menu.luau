--!nocheck
--[[
	A context menu at a screen point, kept on screen, closed by any press outside it, Escape, or
	choosing an item. Long lists scroll. Items: { Text, Icon?, Danger?, Disabled? (reason),
	Detail?, OnActivated } or "divider".
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Scrollbar = require(Root.ui.scrollbar)
local Env = require(Root.core.env)
local State = require(script.Parent.state)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local UserInputService = Env.service("UserInputService")

local ITEM = if State.Touch then 36 else 30
local WIDTH = 220
local MAX_HEIGHT = 600

local Menu = {}
local current = nil
local layer = nil
local layerScale = function()
	return 1
end

-- The full-screen frame menus open in, and its UI scale.
function Menu.setLayer(frame: GuiObject, getScale: () -> number)
	layer = frame
	layerScale = getScale
end

function Menu.close()
	if current then
		local scope = current
		current = nil
		Fusion.doCleanup(scope)
	end
end

function Menu.isOpen(): boolean
	return current ~= nil
end

local function item(scope, entry, order)
	if entry == "divider" then
		return scope:New("Frame")({
			Name = "Divider",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 9),
			BackgroundTransparency = 1,
			[Children] = scope:New("Frame")({
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.new(1, -16, 0, 1),
				BackgroundColor3 = Theme.Ink,
				BackgroundTransparency = Theme.Line,
				BorderSizePixel = 0,
			}),
		})
	end
	local interaction = Controls.Interaction(scope)
	local disabled = entry.Disabled ~= nil
	local ink = if disabled then Theme.Faint elseif entry.Danger then Theme.Danger else Theme.Ink
	return scope:New("TextButton")(
		Controls.merge(
			{
				Name = entry.Text,
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, ITEM),
				BackgroundColor3 = Theme.Ink,
				BackgroundTransparency = scope:Computed(function(use)
					return if disabled then 1 else 1 - 0.07 * use(interaction.HoverT)
				end),
				AutoButtonColor = false,
				Text = "",
				[OnEvent("Activated")] = function()
					if disabled then
						return
					end
					Menu.close()
					task.spawn(entry.OnActivated)
				end,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
					if entry.Icon then Controls.Icon(
							scope,
							entry.Icon,
							15,
							{
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.new(0, 10, 0.5, 0),
								ImageColor3 = if disabled then Theme.Faint
									elseif entry.Danger then Theme.Danger
									else Theme.Ink2,
							}
						)
						else nil,
					Controls.Label(
						scope,
						{
							Position = UDim2.fromOffset(if entry.Icon then 34 else 12, 0),
							Size = UDim2.new(1, -(if entry.Icon then 34 else 12) - 10, 1, 0),
							Text = entry.Text,
							TextSize = 13,
							FontFace = Theme.Body,
							TextColor3 = ink,
						}
					),
					if entry.Detail or entry.Disabled then Controls.Label(
							scope,
							{
								AnchorPoint = Vector2.new(1, 0),
								Position = UDim2.new(1, -10, 0, 0),
								Size = UDim2.new(0.5, 0, 1, 0),
								Text = entry.Detail or "",
								TextSize = 11,
								FontFace = Theme.Body,
								TextColor3 = Theme.Faint,
								TextXAlignment = Enum.TextXAlignment.Right,
							}
						)
						else nil,
				},
			},
			interaction.Events
		)
	)
end

-- position: screen point (absolute, before the layer's UIScale).
function Menu.open(position: Vector2, entries)
	Menu.close()
	if layer == nil or #entries == 0 then
		return
	end
	local scope = Fusion.scoped(Fusion)
	current = scope
	local height = 8
	for _, entry in entries do
		height += if entry == "divider" then 9 else ITEM
	end
	-- The layer is full screen under the UI scale: screen points divide by it.
	local room = layer.AbsoluteSize
	local scale = layerScale()
	local shown = math.min(height, MAX_HEIGHT, room.Y / scale - 16)
	local point = (position - layer.AbsolutePosition) / scale
	local x = math.clamp(point.X, 4, math.max(4, room.X / scale - WIDTH - 4))
	local y = point.Y
	if y + shown > room.Y / scale - 4 then
		y = math.max(4, y - shown)
	end

	local children = {}
	for index, entry in entries do
		table.insert(children, item(scope, entry, index))
	end
	local menuFrame = nil
	local function inside(input): boolean
		local frame = menuFrame
		if frame == nil then
			return false
		end
		local p, at, size = input.Position, frame.AbsolutePosition, frame.AbsoluteSize
		return p.X >= at.X and p.X <= at.X + size.X and p.Y >= at.Y and p.Y <= at.Y + size.Y
	end

	local dismiss = scope:New("TextButton")({
		Name = "MenuDismiss",
		Parent = layer,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 500,
		[OnEvent("InputBegan")] = function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.Touch then
				if not inside(input) then
					Menu.close()
				end
			end
		end,
		[Children] = scope:New("Frame")({
			Name = "Menu",
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(WIDTH, shown),
			BackgroundColor3 = Theme.Surface,
			Active = true,
			ZIndex = 501,
			[Children] = {
				scope:New("UICorner")({ CornerRadius = UDim.new(0, 12) }),
				scope:New("UIStroke")({
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Theme.Ink,
					Transparency = 0.88,
				}),
				Scrollbar.attach(
					scope,
					scope:New("ScrollingFrame")({
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						CanvasSize = UDim2.fromOffset(0, height),
						ScrollingDirection = Enum.ScrollingDirection.Y,
						[Children] = {
							scope:New("UIPadding")({
								PaddingTop = UDim.new(0, 4),
								PaddingBottom = UDim.new(0, 4),
								PaddingLeft = UDim.new(0, 4),
								PaddingRight = UDim.new(0, 4),
							}),
							scope:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
							children,
						},
					})
				),
			},
		}),
	})
	menuFrame = dismiss:FindFirstChild("Menu")
	table.insert(
		scope,
		UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Escape then
				Menu.close()
			end
		end)
	)
end

-- Right click, or a long press on touch, on `button` calls `onMenu(screenPoint)`.
function Menu.bind(button: GuiObject, onMenu: (Vector2) -> ()): { RBXScriptConnection }
	local connections = {}
	local pressId = 0
	table.insert(
		connections,
		button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				onMenu(Vector2.new(input.Position.X, input.Position.Y))
			elseif input.UserInputType == Enum.UserInputType.Touch then
				pressId += 1
				local mine = pressId
				local start = Vector2.new(input.Position.X, input.Position.Y)
				task.delay(
					0.45,
					function()
						if pressId == mine and input.UserInputState ~= Enum.UserInputState.End then
							local now = Vector2.new(input.Position.X, input.Position.Y)
							if (now - start).Magnitude < 12 then
								pressId += 1
								Menu.longPressed = os.clock()
								onMenu(now)
							end
						end
					end
				)
			end
		end)
	)
	table.insert(
		connections,
		button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				pressId += 1
			end
		end)
	)
	return connections
end

-- True right after a long press opened a menu, so the tap that ends it isn't also a click.
function Menu.justLongPressed(): boolean
	return Menu.longPressed ~= nil and os.clock() - Menu.longPressed < 0.6
end

return Menu
