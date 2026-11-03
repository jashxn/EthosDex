local Root = script.Parent.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Motion = require(Root.ui.motion)
local Theme = require(Root.ui.tokens)
local Surface = require(script.Parent.surface)
local Buttons = require(script.Parent.buttons)

local soft = Motion.Soft
local animate = Motion.Animate

local Children = Fusion.Children
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local Controls = {}

function Controls.Field(scope, props)
	local box
	local focused = scope:Value(false)
	local height = props.Height or 40
	box = scope:New("TextBox")({
		Name = "Box",
		Position = UDim2.fromOffset(if props.Icon then 38 else 14, 0),
		Size = UDim2.new(1, -(if props.Icon then 38 else 14) - (props.TrailingWidth or 14), 1, 0),
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Text = peek(props.Text),
		PlaceholderText = props.Placeholder or "",
		PlaceholderColor3 = Theme.Faint,
		FontFace = Theme.Title,
		TextSize = 14,
		TextColor3 = Theme.Ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		[OnChange("Text")] = function(text)
			if peek(props.Text) ~= text then
				props.Text:set(text)
			end
		end,
		[OnEvent("Focused")] = function()
			focused:set(true)
		end,
		[OnEvent("FocusLost")] = function(enter)
			focused:set(false)
			if enter and props.OnSubmit then
				props.OnSubmit(box.Text)
			end
		end,
	})
	table.insert(
		scope,
		scope:Observer(props.Text):onChange(function()
			if box.Text ~= peek(props.Text) then
				box.Text = peek(props.Text)
			end
		end)
	)
	local focusT = animate(
		scope,
		scope:Computed(function(use)
			return if use(focused) then 1 else 0
		end),
		soft(0.15)
	)
	local frame = scope:New("Frame")({
		Name = props.Name or "Field",
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Theme.Ink,
		[Children] = {
			Surface.Fill(
				scope,
				scope:Computed(function(use)
					return 0.06 + 0.02 * use(focusT)
				end)
			),
			Surface.Edge(scope, focusT, props.Radius or UDim.new(0, math.floor(height / 2.6))),
			if props.Icon then Surface.Icon(
					scope,
					props.Icon,
					16,
					{
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 13, 0.5, 0),
						ImageColor3 = Theme.Muted,
					}
				)
				else nil,
			box,
			props.Trailing,
		},
	})
	return frame, box
end

local DIGITS = {
	Zero = "0",
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
}
local KEY_NAMES = {
	Return = "Enter",
	MouseButton1 = "Mouse 1",
	MouseButton2 = "Mouse 2",
	MouseButton3 = "Mouse 3",
}

function Controls.keyLabel(key: string): string
	if KEY_NAMES[key] then
		return KEY_NAMES[key]
	end
	local digit = DIGITS[key] or DIGITS[string.match(key, "^Keypad(%a+)$") or ""]
	if digit then
		return if string.find(key, "^Keypad") then `Num {digit}` else digit
	end
	local spaced = string.gsub(string.gsub(key, "(%l)(%u)", "%1 %2"), "^Keypad ", "Num ")
	return (string.gsub(spaced, "Control", "Ctrl"))
end

function Controls.ageLabel(days: number): string
	local function count(n: number, unit: string)
		return `{n} {unit}{if n == 1 then "" else "s"}`
	end
	if days >= 365 then
		return `{count(days // 365, "year")} ({count(days, "day")})`
	elseif days >= 60 then
		return count(days // 30, "month")
	end
	return count(days, "day")
end

function Controls.KeyButton(scope, props)
	local Dispatcher = require(Root.utils.keybindDispatcher)
	local UserInputService = game:GetService("UserInputService")
	local listening = scope:Value(false)
	local connection
	local owner = {}
	local function stop(late)
		listening:set(false)
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if late then
			task.defer(Dispatcher.endCapture, owner)
		else
			Dispatcher.endCapture(owner)
		end
	end
	table.insert(scope, stop)
	return Buttons.Button(
		scope,
		{
			Name = props.Name or "Key",
			LayoutOrder = props.LayoutOrder,
			AnchorPoint = props.AnchorPoint,
			Position = props.Position,
			Height = 28,
			TextSize = 13,
			PaddingX = 12,
			Ink = scope:Computed(function(use)
				return use(if use(listening) then Theme.Accent else Theme.Ink)
			end),
			Text = scope:Computed(function(use)
				if use(listening) then
					return "Press a key"
				end
				local key = use(props.Key)
				return if key == nil or key == "None" or key == "" then "Not set"
					else Controls.keyLabel(key)
			end),
			OnActivated = function()
				if peek(listening) then
					stop()
					return
				end
				if not Dispatcher.beginCapture(owner, stop) then
					return
				end
				listening:set(true)
				connection = UserInputService.InputBegan:Connect(function(input)
					local key = Dispatcher.normalizeInputToKey(input)
					if key == nil or key == "MouseLeft" then
						return
					end
					stop(true)
					if key == "Escape" then
						return
					end
					props.OnChange(if key == "Backspace" then "None" else key)
				end)
			end,
		}
	)
end

function Controls.KeyRow(scope, props)
	return scope:New("Frame")({
		Name = props.Name or props.Title,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		[Children] = {
			if props.Icon then Surface.Icon(
					scope,
					props.Icon,
					16,
					{
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 14, 0.5, 0),
						ImageColor3 = Theme.Muted,
					}
				)
				else nil,
			Surface.Label(
				scope,
				{
					Name = "Title",
					Position = UDim2.fromOffset(if props.Icon then 40 else 14, 0),
					Size = UDim2.new(1, -150, 1, 0),
					Text = props.Title,
				}
			),
			Controls.KeyButton(
				scope,
				{
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Key = props.Key,
					OnChange = props.OnChange,
				}
			),
		},
	})
end

return table.freeze(Controls)
