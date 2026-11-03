--!nocheck
--[[
	The window: Ethos's two-layer body with the explorer on the left and the inset panel on the
	right, a splitter between them, dragging by either header, a corner grip to resize, maximize,
	and minimize to a floating bubble (the only way back on touch, where there's no keybind).
	Below 720px wide it becomes a phone layout: full screen, one column at a time.

	props: Layer, Explorer (frame), Panel (frame), Title (frame for the panel topbar's left),
	Actions (frame for its right), OnClose.
	Returns { Instance, Open (Value), Maximized (Value), Toggle (), DragHandles (fn) }.
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Icons = require(Root.ui.icons.dock)
local Pointer = require(Root.ui.pointer)
local Settings = require(Root.core.settings)
local State = require(script.Parent.state)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local RADIUS = 18
local INSET = 8
local MIN = Vector2.new(560, 360)
local COMPACT_WIDTH = 720
local EXPLORER_MIN, EXPLORER_MAX = 200, 520
local LOW_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.7, 1),
	NumberSequenceKeypoint.new(0.85, 0.55),
	NumberSequenceKeypoint.new(1, 0.1),
})

local Window = {}

function Window.new(scope, props)
	local layer = props.Layer
	local room = scope:Value(layer.AbsoluteSize)
	table.insert(
		scope,
		layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			room:set(layer.AbsoluteSize)
		end)
	)

	local compact = State.Compact
	local function updateCompact()
		compact:set(peek(room).X < COMPACT_WIDTH)
	end
	updateCompact()
	table.insert(scope, scope:Observer(room):onChange(updateCompact))

	local open = scope:Value(true)
	local maximized = scope:Value(false)
	local size = scope:Value(Vector2.new(Settings.get("WindowWidth"), Settings.get("WindowHeight")))
	local offset = scope:Value(nil) -- top-left; nil centres it
	local explorerWidth = scope:Value(Settings.get("ExplorerWidth"))

	local function clampSize(want: Vector2): Vector2
		local space = peek(room)
		return Vector2.new(
			math.clamp(want.X, MIN.X, math.max(MIN.X, space.X - 16)),
			math.clamp(want.Y, MIN.Y, math.max(MIN.Y, space.Y - 16))
		)
	end

	-- The window's rectangle as drawn: phone and maximized fill the room.
	local rect = scope:Computed(function(use)
		local space = use(room)
		if use(compact) then
			return { At = Vector2.new(6, 6), Size = space - Vector2.new(12, 12) }
		elseif use(maximized) then
			return { At = Vector2.new(12, 12), Size = space - Vector2.new(24, 24) }
		end
		local shown = Vector2.new(
			math.clamp(use(size).X, MIN.X, math.max(MIN.X, space.X - 16)),
			math.clamp(use(size).Y, MIN.Y, math.max(MIN.Y, space.Y - 16))
		)
		local at = use(offset) or (space - shown) / 2
		at = Vector2.new(
			math.clamp(at.X, 8 - shown.X + 120, space.X - 120),
			math.clamp(at.Y, 0, space.Y - 48)
		)
		return { At = at, Size = shown }
	end)
	local rectPosition = scope:Computed(function(use)
		local at = use(rect).At
		return UDim2.fromOffset(math.round(at.X), math.round(at.Y))
	end)
	local rectSize = scope:Computed(function(use)
		local shown = use(rect).Size
		return UDim2.fromOffset(math.round(shown.X), math.round(shown.Y))
	end)

	-- Explorer width as drawn; on phones each column takes the whole window.
	local leftWidth = scope:Computed(function(use)
		local shown = use(rect).Size
		if use(compact) then
			return if use(State.MobileView) == "explorer" then shown.X else 0
		end
		return math.clamp(use(explorerWidth), EXPLORER_MIN, math.min(EXPLORER_MAX, shown.X - 320))
	end)

	local function beginDrag(input)
		if not Pointer.isPress(input) or peek(compact) or peek(maximized) then
			return
		end
		local start = Vector2.new(input.Position.X, input.Position.Y)
		local origin = peek(rect).At
		Pointer.drag(
			scope,
			function(point)
				offset:set(origin + (point - start) / props.Scale())
			end
		)
	end

	local function dragHandle(frame: GuiObject)
		table.insert(scope, frame.InputBegan:Connect(beginDrag))
	end

	local grip = scope:New("TextButton")({
		Name = "ResizeGrip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 20,
		Visible = scope:Computed(function(use)
			return not use(compact) and not use(maximized)
		end),
		[OnEvent("InputBegan")] = function(input)
			if not Pointer.isPress(input) then
				return
			end
			local start = Vector2.new(input.Position.X, input.Position.Y)
			local at, startSize = peek(rect).At, peek(rect).Size
			offset:set(at)
			Pointer.drag(
				scope,
				function(point)
					size:set(clampSize(startSize + (point - start) / props.Scale()))
				end,
				function()
					local final = peek(size)
					Settings.set("WindowWidth", math.round(final.X))
					Settings.set("WindowHeight", math.round(final.Y))
				end
			)
		end,
		[Children] = Controls.Icon(
			scope,
			"grip-vertical",
			12,
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Rotation = -45,
				ImageColor3 = Theme.Faint,
			}
		),
	})

	local splitterHover = scope:Value(false)
	local splitter = scope:New("TextButton")({
		Name = "Splitter",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Computed(function(use)
			return UDim2.new(0, use(leftWidth) + INSET / 2, 0, 0)
		end),
		Size = UDim2.new(0, 8, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Visible = scope:Computed(function(use)
			return not use(compact)
		end),
		[OnEvent("MouseEnter")] = function()
			splitterHover:set(true)
		end,
		[OnEvent("MouseLeave")] = function()
			splitterHover:set(false)
		end,
		[OnEvent("InputBegan")] = function(input)
			if not Pointer.isPress(input) then
				return
			end
			local start = input.Position.X
			local from = peek(leftWidth)
			Pointer.drag(
				scope,
				function(point)
					explorerWidth:set(
						math.clamp(
							from + (point.X - start) / props.Scale(),
							EXPLORER_MIN,
							EXPLORER_MAX
						)
					)
				end,
				function()
					Settings.set("ExplorerWidth", math.round(peek(explorerWidth)))
				end
			)
		end,
		[Children] = scope:New("Frame")({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 2, 0, 36),
			BackgroundColor3 = Theme.Ink,
			BackgroundTransparency = scope:Computed(function(use)
				return if use(splitterHover) then 0.7 else 1
			end),
			[Children] = scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
		}),
	})

	local explorer = scope:Hydrate(props.Explorer)({
		Position = UDim2.fromOffset(0, 0),
		Size = scope:Computed(function(use)
			return UDim2.new(0, use(leftWidth), 1, 0)
		end),
		Visible = scope:Computed(function(use)
			return not use(compact) or use(State.MobileView) == "explorer"
		end),
	})

	local panelVisible = scope:Computed(function(use)
		return not use(compact) or use(State.MobileView) == "panel"
	end)
	local panel = scope:New("Frame")({
		Name = "Panel",
		Position = scope:Computed(function(use)
			return UDim2.fromOffset(if use(compact) then INSET else use(leftWidth), INSET)
		end),
		Size = scope:Computed(function(use)
			local left = if use(compact) then INSET else use(leftWidth)
			return UDim2.new(1, -left - INSET, 1, -INSET * 2)
		end),
		BackgroundColor3 = Theme.Ink,
		Visible = panelVisible,
		ClipsDescendants = true,
		[Children] = {
			Controls.Fill(scope, scope:Value(0.03)),
			Controls.Edge(scope, scope:Value(0.5), UDim.new(0, 14)),
			props.Panel,
		},
	})

	local frame = scope:New("Frame")({
		Name = "EthosDex",
		Parent = layer,
		Position = rectPosition,
		Size = rectSize,
		BackgroundTransparency = 1,
		Visible = open,
		ZIndex = 10,
		[Children] = {
			scope:New("ImageLabel")({
				Name = "Shadow",
				Position = UDim2.fromOffset(-12, -8),
				Size = UDim2.new(1, 24, 1, 24),
				BackgroundTransparency = 1,
				Image = Icons.shadow,
				ImageColor3 = Color3.new(0, 0, 0),
				ImageTransparency = 0.6,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(164, 164, 166, 166),
				SliceScale = 0.25,
			}),
			scope:New("Frame")({
				Name = "Body",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.Surface,
				ClipsDescendants = true,
				BorderSizePixel = 0,
				Active = true,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0, RADIUS) }),
					scope:New("Frame")({
						Name = "Low",
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Theme.SurfaceLow,
						BorderSizePixel = 0,
						[Children] = {
							scope:New("UICorner")({ CornerRadius = UDim.new(0, RADIUS) }),
							scope:New("UIGradient")({ Rotation = 90, Transparency = LOW_FADE }),
						},
					}),
					explorer,
					panel,
					splitter,
					grip,
				},
			}),
			scope:New("Frame")({
				Name = "Rim",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 3,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0, RADIUS) }),
					scope:New("UIStroke")({
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						BorderStrokePosition = Enum.BorderStrokePosition.Inner,
						Color = Theme.Ink,
						Transparency = 0.9,
						[Children] = scope:New("UIGradient")({
							Rotation = 90,
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0),
								NumberSequenceKeypoint.new(0.4, 0.5),
								NumberSequenceKeypoint.new(1, 0.8),
							}),
						}),
					}),
				},
			}),
		},
	})

	-- The floating bubble: shown while the window is hidden; drag it anywhere, tap to reopen.
	local bubbleAt = scope:Value(nil)
	local bubbleMoved = false
	scope:New("TextButton")({
		Name = "Bubble",
		Parent = layer,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = scope:Computed(function(use)
			local at = use(bubbleAt)
			local space = use(room)
			at = at or Vector2.new(space.X - 40, space.Y * 0.35)
			return UDim2.fromOffset(
				math.clamp(at.X, 24, space.X - 24),
				math.clamp(at.Y, 24, space.Y - 24)
			)
		end),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = Theme.Surface,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 50,
		Visible = scope:Computed(function(use)
			return not use(open)
		end),
		[OnEvent("InputBegan")] = function(input)
			if not Pointer.isPress(input) then
				return
			end
			bubbleMoved = false
			local start = Vector2.new(input.Position.X, input.Position.Y)
			local space = peek(room)
			local origin = peek(bubbleAt) or Vector2.new(space.X - 40, space.Y * 0.35)
			Pointer.drag(
				scope,
				function(point)
					local delta = (point - start) / props.Scale()
					if delta.Magnitude > 6 then
						bubbleMoved = true
					end
					bubbleAt:set(origin + delta)
				end
			)
		end,
		[OnEvent("Activated")] = function()
			if not bubbleMoved then
				open:set(true)
			end
		end,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
			scope:New("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Theme.Ink,
				Transparency = 0.82,
			}),
			Controls.Icon(
				scope,
				"ethos-e",
				22,
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				}
			),
		},
	})

	return {
		Instance = frame,
		Panel = panel,
		Open = open,
		Maximized = maximized,
		Toggle = function()
			open:set(not peek(open))
		end,
		DragHandle = dragHandle,
	}
end

return Window
