--[[
	A Luau code view and editor: line numbers, syntax colours and a scrolling surface. Read-only
	views still select text for copying. Editing follows react-simple-code-editor (MIT, behaviour
	only): Tab indents, Shift+Tab outdents, Enter keeps the line's indentation, Ctrl+Z and Ctrl+Y
	undo and redo (100 steps, typing within a second merges). Colours show while the box isn't
	focused; while typing the text is plain, because a Roblox TextBox can't colour its own text.

	props: Text (a Value the view reads and, when editable, writes), Editable?, Placeholder?,
	LayoutOrder?, Size?, Name?.
]]

local UserInputService = game:GetService("UserInputService")

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Theme = require(Root.ui.tokens)
local Scrollbar = require(Root.ui.scrollbar)
local Fonts = require(Root.ui.fonts)
local Surface = require(script.Parent.controls.surface)
local CodeTheme = require(script.Parent.codeTheme)
local LuauHighlight = require(Root.utils.luauHighlight)

local Children = Fusion.Children
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local TEXT_SIZE = 13
local PAD = 12
local DIGIT = 8
-- Past this the label would blow Roblox's text limits with colour tags; show it plain.
local HIGHLIGHT_LIMIT = 20000
local HISTORY_LIMIT = 100
local MERGE_SECONDS = 1
local ESCAPES = {
	["&"] = "&amp;",
	["<"] = "&lt;",
	[">"] = "&gt;",
	['"'] = "&quot;",
	["'"] = "&apos;",
}

local CodeView = {}

function CodeView.richText(source: string, colors): string
	local lines = {}
	for index, tokens in LuauHighlight(source) do
		local parts = {}
		for _, token in tokens do
			local text = string.gsub(token.Text, "[&<>\"']", ESCAPES)
			local color = colors[token.Kind] or colors.iden
			table.insert(parts, `<font color="#{color:ToHex()}">{text}</font>`)
		end
		lines[index] = table.concat(parts)
	end
	return table.concat(lines, "\n")
end

function CodeView.keyEdit(text: string, cursor: number, key: Enum.KeyCode, shift: boolean): (string?, number?)
	local before, after = string.sub(text, 1, cursor - 1), string.sub(text, cursor)
	local lineStart = (string.find(before, "\n[^\n]*$") or 0) + 1
	if key == Enum.KeyCode.Tab and not shift then
		return before .. "\t" .. after, cursor + 1
	elseif key == Enum.KeyCode.Tab and shift then
		if string.sub(text, lineStart, lineStart) == "\t" then
			return
				string.sub(text, 1, lineStart - 1) .. string.sub(text, lineStart + 1),
				math.max(lineStart, cursor - 1)
		end
		return nil
	end
	return nil
end

function CodeView.indentNewline(text: string, cursor: number): (string, number)
	local before = string.sub(text, 1, cursor - 2)
	local previous = string.match(before, "([^\n]*)$") or ""
	local indent = string.match(previous, "^[ \t]*") or ""
	if indent == "" then
		return text, cursor
	end
	return string.sub(text, 1, cursor - 1) .. indent .. string.sub(text, cursor), cursor + #indent
end

