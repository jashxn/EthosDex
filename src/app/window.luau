--!nocheck
--[[
	The floating window that holds Script, Console, Preview and Settings, like Dex's app windows,
	and `chrome`, the Ethos body (shadow, two layers, rim) it shares with the dock.

	Window.new props: Layer, Room (Value of the layer's size), Content (frame), Reserve (Computed: px on
	the right taken by the dock), Shown (Computed: the app is visible), Scale ().
	Returns { Instance, Maximized (Value), DragHandle (fn) }. State.WindowOpen opens and closes it.
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
local MIN = Vector2.new(420, 300)
local LOW_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.7, 1),
	NumberSequenceKeypoint.new(0.85, 0.55),
	NumberSequenceKeypoint.new(1, 0.1),
})

local Window = {}

-- props: Name, Position, Size, Visible, ZIndex, Children (inside the body).
function Window.chrome(scope, props)
	local clear = scope:Computed(function(use)
		return 1 - math.clamp(use(Settings.state("PanelOpacity")), 0.3, 1)
	end)
	return scope:New("Frame")({
		Name = props.Name,
		Parent = props.Parent,
		Position = props.Position,
		Size = props.Size,
		BackgroundTransparency = 1,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		[Children] = {
			scope:New("ImageLabel")({
				Name = "Shadow",
				Position = UDim2.fromOffset(-12, -8),
				Size = UDim2.new(1, 24, 1, 24),
				BackgroundTransparency = 1,
				Image = Icons.shadow,
				ImageColor3 = Color3.new(0, 0, 0),
				ImageTransparency = scope:Computed(function(use)
					return 0.6 + 0.4 * use(clear)
				end),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(164, 164, 166, 166),
				SliceScale = 0.25,
			}),
			scope:New("Frame")({
				Name = "Body",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.Surface,
				BackgroundTransparency = clear,
				ClipsDescendants = true,
				BorderSizePixel = 0,
				Active = true,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0, RADIUS) }),
					scope:New("Frame")({
						Name = "Low",
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Theme.SurfaceLow,
						BackgroundTransparency = clear,
						BorderSizePixel = 0,
						[Children] = {
							scope:New("UICorner")({ CornerRadius = UDim.new(0, RADIUS) }),
							scope:New("UIGradient")({ Rotation = 90, Transparency = LOW_FADE }),
						},
					}),
					props.Children,
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
end

function Window.new(scope, props)
	local room = props.Room
	local compact = State.Compact
	local maximized = scope:Value(false)
	local size = scope:Value(Vector2.new(Settings.get("WindowWidth"), Settings.get("WindowHeight")))
	local offset = scope:Value(nil) -- top-left; nil centres it in the space left of the dock

	local function clampSize(want: Vector2): Vector2
		local space = peek(room)
		return Vector2.new(
			math.clamp(want.X, MIN.X, math.max(MIN.X, space.X - 16)),
			math.clamp(want.Y, MIN.Y, math.max(MIN.Y, space.Y - 16))
		)
	end

	-- The window's rectangle as drawn: phone fills the screen, maximized fills what the dock leaves.
	local rect = scope:Computed(
		function(use)
			local space = use(room)
			local reserve = use(props.Reserve)
			local free = Vector2.new(math.max(MIN.X + 24, space.X - reserve), space.Y)
			-- The free space starts after the dock when it's on the left.
			local origin = Vector2.new(
				if use(Settings.state("DockSide")) == "Left" then reserve else 0,
				0
			)
			if use(compact) then
				return { At = Vector2.new(6, 6), Size = space - Vector2.new(12, 12) }
			elseif use(maximized) then
				return { At = origin + Vector2.new(12, 12), Size = free - Vector2.new(24, 24) }
			end
			local shown = Vector2.new(
				math.clamp(use(size).X, MIN.X, math.max(MIN.X, free.X - 24)),
				math.clamp(use(size).Y, MIN.Y, math.max(MIN.Y, space.Y - 16))
			)
			local at = use(offset) or origin + (free - shown) / 2
			at = Vector2.new(
				math.clamp(at.X, 8 - shown.X + 120, space.X - 120),
				math.clamp(at.Y, 0, space.Y - 48)
			)
			return { At = at, Size = shown }
		end
	)

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

	local frame = Window.chrome(
		scope,
		{
			Name = "Window",
			Parent = props.Layer,
			Position = scope:Computed(function(use)
				local at = use(rect).At
				return UDim2.fromOffset(math.round(at.X), math.round(at.Y))
			end),
			Size = scope:Computed(function(use)
				local shown = use(rect).Size
				return UDim2.fromOffset(math.round(shown.X), math.round(shown.Y))
			end),
			Visible = scope:Computed(function(use)
				return use(State.WindowOpen) and use(props.Shown)
			end),
			ZIndex = 12,
			Children = { props.Content, grip },
		}
	)

	return {
		Instance = frame,
		Maximized = maximized,
		DragHandle = function(handle: GuiObject)
			table.insert(scope, handle.InputBegan:Connect(beginDrag))
		end,
	}
end

return Window
