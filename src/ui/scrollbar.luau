--!nocheck
--[[
	Ethos's scrollbar in place of Roblox's: a thin pill over the content's edge that widens
	under the pointer, takes the accent while dragged, and fades when nothing is moving. Drag the
	pill, or click the track to jump there. Both axes, as the frame's ScrollingDirection allows.

	Scrollbar.attach(scope, frame: ScrollingFrame)

	The bars live in a Folder inside the frame, so list layouts skip them; children of a
	ScrollingFrame move with the canvas, so each bar is shifted by CanvasPosition to stay put.
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Theme = require(Root.ui.tokens)
local Motion = require(Root.ui.motion)
local Pointer = require(Root.ui.pointer)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local TRACK = 12 -- the strip that reacts to the pointer
local THIN, WIDE = 3, 6
local MIN_THUMB = 24
local IDLE_AFTER = 1.2

local Scrollbar = {}

-- Absolute sizes count every UIScale above; CanvasPosition and offsets don't.
local function scaleAt(instance): number
	local scale = 1
	local current = instance
	while current do
		local uiScale = current:FindFirstChildOfClass("UIScale")
		if uiScale then
			scale *= uiScale.Scale
		end
		current = current.Parent
	end
	return math.max(scale, 0.001)
end

-- The thumb's offset and length along a track, from the window, canvas and scroll position.
function Scrollbar.thumb(window: number, canvas: number, position: number): (number?, number?)
	if canvas <= window + 1 then
		return nil, nil
	end
	local length = math.max(MIN_THUMB, window * window / canvas)
	local travel = window - length
	local at = travel * math.clamp(position / (canvas - window), 0, 1)
	return at, length
end

local function bar(scope, frame: ScrollingFrame, vertical: boolean, folder: Folder)
	local hovered = scope:Value(false)
	local dragging = scope:Value(false)
	local active = scope:Value(false) -- scrolled a moment ago
	local width = Motion.Animate(
		scope,
		scope:Computed(function(use)
			return if use(hovered) or use(dragging) then WIDE else THIN
		end),
		Motion.Snap(0.18)
	)
	local fade = Motion.Animate(
		scope,
		scope:Computed(function(use)
			return if use(dragging) then 0.1
				elseif use(hovered) then 0.45
				elseif use(active) then 0.6
				else 0.82
		end),
		Motion.Soft(0.25)
	)

	local thumb = scope:New("Frame")({
		Name = "Thumb",
		AnchorPoint = if vertical then Vector2.new(1, 0) else Vector2.new(0, 1),
		BackgroundColor3 = scope:Computed(function(use)
			return if use(dragging) then use(Theme.Accent) else use(Theme.Ink)
		end),
		BackgroundTransparency = fade,
		BorderSizePixel = 0,
		[Children] = scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
	})
	local track = scope:New("TextButton")({
		Name = if vertical then "VerticalBar" else "HorizontalBar",
		Parent = folder,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 50,
		Visible = false,
		[OnEvent("MouseEnter")] = function()
			hovered:set(true)
		end,
		[OnEvent("MouseLeave")] = function()
			hovered:set(false)
		end,
		[Children] = thumb,
	})

	local geometry = { At = 0, Length = 0, Window = 0, Canvas = 0 }
	local function layout()
		local s = scaleAt(frame)
		local window = (if vertical then frame.AbsoluteWindowSize.Y else frame.AbsoluteWindowSize.X)
			/ s
		local canvas = (if vertical then frame.AbsoluteCanvasSize.Y else frame.AbsoluteCanvasSize.X)
			/ s
		local across = (if vertical then frame.AbsoluteWindowSize.X else frame.AbsoluteWindowSize.Y)
			/ s
		local position = if vertical then frame.CanvasPosition.Y else frame.CanvasPosition.X
		local at, length = Scrollbar.thumb(window, canvas, position)
		track.Visible = at ~= nil
		if at == nil then
			return
		end
		geometry = { At = at, Length = length, Window = window, Canvas = canvas }
		local scroll = frame.CanvasPosition
		if vertical then
			track.Position = UDim2.fromOffset(scroll.X + across - TRACK, scroll.Y)
			track.Size = UDim2.fromOffset(TRACK, window)
		else
			track.Position = UDim2.fromOffset(scroll.X, scroll.Y + across - TRACK)
			track.Size = UDim2.fromOffset(window, TRACK)
		end
	end
	local function place()
		local w = peek(width)
		if vertical then
			thumb.Position = UDim2.new(1, -2, 0, geometry.At)
			thumb.Size = UDim2.fromOffset(w, geometry.Length)
		else
			thumb.Position = UDim2.new(0, geometry.At, 1, -2)
			thumb.Size = UDim2.fromOffset(geometry.Length, w)
		end
	end

	local idle = 0
	local function moved()
		layout()
		place()
		active:set(true)
		idle += 1
		local mine = idle
		task.delay(
			IDLE_AFTER,
			function()
				if mine == idle then
					active:set(false)
				end
			end
		)
	end
	for _, property in { "CanvasPosition", "AbsoluteCanvasSize", "AbsoluteWindowSize" } do
		table.insert(scope, frame:GetPropertyChangedSignal(property):Connect(moved))
	end
	table.insert(scope, scope:Observer(width):onChange(place))
	task.defer(function()
		layout()
		place()
	end)

	local function scrollTo(at: number)
		local travel = geometry.Window - geometry.Length
		local share = if travel > 0 then math.clamp(at / travel, 0, 1) else 0
		local target = share * (geometry.Canvas - geometry.Window)
		frame.CanvasPosition = if vertical then Vector2.new(frame.CanvasPosition.X, target)
			else Vector2.new(target, frame.CanvasPosition.Y)
	end
	table.insert(
		scope,
		track.InputBegan:Connect(
			function(input)
				if not Pointer.isPress(input) then
					return
				end
				local s = scaleAt(frame)
				local start = if vertical then input.Position.Y else input.Position.X
				local origin = if vertical then track.AbsolutePosition.Y
					else track.AbsolutePosition.X
				local along = (start - origin) / s
				-- A press off the thumb jumps there first, then drags from the middle.
				local from = geometry.At
				if along < geometry.At or along > geometry.At + geometry.Length then
					from = along - geometry.Length / 2
					scrollTo(from)
				end
				dragging:set(true)
				Pointer.drag(
					scope,
					function(point)
						local now = if vertical then point.Y else point.X
						scrollTo(from + (now - start) / s)
					end,
					function()
						dragging:set(false)
					end
				)
			end
		)
	)
end

function Scrollbar.attach(scope, frame: ScrollingFrame)
	frame.ScrollBarThickness = 0
	local folder = Instance.new("Folder")
	folder.Name = "Scrollbars"
	folder.Parent = frame
	table.insert(scope, folder)
	local direction = frame.ScrollingDirection
	if direction ~= Enum.ScrollingDirection.X then
		bar(scope, frame, true, folder)
	end
	if direction ~= Enum.ScrollingDirection.Y then
		bar(scope, frame, false, folder)
	end
	return frame
end

return table.freeze(Scrollbar)
