--!nocheck
--[[
	Studio's class icons: the 16px strip every Roblox client ships, indexed by ReflectionMetadata's
	ExplorerImageIndex, so nothing is uploaded and it works on every executor. The strip is 2352px
	wide and the engine ignores ImageRectOffset past 1024px, so instead of cropping, the whole strip
	slides inside a 16px clipping frame.
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Api = require(Root.core.api)

local IMAGE = "rbxasset://textures/ClassImages.PNG"
local SIZE = 16
local COUNT = 147

local ClassIcon = {}

-- For when ReflectionMetadata couldn't load; indices from it.
local FALLBACK = {
	Folder = 77,
	Model = 2,
	Part = 1,
	Script = 6,
	LocalScript = 18,
	ModuleScript = 76,
	Players = 21,
	Player = 12,
	Workspace = 19,
	Camera = 5,
}

function ClassIcon.index(className: string): number
	local index = Api.icon(className) or FALLBACK[className] or 0
	return math.clamp(index, 0, COUNT - 1)
end

function ClassIcon.apply(frame: Frame, className: string)
	frame.Strip.Position = UDim2.fromOffset(-ClassIcon.index(className) * SIZE, 0)
end

function ClassIcon.new(scope, className: string, props)
	props = props or {}
	props.Name = props.Name or "ClassIcon"
	props.Size = UDim2.fromOffset(SIZE, SIZE)
	props.BackgroundTransparency = 1
	props.ClipsDescendants = true
	props[Fusion.Children] = scope:New("ImageLabel")({
		Name = "Strip",
		Size = UDim2.fromOffset(SIZE * COUNT, SIZE),
		BackgroundTransparency = 1,
		Image = IMAGE,
	})
	local frame = scope:New("Frame")(props)
	ClassIcon.apply(frame, className)
	return frame
end

return table.freeze(ClassIcon)