function CodeView.new(scope, props)
	local text = props.Text
	local editable = props.Editable
	local focused = scope:Value(false)
	local colors = scope:Computed(function(use)
		return CodeTheme(use(Theme.Surface))
	end)
	local lineCount = scope:Computed(function(use)
		return select(2, string.gsub(use(text), "\n", "")) + 1
	end)
	local gutter = scope:Computed(function(use)
		return #tostring(use(lineCount)) * DIGIT + PAD + 4
	end)
	local function isEditable(use)
		return if editable == nil then false
			elseif type(editable) == "boolean" then editable
			else use(editable)
	end

	local history = { { Text = peek(text), Cursor = 1, At = 0 } }
	local at = 1
	local applying = false
	local box: TextBox

	local function remember(value: string, cursor: number, merge: boolean)
		local now = os.clock()
		for index = #history, at + 1, -1 do
			history[index] = nil
		end
		local last = history[at]
		if last and last.Text == value then
			return
		end
		if merge and last and at > 1 and now - last.At < MERGE_SECONDS then
			history[at] = { Text = value, Cursor = cursor, At = now }
		else
			table.insert(history, { Text = value, Cursor = cursor, At = now })
			if #history > HISTORY_LIMIT then
				table.remove(history, 1)
			end
			at = #history
		end
	end

	local function apply(value: string, cursor: number)
		applying = true
		box.Text = value
		box.CursorPosition = cursor
		applying = false
		text:set(value)
	end

	local lastText = peek(text)
	box = scope:New("TextBox")({
		Name = "Code",
		Position = scope:Computed(function(use)
			return UDim2.fromOffset(use(gutter), 0)
		end),
		Size = scope:Computed(function(use)
			return UDim2.new(1, -use(gutter), 1, 0)
		end),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		MultiLine = true,
		TextEditable = scope:Computed(isEditable),
		Text = peek(text),
		PlaceholderText = props.Placeholder or "",
		PlaceholderColor3 = Theme.Faint,
		FontFace = Fonts.Mono,
		TextSize = TEXT_SIZE,
		TextColor3 = Theme.Ink2,
		TextTransparency = scope:Computed(function(use)
			local long = #use(text) > HIGHLIGHT_LIMIT
			return if use(focused) or long then 0 else 1
		end),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		SelectionImageObject = nil,
		ZIndex = 2,
		[OnEvent("Focused")] = function()
			focused:set(true)
		end,
		[OnEvent("FocusLost")] = function()
			focused:set(false)
		end,
		[OnChange("Text")] = function(value)
			if applying or value == lastText then
				lastText = value
				return
			end
			local cursor = box.CursorPosition
			if #value == #lastText + 1 and string.sub(value, cursor - 1, cursor - 1) == "\n" then
				local indented, moved = CodeView.indentNewline(value, cursor)
				if indented ~= value then
					lastText = indented
					apply(indented, moved)
					remember(indented, moved, false)
					return
				end
			end
			lastText = value
			text:set(value)
			remember(value, cursor, true)
		end,
	})
	table.insert(
		scope,
		scope:Observer(text):onChange(function()
			local value = peek(text)
			if value ~= box.Text then
				lastText = value
				applying = true
				box.Text = value
				applying = false
				history, at = { { Text = value, Cursor = 1, At = 0 } }, 1
			end
		end)
	)
	table.insert(
		scope,
		UserInputService.InputBegan:Connect(
			function(input)
				if not box:IsFocused()
					or not box.TextEditable
					or input.UserInputType ~= Enum.UserInputType.Keyboard then
					return
				end
				local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
				local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
				if ctrl and (input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.Y) then
					local redo = input.KeyCode == Enum.KeyCode.Y or shift
					local target = if redo then at + 1 else at - 1
					local entry = history[target]
					if entry then
						at = target
						task.defer(function()
							lastText = entry.Text
							apply(entry.Text, entry.Cursor)
						end)
					end
					return
				end
				if input.KeyCode == Enum.KeyCode.Tab then
					local before = box.Text
					local cursor = box.CursorPosition
					task.defer(
						function()
							-- The TextBox may have moved focus or typed a tab itself; start from what it had.
							local value, moved = CodeView.keyEdit(
								before,
								cursor,
								Enum.KeyCode.Tab,
								shift
							)
							if value then
								lastText = value
								apply(value, moved)
								remember(value, moved, false)
								if not box:IsFocused() then
									box:CaptureFocus()
									box.CursorPosition = moved
								end
							end
						end
					)
				end
			end
		)
	)

	local scroll = scope:New("ScrollingFrame")({
		Name = "Scroll",
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		[Children] = {
			scope:New("UIPadding")({
				PaddingTop = UDim.new(0, PAD),
				PaddingBottom = UDim.new(0, PAD),
				PaddingRight = UDim.new(0, PAD),
			}),
			scope:New("TextLabel")({
				Name = "Lines",
				Size = scope:Computed(function(use)
					return UDim2.new(0, use(gutter) - PAD, 1, 0)
				end),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					local numbers = table.create(use(lineCount))
					for index = 1, use(lineCount) do
						numbers[index] = tostring(index)
					end
					return table.concat(numbers, "\n")
				end),
				FontFace = Fonts.Mono,
				TextSize = TEXT_SIZE,
				TextColor3 = Theme.Faint,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Top,
				-- AutomaticCanvasSize ignores the frame's bottom padding; this keeps room under the last line.
				[Children] = scope:New("UIPadding")({ PaddingBottom = UDim.new(0, PAD) }),
			}),
			scope:New("TextLabel")({
				Name = "Colours",
				Position = scope:Computed(function(use)
					return UDim2.fromOffset(use(gutter), 0)
				end),
				Size = UDim2.fromScale(0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				RichText = true,
				Visible = scope:Computed(function(use)
					return not use(focused) and #use(text) <= HIGHLIGHT_LIMIT
				end),
				Text = scope:Computed(function(use)
					local source = use(text)
					return if #source <= HIGHLIGHT_LIMIT then CodeView.richText(source, use(colors))
						else ""
				end),
				FontFace = Fonts.Mono,
				TextSize = TEXT_SIZE,
				TextColor3 = Theme.Ink2,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
			box,
		},
	})
	Scrollbar.attach(scope, scroll)

	local frame = scope:New("Frame")({
		Name = props.Name or "CodeView",
		LayoutOrder = props.LayoutOrder,
		Size = props.Size or UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Ink,
		ClipsDescendants = true,
		[Children] = {
			Surface.Fill(scope, scope:Value(0.04)),
			Surface.Edge(scope, nil, UDim.new(0, 14)),
			scroll,
		},
	})
	return frame, { Box = box, Scroll = scroll }
end

return table.freeze(CodeView)
