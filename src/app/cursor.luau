--!nocheck
--[[
	Games with a custom cursor hide the real one (MouseIconEnabled = false, often re-set every
	frame) and draw an ImageLabel in PlayerGui, which ends up under our UI. So while the pointer
	is over our UI and the real cursor is hidden, we draw Roblox's arrow on top; the game's own
	settings are never touched.
]]

local Root = script.Parent.Parent
local Env = require(Root.core.env)
local State = require(script.Parent.state)

local UserInputService = Env.service("UserInputService")
local RunService = Env.service("RunService")
local GuiService = Env.service("GuiService")

-- 64px with the tip at the centre, like every Roblox cursor image.
local ARROW = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png"

local Cursor = {}

local function inside(object: GuiObject, point: Vector2): boolean
	local at, size = object.AbsolutePosition, object.AbsoluteSize
	return point.X >= at.X
		and point.Y >= at.Y
		and point.X <= at.X + size.X
		and point.Y <= at.Y + size.Y
end

-- Whether `point` (layer space) is over a visible top-level piece of our UI.
function Cursor.over(layer: Frame, point: Vector2): boolean
	for _, child in layer:GetChildren() do
		if child:IsA("GuiObject")
			and child.Visible
			and child.Name ~= "Cursor"
			and inside(child, point) then
			return true
		end
	end
	return false
end

function Cursor.new(scope, layer: Frame)
	if State.Touch then
		return
	end
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "Cursor"
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(64, 64)
	arrow.BackgroundTransparency = 1
	arrow.Image = ARROW
	arrow.ZIndex = 100000
	arrow.Visible = false
	arrow.Parent = layer
	table.insert(scope, arrow)

	table.insert(
		scope,
		RunService.RenderStepped:Connect(function()
			local point = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
			local show = not UserInputService.MouseIconEnabled and Cursor.over(layer, point)
			arrow.Visible = show
			if show then
				arrow.Position = UDim2.fromOffset(point.X, point.Y)
			end
		end)
	)
	return arrow
end

return Cursor
