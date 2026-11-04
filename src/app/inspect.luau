--!nocheck
--[[
	Inspect: what's wired to an instance and what it sends. Sections show when they apply:
		Remote       call it with typed arguments, or block the game from firing it
		Connections  each event's handlers (script and line) to fire, disable or disconnect
		Constants    search a script's constants and upvalues
	The arguments box is shared by calling the remote and firing connections.
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Scrollbar = require(Root.ui.scrollbar)
local Env = require(Root.core.env)
local Api = require(Root.core.api)
local Introspect = require(Root.core.introspect)
local State = require(script.Parent.state)
local Toast = require(script.Parent.toast)
local Actions = require(script.Parent.actions)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local ROW = 30
local RESULT_LIMIT = 200
-- Without the API dump, the events every instance has.
local BASIC_EVENTS = {
	"Changed",
	"ChildAdded",
	"ChildRemoved",
	"DescendantAdded",
	"DescendantRemoving",
	"AncestryChanged",
	"AttributeChanged",
	"Destroying",
}

local Inspect = {}

local function label(scope, props)
	props.Size = props.Size or UDim2.new(0, 0, 0, ROW)
	props.TextSize = props.TextSize or 13
	props.FontFace = props.FontFace or Theme.Body
	return Controls.Label(scope, props)
end

-- A row: text that takes the room left, then small buttons.
local function line(scope, order: number, text, buttons, props)
	props = props or {}
	local content = {
		scope:New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		scope:New("UIPadding")({
			PaddingLeft = UDim.new(0, props.Indent or 10),
			PaddingRight = UDim.new(0, 6),
		}),
		scope:New(if props.OnActivated then "TextButton" else "Frame")({
			Name = "Text",
			LayoutOrder = 1,
			Size = UDim2.fromOffset(0, ROW),
			BackgroundTransparency = 1,
			Text = if props.OnActivated then "" else nil,
			AutoButtonColor = if props.OnActivated then false else nil,
			[OnEvent("Activated")] = props.OnActivated,
			[Children] = {
				scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
				label(
					scope,
					{
						Size = UDim2.fromScale(1, 1),
						Text = text,
						TextColor3 = props.Color or Theme.Ink,
						FontFace = props.FontFace,
					}
				),
			},
		}),
	}
	for index, button in buttons or {} do
		button.LayoutOrder = index + 1
		table.insert(content, button)
	end
	return scope:New("Frame")({
		Name = "Line",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, ROW + 4),
		BackgroundTransparency = 1,
		[Children] = content,
	})
end

local function small(scope, text: string, onActivated, ghost: boolean?)
	return Controls.Button(
		scope,
		{
			Text = text,
			Height = 26,
			TextSize = 12,
			PaddingX = 9,
			Ghost = ghost,
			OnActivated = onActivated,
		}
	)
end

local function heading(scope, order: number, text)
	return label(
		scope,
		{
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 22),
			Text = text,
			TextColor3 = Theme.Muted,
			FontFace = Theme.Title,
		}
	)
end

