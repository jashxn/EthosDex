--!nocheck
--[[
	A Luau console. Code runs through the executor's loadstring with `sel` (the first selected
	instance) and `sels` (all of them) defined, and its print/warn/error land here as well as in
	the game's output. Game output can be shown too.
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Fonts = require(Root.ui.fonts)
local CodeView = require(Root.ui.codeView)
local Env = require(Root.core.env)
local Values = require(Root.core.values)
local State = require(script.Parent.state)

local Children = Fusion.Children
local peek = Fusion.peek

local LogService = Env.service("LogService")
local UserInputService = Env.service("UserInputService")

local LIMIT = 250

local Console = {}

function Console.new(scope)
	local code = scope:Value("print(sel)\n")
	local gameOutput = scope:Value(false)
	local order = 0
	local entries = {}

	local log = scope:New("ScrollingFrame")({
		Name = "Output",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Ink,
		ScrollBarImageTransparency = 0.8,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		[Children] = {
			scope:New("UIPadding")({
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}),
			scope:New("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
		},
	})

	local function push(text: string, kind: string)
		order += 1
		local color = if kind == "error" then Theme.Danger
			elseif kind == "warn" then Theme.Caution
			elseif kind == "input" then Theme.Muted
			elseif kind == "game" then Theme.Faint
			else Theme.Ink2
		local label = scope:New("TextLabel")({
			Name = "Entry",
			Parent = log,
			LayoutOrder = order,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			FontFace = Fonts.Mono,
			TextSize = 12,
			TextColor3 = color,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.sub(text, 1, 4000),
		})
		table.insert(entries, label)
		while #entries > LIMIT do
			table.remove(entries, 1):Destroy()
		end
		task.defer(function()
			log.CanvasPosition = Vector2.new(0, math.huge)
		end)
	end

	local function show(...)
		local parts = table.pack(...)
		for index = 1, parts.n do
			local value = parts[index]
			parts[index] = if type(value) == "string" then value else Values.format(value)
		end
		return table.concat(parts, "  ", 1, parts.n)
	end

	local function run()
		local source = peek(code)
		if string.match(source, "^%s*$") then
			return
		end
		push("> " .. (string.gsub(source, "\n", "\n  ")), "input")
		local fn, problem = Env.compile(source, "=EthosDex")
		if fn == nil then
			push(tostring(problem), "error")
			return
		end
		local selection = State.selection()
		local env = setmetatable(
			{
				sel = selection[1],
				sels = selection,
				print = function(...)
					push(show(...), "print")
					print(...)
				end,
				warn = function(...)
					push(show(...), "warn")
					warn(...)
				end,
			},
			{ __index = getfenv(0) }
		)
		pcall(setfenv, fn, env)
		task.spawn(function()
			local results = table.pack(xpcall(fn, debug.traceback))
			if not results[1] then
				push(tostring(results[2]), "error")
			elseif results.n > 1 then
				push("< " .. show(table.unpack(results, 2, results.n)), "print")
			end
		end)
	end

	table.insert(
		scope,
		LogService.MessageOut:Connect(function(message, messageType)
			if not peek(gameOutput) then
				return
			end
			push(
				message,
				if messageType == Enum.MessageType.MessageError then "error"
					elseif messageType == Enum.MessageType.MessageWarning then "warn"
					else "game"
			)
		end)
	)

	State.Hooks.consoleInsert = function(text)
		code:set(text .. peek(code))
	end

	local editor, parts = CodeView.new(
		scope,
		{
			Name = "Input",
			Text = code,
			Editable = true,
			Placeholder = "Luau. sel is the selected instance, sels all of them.",
		}
	)
	editor.AnchorPoint = Vector2.new(0, 1)
	editor.Position = UDim2.new(0, 10, 1, -52)
	editor.Size = UDim2.new(1, -20, 0.42, -40)

	table.insert(
		scope,
		UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Return
				and parts.Box:IsFocused()
				and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
				task.defer(run)
			end
		end)
	)

	local output = scope:New("Frame")({
		Name = "Log",
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0.58, -22),
		BackgroundColor3 = Theme.Ink,
		ClipsDescendants = true,
		[Children] = {
			Controls.Fill(scope, scope:Value(0.04)),
			Controls.Edge(scope, nil, UDim.new(0, 12)),
			log,
		},
	})

	local gameOutputT = Controls.animate(
		scope,
		scope:Computed(function(use)
			return if use(gameOutput) then 1 else 0
		end),
		Controls.snap(0.25)
	)

	local bar = scope:New("Frame")({
		Name = "Bar",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -10),
		Size = UDim2.new(1, -20, 0, 32),
		BackgroundTransparency = 1,
		[Children] = {
			Controls.Button(
				scope,
				{
					Name = "Run",
					Text = "Run",
					Icon = "play",
					Height = 32,
					OnActivated = run,
				}
			),
			Controls.Button(
				scope,
				{
					Name = "Clear",
					Position = UDim2.fromOffset(86, 0),
					Text = "Clear",
					Icon = "trash-2",
					Ghost = true,
					Height = 32,
					OnActivated = function()
						for _, entry in entries do
							entry:Destroy()
						end
						table.clear(entries)
					end,
				}
			),
			scope:New("TextButton")({
				Name = "GameOutput",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromOffset(150, 32),
				BackgroundTransparency = 1,
				Text = "",
				[Fusion.OnEvent("Activated")] = function()
					gameOutput:set(not peek(gameOutput))
				end,
				[Children] = {
					Controls.Label(
						scope,
						{
							Size = UDim2.new(1, -46, 1, 0),
							Text = "Game output",
							TextSize = 13,
							FontFace = Theme.Body,
							TextColor3 = Theme.Ink2,
							TextXAlignment = Enum.TextXAlignment.Right,
						}
					),
					Controls.Switch(scope, gameOutputT, scope:Value(0)),
				},
			}),
		},
	})

	local pane = scope:New("Frame")({
		Name = "Console",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[Children] = {
			output,
			editor,
			bar,
			Controls.Label(
				scope,
				{
					Name = "Unsupported",
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -16, 1, -48),
					Size = UDim2.fromOffset(260, 16),
					Text = "This executor has no loadstring",
					TextSize = 11,
					FontFace = Theme.Body,
					TextColor3 = Theme.Danger,
					TextXAlignment = Enum.TextXAlignment.Right,
					Visible = not Env.has("loadstring"),
				}
			),
		},
	})
	push(
		"Ethos Dex console. Ctrl+Enter runs. sel = selected instance, sels = all selected.",
		"input"
	)
	return { Instance = pane }
end

return Console
