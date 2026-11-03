--!nocheck
--[[
	Decompiled source, one pooled row per visible line, so a 20k-line script costs what fits on
	screen. Lines are highlighted once (LuauHighlight over the whole source, so strings and
	comments that span lines colour right) and turned into rich text as they scroll in.
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Fonts = require(Root.ui.fonts)
local CodeTheme = require(Root.ui.codeTheme)
local LuauHighlight = require(Root.utils.luauHighlight)
local Env = require(Root.core.env)
local Settings = require(Root.core.settings)
local State = require(script.Parent.state)
local ClassIcon = require(script.Parent.classIcon)
local Menu = require(script.Parent.menu)
local Toast = require(script.Parent.toast)
local Actions = require(script.Parent.actions)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local RunService = Env.service("RunService")
local TextService = Env.service("TextService")

local LINE = 18
local TEXT = 13
local PAD = 10
local HIGHLIGHT_LIMIT = 400000
local LONG_LINE = 1500
local ESCAPES = {
	["&"] = "&amp;",
	["<"] = "&lt;",
	[">"] = "&gt;",
	['"'] = "&quot;",
	["'"] = "&apos;",
}

local ScriptViewer = {}

local CHAR = (function()
	local ok, size = pcall(
		TextService.GetTextSize,
		TextService,
		string.rep("0", 100),
		TEXT,
		Enum.Font.RobotoMono,
		Vector2.new(100000, 100)
	)
	return if ok then size.X / 100 else 7.8
end)()

local function escape(text: string): string
	return (string.gsub(text, "[&<>\"']", ESCAPES))
end

function ScriptViewer.new(scope)
	local cache = setmetatable({}, { __mode = "k" })
	local lines = {} -- plain text
	local tokens = nil -- per line, or nil when plain
	local rich = {}
	local source = ""
	local status = scope:Value("")
	local problem = scope:Value(nil)
	local findQuery = scope:Value("")
	local matches = {}
	local matchAt = 0
	local matchLine = nil
	local dirty = true
	local resetCanvas = false
	local generation = 0
	local target = nil

	local function setSource(text: string)
		source = text
		local expanded = string.gsub(text, "\t", "    ")
		lines = string.split(expanded, "\n")
		rich = {}
		tokens = nil
		if #expanded <= HIGHLIGHT_LIMIT then
			local ok, result = pcall(LuauHighlight, expanded)
			if ok then
				tokens = result
			end
		end
		matches, matchAt, matchLine = {}, 0, nil
		resetCanvas = true
		dirty = true
	end

	local function richLine(index: number, colors): string
		local hit = rich[index]
		if hit then
			return hit
		end
		local text = lines[index] or ""
		if #text > LONG_LINE then
			hit = escape(string.sub(text, 1, LONG_LINE)) .. " …"
		elseif tokens and tokens[index] then
			local parts = {}
			for _, token in tokens[index] do
				local color = colors[token.Kind] or colors.iden
				table.insert(parts, `<font color="#{color:ToHex()}">{escape(token.Text)}</font>`)
			end
			hit = table.concat(parts)
		else
			hit = escape(text)
		end
		rich[index] = hit
		return hit
	end

	local function load(object, force: boolean?)
		generation += 1
		local mine = generation
		target = object
		problem:set(nil)
		if object == nil then
			setSource("")
			status:set("")
			return
		end
		local mode = Settings.get("Decompiler")
		local hit = cache[object]
		if hit and hit.Mode == mode and not force then
			setSource(hit.Source)
			status:set(`{#lines} lines`)
			return
		end
		setSource("")
		if not Env.canDecompile(object) then
			problem:set(
				if Env.has("decompile") or Env.has("getscriptbytecode") then "Server scripts aren't on the client, so there's nothing to decompile."
					else "This executor can't decompile scripts."
			)
			status:set("")
			return
		end
		status:set("Decompiling")
		task.spawn(function()
			local started = os.clock()
			local text, failure = Env.decompile(object, mode)
			if mine ~= generation then
				return
			end
			if text == nil then
				problem:set(tostring(failure))
				status:set("")
				return
			end
			cache[object] = { Mode = mode, Source = text }
			setSource(text)
			status:set(`{#lines} lines · {string.format("%.1f", os.clock() - started)}s`)
		end)
	end

	table.insert(
		scope,
		scope:Observer(State.ScriptTarget):onBind(function()
			load(peek(State.ScriptTarget))
		end)
	)
	table.insert(
		scope,
		scope:Observer(Settings.state("Decompiler")):onChange(function()
			if target then
				load(target)
			end
		end)
	)

	-- Header -------------------------------------------------------------------------------
	local headerIcon = ClassIcon.new(
		scope,
		"LocalScript",
		{
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
		}
	)
	local headerName = Controls.Label(
		scope,
		{
			Position = UDim2.fromOffset(40, 6),
			Size = UDim2.new(1, -170, 0, 18),
			TextSize = 14,
		}
	)
	local headerPath = Controls.Label(
		scope,
		{
			Position = UDim2.fromOffset(40, 23),
			Size = UDim2.new(1, -170, 0, 16),
			TextSize = 12,
			FontFace = Theme.Body,
			TextColor3 = Theme.Muted,
			Text = status,
		}
	)
	table.insert(
		scope,
		scope:Observer(State.ScriptTarget):onBind(function()
			local object = peek(State.ScriptTarget)
			if object then
				headerName.Text = object.Name
				ClassIcon.apply(headerIcon, object.ClassName)
			end
		end)
	)

	local function action(name, icon, order, onActivated)
		return Controls.IconButton(
			scope,
			{ Name = name, Icon = icon, Size = 30, LayoutOrder = order, OnActivated = onActivated }
		)
	end

	local header = scope:New("Frame")({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		[Children] = {
			headerIcon,
			headerName,
			headerPath,
			scope:New("Frame")({
				Name = "Actions",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(0, 30),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				[Children] = {
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					action(
						"Redo",
						"refresh-cw",
						1,
						function()
							if target then
								load(target, true)
							end
						end
					),
					action(
						"Copy",
						"copy",
						2,
						function()
							if source ~= "" then
								Actions.copy(source, "source")
							end
						end
					),
					action(
						"Save",
						"download",
						3,
						function()
							if target then
								Actions.saveScript(target)
							end
						end
					),
				},
			}),
		},
	})

	-- Find ---------------------------------------------------------------------------------
	local findCount = scope:Value("")
	local scrollToLine
	local function find(step: number)
		local text = string.lower(peek(findQuery))
		if text == "" then
			matches, matchLine = {}, nil
			findCount:set("")
			dirty = true
			return
		end
		if #matches == 0 or matches.Query ~= text then
			matches = { Query = text }
			for index, line in lines do
				if string.find(string.lower(line), text, 1, true) then
					table.insert(matches, index)
				end
			end
			matchAt = 0
		end
		if #matches == 0 then
			findCount:set("0")
			matchLine = nil
			dirty = true
			return
		end
		matchAt = (matchAt + step - 1) % #matches + 1
		matchLine = matches[matchAt]
		findCount:set(`{matchAt}/{#matches}`)
		scrollToLine(matchLine)
		dirty = true
	end
	table.insert(
		scope,
		scope:Observer(findQuery):onChange(function()
			matches = {}
			find(1)
		end)
	)

	local findField = Controls.Field(
		scope,
		{
			Name = "Find",
			Text = findQuery,
			Placeholder = "Find",
			Icon = "search",
			Height = 32,
			TrailingWidth = 110,
			OnSubmit = function()
				find(1)
			end,
			Trailing = scope:New("Frame")({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -4, 0.5, 0),
				Size = UDim2.fromOffset(104, 26),
				BackgroundTransparency = 1,
				[Children] = {
					Controls.Label(
						scope,
						{
							Size = UDim2.new(1, -56, 1, 0),
							Text = findCount,
							TextSize = 11,
							FontFace = Theme.Body,
							TextColor3 = Theme.Muted,
							TextXAlignment = Enum.TextXAlignment.Right,
						}
					),
					Controls.IconButton(
						scope,
						{
							Position = UDim2.new(1, -52, 0, 0),
							Icon = "chevron-up",
							Size = 26,
							IconSize = 13,
							OnActivated = function()
								find(-1)
							end,
						}
					),
					Controls.IconButton(
						scope,
						{
							Position = UDim2.new(1, -26, 0, 0),
							Icon = "chevron-down",
							Size = 26,
							IconSize = 13,
							OnActivated = function()
								find(1)
							end,
						}
					),
				},
			}),
		}
	)
	findField.Position = UDim2.fromOffset(10, 48)
	findField.Size = UDim2.new(1, -20, 0, 32)

	-- Code ---------------------------------------------------------------------------------
	local scroll = scope:New("ScrollingFrame")({
		Name = "Code",
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = if State.Touch then 0 else 4,
		ScrollBarImageColor3 = Theme.Ink,
		ScrollBarImageTransparency = 0.8,
	})
	table.insert(
		scope,
		scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			dirty = true
		end)
	)
	table.insert(
		scope,
		scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			dirty = true
		end)
	)

	scrollToLine = function(index: number)
		local height = scroll.AbsoluteWindowSize.Y
		local y = (index - 1) * LINE + PAD
		local top = scroll.CanvasPosition.Y
		if y < top or y + LINE > top + height then
			scroll.CanvasPosition = Vector2.new(0, math.max(0, y - height / 3))
		end
	end

	local body = scope:New("Frame")({
		Name = "Body",
		Position = UDim2.fromOffset(10, 88),
		Size = UDim2.new(1, -20, 1, -98),
		BackgroundColor3 = Theme.Ink,
		ClipsDescendants = true,
		[Children] = {
			Controls.Fill(scope, scope:Value(0.04)),
			Controls.Edge(scope, nil, UDim.new(0, 12)),
			scroll,
		},
	})

	local message = scope:New("Frame")({
		Name = "Problem",
		Position = UDim2.fromOffset(10, 88),
		Size = UDim2.new(1, -20, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = scope:Computed(function(use)
			return use(problem) ~= nil
		end),
		[Children] = Controls.Banner(
			scope,
			{
				Icon = "triangle-alert",
				Ink = Theme.Caution,
				Text = scope:Computed(function(use)
					return "Couldn't decompile: "
						.. (use(problem) or "")
						.. "\nTry another decompiler in Settings."
				end),
			}
		),
	})

	local empty = Controls.Empty(
		scope,
		{
			Name = "Empty",
			Icon = "code",
			Title = "Right-click a script and choose View script",
		}
	)
	empty.AnchorPoint = Vector2.new(0.5, 0.5)
	empty.Position = UDim2.fromScale(0.5, 0.45)

	local pool = {}
	local function newRow(index)
		local number = scope:New("TextLabel")({
			Name = "Number",
			BackgroundTransparency = 1,
			FontFace = Fonts.Mono,
			TextSize = TEXT,
			TextColor3 = Theme.Faint,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		local code = scope:New("TextLabel")({
			Name = "Text",
			BackgroundTransparency = 1,
			RichText = true,
			FontFace = Fonts.Mono,
			TextSize = TEXT,
			TextColor3 = Theme.Ink2,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local frame = scope:New("TextButton")({
			Name = "Line" .. index,
			Parent = scroll,
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Visible = false,
			[Children] = { number, code },
		})
		local row = { Frame = frame, Number = number, Code = code, Line = 0 }
		for _, connection in Menu.bind(
			frame,
			function(point)
				local line = lines[row.Line]
				if line then
					Menu.open(
						point,
						{
							{
								Text = "Copy line",
								Icon = "copy",
								OnActivated = function()
									Actions.copy(line, "line")
								end,
							},
							{
								Text = "Copy all",
								Icon = "files",
								OnActivated = function()
									Actions.copy(source, "source")
								end,
							},
						}
					)
				end
			end
		) do
			table.insert(scope, connection)
		end
		return row
	end

	local function render()
		dirty = false
		if resetCanvas then
			resetCanvas = false
			scroll.CanvasSize = UDim2.new()
			scroll.CanvasPosition = Vector2.zero
		end
		local hasTarget = peek(State.ScriptTarget) ~= nil
		empty.Visible = not hasTarget
		header.Visible = hasTarget
		findField.Visible = hasTarget
		body.Visible = hasTarget and peek(problem) == nil
		local count = if source == "" then 0 else #lines
		local gutter = #tostring(math.max(count, 1)) * CHAR + PAD * 2
		local widest = 0
		local height = scroll.AbsoluteWindowSize.Y
		local first = math.max(1, math.floor(math.max(0, scroll.CanvasPosition.Y - PAD) / LINE) + 1)
		local needed = math.ceil(height / LINE) + 2
		while #pool < needed do
			table.insert(pool, newRow(#pool + 1))
		end
		local colors = CodeTheme(peek(Theme.Surface))
		for slot, row in pool do
			local index = first + slot - 1
			if slot > needed or index > count then
				row.Frame.Visible = false
				continue
			end
			local text = lines[index]
			widest = math.max(widest, math.min(#text, LONG_LINE + 2))
			row.Line = index
			row.Frame.Visible = true
			row.Frame.Position = UDim2.fromOffset(0, (index - 1) * LINE + PAD)
			row.Frame.Size = UDim2.new(1, 0, 0, LINE)
			row.Frame.BackgroundTransparency = if index == matchLine then 0.82 else 1
			row.Number.Position = UDim2.fromOffset(0, 0)
			row.Number.Size = UDim2.fromOffset(gutter - PAD, LINE)
			row.Number.Text = tostring(index)
			row.Code.Position = UDim2.fromOffset(gutter, 0)
			row.Code.Size = UDim2.fromOffset(math.min(#text, LONG_LINE + 2) * CHAR + 20, LINE)
			row.Code.Text = richLine(index, colors)
		end
		-- The canvas is as wide as the widest line seen so far, so it never jumps narrower.
		local canvasWidth = math.max(scroll.CanvasSize.X.Offset, gutter + widest * CHAR + PAD * 3)
		if count == 0 then
			canvasWidth = 0
		end
		scroll.CanvasSize = UDim2.fromOffset(canvasWidth, count * LINE + PAD * 2)
	end

	table.insert(
		scope,
		RunService.Heartbeat:Connect(function()
			if dirty then
				render()
			end
		end)
	)
	table.insert(
		scope,
		scope:Observer(problem):onChange(function()
			dirty = true
		end)
	)
	table.insert(
		scope,
		scope:Observer(Theme.Surface):onChange(function()
			rich = {}
			dirty = true
		end)
	)

	local pane = scope:New("Frame")({
		Name = "Script",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[Children] = { header, findField, body, message, empty },
	})
	return { Instance = pane }
end

return ScriptViewer
