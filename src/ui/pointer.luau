local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)

local UserInputService = game:GetService("UserInputService")

local Pointer = {}

function Pointer.isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

function Pointer.drag(scope, onMove: (Vector2) -> (), onEnd: (() -> ())?)
	local dragScope = scope:innerScope()
	table.insert(
		dragScope,
		UserInputService.InputChanged:Connect(function(motion)
			if motion.UserInputType == Enum.UserInputType.MouseMovement
				or motion.UserInputType == Enum.UserInputType.Touch then
				onMove(Vector2.new(motion.Position.X, motion.Position.Y))
			end
		end)
	)
	table.insert(
		dragScope,
		UserInputService.InputEnded:Connect(function(release)
			if Pointer.isPress(release) then
				Fusion.doCleanup(dragScope)
				if onEnd then
					onEnd()
				end
			end
		end)
	)
end

return table.freeze(Pointer)
