--!nocheck
--[[
	Dex's layout: one panel docked to the right edge, the explorer on top and the properties
	below, a splitter between them and a grip on the left edge to widen it. On phones it takes the
	screen's width. Hidden, it leaves a floating bubble (the only way back on touch).

	props: Layer, Room (Value of the layer's size), Explorer (frame), Properties (frame),
	Footer (frame), Scale ().
	Returns { Instance, Open (Value), Toggle (), Reserve (Computed: px it takes on the right) }.
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Pointer = require(Root.ui.pointer)
local Settings = require(Root.core.settings)
local State = require(script.Parent.state)
local Window = require(script.Parent.window)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local MARGIN = 8
local INSET = 8
local FOOTER = 56
local WIDTH_MIN = 260
local SECTION_MIN = 120

local Dock = {}

function Dock.new(scope, props)
	local room = props.Room
	local compact = State.Compact
	local open = scope:Value(true)
	local width = scope:Value(Settings.get("DockWidth"))
	local split = scope:Value(Settings.get("DockSplit"))

	local shownWidth = scope:Computed(function(use)
		local space = use(room)
		if use(compact) then
			return space.X - MARGIN * 2
		end
		return math.clamp(use(width), WIDTH_MIN, math.max(WIDTH_MIN, space.X * 0.6))
	end)
	local height = scope:Computed(function(use)
		return use(room).Y - MARGIN * 2
	end)
	-- The explorer's height; the properties get the rest above the footer.
	local topHeight = scope:Computed(function(use)
		local free = use(height) - FOOTER
		return math.round(
			math.clamp(
				use(split) * free,
				SECTION_MIN,
				math.max(SECTION_MIN, free - SECTION_MIN - INSET)
			)
		)
	end)

	local function hoverLine(hover, size)
		return scope:New("Frame")({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = size,
			BackgroundColor3 = Theme.Ink,
			BackgroundTransparency = scope:Computed(function(use)
				return if use(hover) then 0.7 else 1
			end),
			[Children] = scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
		})
	end

	local edgeHover = scope:Value(false)
	local edge = scope:New("TextButton")({
		Name = "WidthGrip",
		Size = UDim2.new(0, 8, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 20,
		Visible = scope:Computed(function(use)
			return not use(compact)
		end),
		[OnEvent("MouseEnter")] = function()
			edgeHover:set(true)
		end,
		[OnEvent("MouseLeave")] = function()
			edgeHover:set(false)
		end,
		[OnEvent("InputBegan")] = function(input)
			if not Pointer.isPress(input) then
				return
			end
			local start = input.Position.X
			local from = peek(shownWidth)
			Pointer.drag(
				scope,
				function(point)
					-- Docked to the right, so dragging left widens it.
					width:set(math.max(WIDTH_MIN, from - (point.X - start) / props.Scale()))
				end,
				function()
					Settings.set("DockWidth", math.round(peek(shownWidth)))
				end
			)
		end,
		[Children] = hoverLine(edgeHover, UDim2.new(0, 2, 0, 36)),
	})

	local splitHover = scope:Value(false)
	local splitter = scope:New("TextButton")({
		Name = "Splitter",
		Position = scope:Computed(function(use)
			return UDim2.fromOffset(0, use(topHeight))
		end),
		Size = UDim2.new(1, 0, 0, INSET),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		[OnEvent("MouseEnter")] = function()
			splitHover:set(true)
		end,
		[OnEvent("MouseLeave")] = function()
			splitHover:set(false)
		end,
		[OnEvent("InputBegan")] = function(input)
			if not Pointer.isPress(input) then
				return
			end
			local start = input.Position.Y
			local from = peek(topHeight)
			Pointer.drag(
				scope,
				function(point)
					local free = peek(height) - FOOTER
					split:set(
						math.clamp((from + (point.Y - start) / props.Scale()) / free, 0.1, 0.9)
					)
				end,
				function()
					Settings.set("DockSplit", math.round(peek(split) * 1000) / 1000)
				end
			)
		end,
		[Children] = hoverLine(splitHover, UDim2.new(0, 36, 0, 2)),
	})

	scope:Hydrate(props.Explorer)({
		Position = UDim2.fromOffset(0, 0),
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, use(topHeight))
		end),
	})

	local properties = scope:New("Frame")({
		Name = "PropertiesCard",
		Position = scope:Computed(function(use)
			return UDim2.fromOffset(INSET, use(topHeight) + INSET)
		end),
		Size = scope:Computed(function(use)
			return UDim2.new(1, -INSET * 2, 0, use(height) - FOOTER - use(topHeight) - INSET)
		end),
		BackgroundColor3 = Theme.Ink,
		ClipsDescendants = true,
		[Children] = {
			Controls.Fill(scope, scope:Value(0.03)),
			Controls.Edge(scope, scope:Value(0.5), UDim.new(0, 14)),
			props.Properties,
		},
	})

	local frame = Window.chrome(
		scope,
		{
			Name = "Dock",
			Parent = props.Layer,
			Position = scope:Computed(function(use)
				return UDim2.fromOffset(use(room).X - use(shownWidth) - MARGIN, MARGIN)
			end),
			Size = scope:Computed(function(use)
				return UDim2.fromOffset(use(shownWidth), use(height))
			end),
			Visible = open,
			ZIndex = 10,
			Children = {
				props.Explorer,
				splitter,
				properties,
				props.Footer,
				edge,
				-- A visible Modal button frees a locked mouse (first person, shift lock) while open.
				scope:New("TextButton")({
					Name = "FreeMouse",
					Modal = true,
					Size = UDim2.fromOffset(0, 0),
					BackgroundTransparency = 1,
					Text = "",
				}),
			},
		}
	)

	-- The floating bubble: shown while the dock is hidden; drag it anywhere, tap to reopen.
	local bubbleAt = scope:Value(nil)
	local bubbleMoved = false
	local function bubbleHome()
		local space = peek(room)
		return Vector2.new(space.X - 40, space.Y * 0.35)
	end
	scope:New("TextButton")({
		Name = "Bubble",
		Parent = props.Layer,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = scope:Computed(function(use)
			local space = use(room)
			local at = use(bubbleAt) or Vector2.new(space.X - 40, space.Y * 0.35)
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
			local origin = peek(bubbleAt) or bubbleHome()
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
		Open = open,
		Toggle = function()
			open:set(not peek(open))
		end,
		Reserve = scope:Computed(function(use)
			return if use(open) and not use(compact) then use(shownWidth) + MARGIN * 2 else 0
		end),
	}
end

return Dock
