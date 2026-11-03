--!nocheck
-- One-line notices at the bottom of the screen; the newest replaces the last.

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)

local Children = Fusion.Children

local Toast = {}
local layer = nil
local current = nil
local generation = 0

function Toast.setLayer(frame: GuiObject)
	layer = frame
end

-- kind: "info" | "success" | "error"
function Toast.show(text: string, kind: string?)
	if layer == nil then
		return
	end
	text = if #text > 96 then string.sub(text, 1, 93) .. "..." else text
	if current then
		Fusion.doCleanup(current)
	end
	generation += 1
	local mine = generation
	local scope = Fusion.scoped(Fusion)
	current = scope
	local ink = if kind == "error" then Theme.Danger
		elseif kind == "success" then Theme.Success
		else Theme.Ink2
	local icon = if kind == "error" then "circle-alert"
		elseif kind == "success" then "check"
		else "info"
	scope:New("Frame")({
		Name = "Toast",
		Parent = layer,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 36),
		BackgroundColor3 = Theme.Surface,
		ZIndex = 600,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
			scope:New("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Theme.Ink,
				Transparency = 0.86,
			}),
			scope:New("UISizeConstraint")({ MaxSize = Vector2.new(520, 36) }),
			scope:New("UIPadding")({
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 16),
			}),
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Controls.Icon(scope, icon, 15, { LayoutOrder = 1, ImageColor3 = ink }),
			Controls.Label(
				scope,
				{
					LayoutOrder = 2,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 36),
					Text = text,
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.None,
				}
			),
		},
	})
	task.delay(
		if kind == "error" then 4 else 2.5,
		function()
			if generation == mine and current == scope then
				current = nil
				Fusion.doCleanup(scope)
			end
		end
	)
end

return Toast