local function card(scope, order: number, children)
	return scope:New("Frame")({
		Name = "Card",
		LayoutOrder = order,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Ink,
		[Children] = {
			Controls.Fill(scope, scope:Value(0.04)),
			Controls.Edge(scope, nil, UDim.new(0, 12)),
			scope:New("UIPadding")({ PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
			scope:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			children,
		},
	})
end

-- The globals argument expressions can use.
local function argumentNames()
	local player = State.LocalPlayer
	local character = player and player.Character
	return {
		me = player,
		char = character,
		hrp = character and character:FindFirstChild("HumanoidRootPart"),
		sel = State.first(),
		sels = State.selection(),
	}
end

function Inspect.new(scope)
	local argsText = scope:Value("")
	local title = scope:Value("Nothing to inspect")
	local subtitle = scope:Value("Right-click an instance and pick Inspect")
	local sections = scope:New("Frame")({
		Name = "Sections",
		LayoutOrder = 3,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		[Children] = scope:New("UIListLayout")({
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local built = nil -- the inner scope of what's shown, cleaned on rebuild

	local function args()
		local parsed, problem = Introspect.parseArgs(peek(argsText), argumentNames())
		if parsed == nil then
			Toast.show(problem, "error")
		end
		return parsed
	end

	local rebuild

	local function remoteSection(inner, target, order)
		local method = Introspect.sendMethod(target)
		local result = inner:Value("")
		local count = inner:Value(Introspect.blockedCount(target))
		local alive = true
		table.insert(
			inner,
			function()
				alive = false
			end
		)
		task.spawn(function()
			while alive do
				count:set(Introspect.blockedCount(target))
				task.wait(0.5)
			end
		end)
		return {
			heading(inner, order, "Remote"),
			card(
				inner,
				order + 1,
				{
					line(
						inner,
						1,
						inner:Computed(function(use)
							local text = use(result)
							return if text == "" then `{method}(arguments)` else text
						end),
						{
							small(
								inner,
								method,
								function()
									local parsed = args()
									if parsed then
										result:set("…")
										task.spawn(function()
											local ok, text = Introspect.call(target, parsed)
											result:set((if ok then "→ " else "Error: ") .. text)
										end)
									end
								end
							),
						}
					),
					Controls.Row(
						inner,
						{
							LayoutOrder = 2,
							Title = "Block the game from firing it",
							Description = inner:Computed(function(use)
								local blocked = use(count)
								return if blocked == nil then "Your own calls still go through"
									else `Blocked {blocked} call{if blocked == 1 then "" else "s"}`
							end),
							Disabled = if Introspect.canBlock() then nil else "Needs hookmetamethod",
							Switch = {
								On = inner:Computed(function(use)
									return use(count) ~= nil
								end),
								Set = function(on)
									local ok, problem = Introspect.setBlocked(target, on)
									if not ok then
										Toast.show(problem, "error")
									end
									count:set(Introspect.blockedCount(target))
								end,
							},
						}
					),
				}
			),
		}
	end

	local function connectionsSection(inner, target, order)
		if not Env.has("getconnections") then
			return {
				heading(inner, order, "Connections"),
				card(
					inner,
					order + 1,
					line(inner, 1, "Needs getconnections", nil, { Color = Theme.Muted })
				),
			}
		end
		local events = if Api.hasDump() then Api.members(target.ClassName, "Events")
			else BASIC_EVENTS
		local rows, total = {}, 0
		for _, event in events do
			-- getconnections on a server-only signal (OnServerEvent) crashes the client outright.
			if string.match(event, "^OnServer") then
				continue
			end
			local ok, signal = pcall(function()
				return target[event]
			end)
			if not ok or typeof(signal) ~= "RBXScriptSignal" then
				continue
			end
			local connections = Introspect.connections(signal)
			if #connections == 0 then
				continue
			end
			total += #connections
			table.insert(
				rows,
				line(
					inner,
					#rows + 1,
					`{event} · {#connections}`,
					{
						if Env.has("firesignal") then small(
								inner,
								"Fire all",
								function()
									local parsed = args()
									if parsed then
										local fired, problem = pcall(
											Env.raw.firesignal,
											signal,
											table.unpack(parsed, 1, parsed.n)
										)
										Toast.show(
											if fired then `Fired {event}` else tostring(problem),
											if fired then "success" else "error"
										)
									end
								end,
								true
							)
							else nil,
					},
					{ FontFace = Theme.Title }
				)
			)
			for _, entry in connections do
				local connection = entry.Connection
				local enabled = inner:Value(entry.Enabled)
				table.insert(
					rows,
					line(
						inner,
						#rows + 1,
						Introspect.where(entry),
						{
							small(
								inner,
								"Fire",
								function()
									local parsed = args()
									if parsed then
										local fired, problem = pcall(function()
											connection:Fire(table.unpack(parsed, 1, parsed.n))
										end)
										if not fired then
											Toast.show(tostring(problem), "error")
										end
									end
								end,
								true
							),
							small(
								inner,
								inner:Computed(function(use)
									return if use(enabled) then "Disable" else "Enable"
								end),
								function()
									local on = not peek(enabled)
									local done, problem = pcall(function()
										if on then
											connection:Enable()
										else
											connection:Disable()
										end
									end)
									if done then
										enabled:set(on)
									else
										Toast.show(tostring(problem), "error")
									end
								end,
								true
							),
							small(
								inner,
								"Disconnect",
								function()
									local done, problem = pcall(function()
										connection:Disconnect()
									end)
									if done then
										rebuild()
									else
										Toast.show(tostring(problem), "error")
									end
								end,
								true
							),
						},
						{
							Indent = 22,
							Color = Theme.Muted,
							-- The handler's script opens decompiled, at least to read along.
							OnActivated = function()
								if entry.Script then
									State.Hooks.reveal(entry.Script)
									if not Actions.openScript(entry.Script) then
										Toast.show("Can't open that script here.", "error")
									end
								end
							end,
						}
					)
				)
			end
		end
		if total == 0 then
			table.insert(
				rows,
				line(inner, 1, "Nothing is connected to its events", nil, { Color = Theme.Muted })
			)
		end
		return {
			heading(inner, order, `Connections · {total}`),
			card(inner, order + 1, rows),
		}
	end

	local function constantsSection(inner, target, order)
		local hasConstants = Env.has("getconstants")
			and (Env.has("getgc") or Env.has("getscriptclosure"))
		if not hasConstants then
			return {
				heading(inner, order, "Constants"),
				card(
					inner,
					order + 1,
					line(
						inner,
						1,
						"Needs debug.getconstants and getgc",
						nil,
						{ Color = Theme.Muted }
					)
				),
			}
		end
		local query = inner:Value("")
		local kinds = { Constants = true, Upvalues = true }
		local status = inner:Value("Scanning the script's functions…")
		local list = inner:New("Frame")({
			Name = "Results",
			LayoutOrder = 3,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			[Children] = inner:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		local functions = nil
		local shown = nil
		local generation = 0
		local function show()
			generation += 1
			local mine = generation
			task.delay(
				0.2,
				function()
					if mine ~= generation or functions == nil or list.Parent == nil then
						return
					end
					if shown then
						Fusion.doCleanup(shown)
					end
					shown = inner:innerScope()
					local results, capped = Introspect.search(
						functions,
						peek(query),
						kinds,
						RESULT_LIMIT
					)
					status:set(
						if #results == 0 then `Nothing found in {#functions} functions`
							else `{#results}{if capped then "+" else ""} in {#functions} functions · click to copy`
					)
					for index, result in results do
						local where = `{result.Name}:{result.Line or "?"}`
						line(
							shown,
							index,
							`{result.Kind}  {result.Text}`,
							{
								label(
									shown,
									{
										Size = UDim2.fromOffset(0, ROW),
										AutomaticSize = Enum.AutomaticSize.X,
										Text = where,
										TextColor3 = Theme.Faint,
										TextSize = 12,
									}
								),
							},
							{
								FontFace = Theme.Code or Theme.Body,
								OnActivated = function()
									Actions.copy(result.Text, "value")
								end,
							}
						).Parent = list
					end
				end
			)
		end
		table.insert(inner, inner:Observer(query):onChange(show))
		table.insert(
			inner,
			function()
				if shown then
					Fusion.doCleanup(shown)
				end
			end
		)
		task.spawn(function()
			local found = Introspect.functionsOf(target)
			if list.Parent == nil then
				return
			end
			functions = found
			show()
		end)

		local function toggle(key, text)
			return small(
				inner,
				inner:Computed(
					function(use)
						use(status) -- relabel after a click
						return (if kinds[key] then "✓ " else "") .. text
					end
				),
				function()
					kinds[key] = not kinds[key]
					status:set("Searching…")
					show()
				end,
				true
			)
		end
		local field = Controls.Field(
			inner,
			{
				Name = "Find",
				Text = query,
				Placeholder = "Find a constant or upvalue",
				Icon = "search",
				Height = 34,
				LayoutOrder = 1,
			}
		)
		return {
			heading(inner, order, "Constants and upvalues"),
			card(
				inner,
				order + 1,
				{
					inner:New("Frame")({
						Name = "Search",
						LayoutOrder = 1,
						Size = UDim2.new(1, 0, 0, 42),
						BackgroundTransparency = 1,
						[Children] = {
							inner:New("UIPadding")({
								PaddingLeft = UDim.new(0, 6),
								PaddingRight = UDim.new(0, 6),
								PaddingTop = UDim.new(0, 4),
							}),
							field,
						},
					}),
					line(
						inner,
						2,
						status,
						{ toggle("Constants", "Constants"), toggle("Upvalues", "Upvalues") },
						{ Color = Theme.Muted }
					),
					list,
				}
			),
		}
	end

	rebuild = function()
		if built then
			Fusion.doCleanup(built)
			built = nil
		end
		local target = peek(State.InspectTarget)
		local alive = target ~= nil
			and pcall(function()
				return target.Parent
			end)
		if not alive then
			title:set("Nothing to inspect")
			subtitle:set("Right-click an instance and pick Inspect")
			return
		end
		title:set(target.Name)
		subtitle:set(target.ClassName)
		built = scope:innerScope()
		local content = {}
		local order = 1
		local function add(list)
			for _, child in list do
				table.insert(content, child)
			end
			order += 2
		end
		if Introspect.sendMethod(target) then
			add(remoteSection(built, target, order))
		end
		if target:IsA("LuaSourceContainer") then
			add(constantsSection(built, target, order))
		end
		add(connectionsSection(built, target, order))
		for _, child in content do
			child.Parent = sections
		end
	end
	table.insert(scope, scope:Observer(State.InspectTarget):onBind(rebuild))
	table.insert(
		scope,
		function()
			if built then
				Fusion.doCleanup(built)
			end
		end
	)

	local argsBox = scope:New("TextBox")({
		Name = "Arguments",
		Size = UDim2.new(1, -20, 0, 0),
		Position = UDim2.fromOffset(10, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		MultiLine = true,
		Text = "",
		PlaceholderText = 'Arguments, one per line: 5, "hi", true, nil, workspace.Part, hrp, sel',
		PlaceholderColor3 = Theme.Faint,
		TextColor3 = Theme.Ink,
		FontFace = Theme.Code or Theme.Body,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		[Fusion.OnChange("Text")] = function(text)
			argsText:set(text)
		end,
		[Children] = scope:New("UISizeConstraint")({ MinSize = Vector2.new(0, 44) }),
	})

	local pane = scope:New("ScrollingFrame")({
		Name = "Inspect",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		[Children] = {
			scope:New("UIPadding")({
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}),
			scope:New("UIListLayout")({
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			scope:New("Frame")({
				Name = "Header",
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
				[Children] = {
					label(
						scope,
						{
							Size = UDim2.new(1, -40, 0, 18),
							Text = title,
							TextSize = 14,
							FontFace = Theme.Title,
						}
					),
					label(
						scope,
						{
							Position = UDim2.fromOffset(0, 18),
							Size = UDim2.new(1, -40, 0, 16),
							Text = subtitle,
							TextSize = 12,
							TextColor3 = Theme.Muted,
						}
					),
					Controls.IconButton(
						scope,
						{
							Name = "Refresh",
							Icon = "refresh-cw",
							Size = 28,
							Position = UDim2.new(1, -28, 0, 4),
							OnActivated = function()
								rebuild()
							end,
						}
					),
				},
			}),
			card(
				scope,
				2,
				{
					heading(scope, 1, "   Arguments"),
					scope:New("Frame")({
						Name = "Box",
						LayoutOrder = 2,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						[Children] = {
							argsBox,
							scope:New("UIPadding")({ PaddingBottom = UDim.new(0, 6) }),
						},
					}),
				}
			),
			sections,
		},
	})
	Scrollbar.attach(scope, pane)
	return { Instance = pane }
end

return Inspect
