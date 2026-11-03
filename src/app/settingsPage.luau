--!nocheck
-- Settings, what this executor supports, and credits.

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local EthosTheme = require(Root.ui.theme)
local Env = require(Root.core.env)
local Api = require(Root.core.api)
local Settings = require(Root.core.settings)
local State = require(script.Parent.state)
local Menu = require(script.Parent.menu)
local Picker = require(script.Parent.picker)
local Toast = require(script.Parent.toast)
local Actions = require(script.Parent.actions)

local Children = Fusion.Children
local peek = Fusion.peek

local UserInputService = Env.service("UserInputService")

local SettingsPage = {}

local function titleCase(text: string): string
	return (string.gsub(
		text,
		"(%a)([%w']*)",
		function(first, rest)
			return string.upper(first) .. rest
		end
	))
end

function SettingsPage.new(scope)
	local function switchRow(
		key: string,
		title: string,
		description: string?,
		reason: string?,
		onChange: (() -> ())?
	)
		local state = Settings.state(key)
		return Controls.Row(
			scope,
			{
				Title = title,
				Description = description,
				Disabled = reason,
				Switch = {
					On = state,
					Set = function(value)
						Settings.set(key, value)
						if onChange then
							onChange()
						end
					end,
				},
			}
		)
	end

	-- A setting with a few values: the row shows the current one and opens a menu of them.
	-- options: { { Value, Text } }
	local function choiceRow(key: string, title: string, description: string?, options)
		local state = Settings.state(key)
		return Controls.Row(
			scope,
			{
				Title = title,
				Description = description,
				Detail = scope:Computed(function(use)
					local current = use(state)
					for _, option in options do
						if option[1] == current then
							return option[2]
						end
					end
					return tostring(current)
				end),
				Chevron = true,
				OnActivated = function()
					local items = {}
					for _, option in options do
						table.insert(
							items,
							{
								Text = option[2],
								Icon = if Settings.get(key) == option[1] then "check" else nil,
								OnActivated = function()
									Settings.set(key, option[1])
								end,
							}
						)
					end
					Menu.open(
						UserInputService:GetMouseLocation()
							- Env.service("GuiService"):GetGuiInset(),
						items
					)
				end,
			}
		)
	end
	local function sizes(from: number, to: number, default: number)
		local options = {}
		for size = from, to do
			table.insert(
				options,
				{ size, if size == default then `{size} (default)` else tostring(size) }
			)
		end
		return options
	end

	local listening = scope:Value(false)
	local keyText = scope:Computed(function(use)
		return if use(listening) then "Press a key" else use(Settings.state("ToggleKey"))
	end)

	local capabilityRows = {}
	for _, feature in Env.FEATURES do
		local supported = Env.supports(feature)
		local missing = {}
		for _, name in feature.Needs do
			if not Env.has(name) then
				table.insert(missing, name)
			end
		end
		table.insert(
			capabilityRows,
			Controls.Row(
				scope,
				{
					Title = feature.Name,
					Icon = if supported then "check" else "x",
					Description = if supported then nil
						else "Missing "
							.. table.concat(missing, if feature.Any then " and " else ", "),
				}
			)
		)
	end

	local apiState = scope:Value(Api.Status)
	Api.onReady(function()
		apiState:set(Api.Status)
	end)

	local content = {
		Controls.Group(
			scope,
			{
				Title = "Appearance",
				Rows = {
					Controls.Row(
						scope,
						{
							Title = "Theme",
							Detail = scope:Computed(function(use)
								return titleCase(use(Settings.state("Theme")))
							end),
							Chevron = true,
							OnActivated = function()
								local names = EthosTheme.GetSupportedThemes()
								local items = {}
								for _, name in names do
									table.insert(items, name)
								end
								table.sort(items)
								Picker.open({
									Title = "Theme",
									Items = items,
									Current = Settings.get("Theme"),
									OnPick = function(name)
										Settings.set("Theme", name)
									end,
								})
							end,
						}
					),
					choiceRow(
						"UIScale",
						"UI scale",
						"Everything, bigger or smaller",
						{
							{ 0.8, "80%" },
							{ 0.9, "90%" },
							{ 1, "100%" },
							{ 1.1, "110%" },
							{ 1.25, "125%" },
							{ 1.5, "150%" },
						}
					),
					choiceRow(
						"PanelOpacity",
						"Panel opacity",
						"See the game through the panels",
						{
							{ 1, "Solid" },
							{ 0.9, "90%" },
							{ 0.8, "80%" },
							{ 0.7, "70%" },
							{ 0.55, "55%" },
						}
					),
					choiceRow(
						"DockSide",
						"Dock side",
						"Which edge the explorer and properties sit on",
						{ { "Right", "Right" }, { "Left", "Left" } }
					),
					switchRow(
						"CustomCursor",
						"Cursor over the panels",
						"Draws an arrow over Ethos Dex in games that hide the cursor"
					),
				},
			}
		),
		Controls.Group(
			scope,
			{
				Title = "Explorer",
				Rows = {
					choiceRow(
						"Density",
						"Row height",
						"For the explorer and properties",
						{
							{ "Compact", "Compact" },
							{ "Default", "Default" },
							{ "Comfortable", "Comfortable" },
						}
					),
					choiceRow("ExplorerText", "Text size", nil, sizes(11, 17, 13)),
					switchRow(
						"SelectionGlow",
						"Glow on the selection",
						"Outlines the selected part or model in the world"
					),
					switchRow(
						"HoverGlow",
						"Glow on hover",
						"Outlines what's under the pointer in the explorer"
					),
					switchRow(
						"ShowNil",
						"Nil instances",
						"Instances parented to nothing, as a folder at the bottom",
						if Env.has("getnilinstances") then nil else "Needs getnilinstances",
						function()
							State.Hooks.rebuildTree()
						end
					),
					Controls.Row(
						scope,
						{
							Title = "Collapse everything",
							Chevron = true,
							OnActivated = function()
								State.Hooks.collapseAll()
							end,
						}
					),
				},
			}
		),
		Controls.Group(
			scope,
			{
				Title = "Properties",
				Rows = {
					choiceRow("PropertiesText", "Text size", nil, sizes(11, 17, 13)),
					choiceRow(
						"NameColumn",
						"Name column",
						"How much of the width names get",
						{
							{ 0.3, "30%" },
							{ 0.42, "42% (default)" },
							{ 0.5, "50%" },
							{ 0.6, "60%" },
						}
					),
					switchRow(
						"ShowHidden",
						"Hidden properties",
						"Properties Roblox hides from scripts",
						if Env.has("gethiddenproperty") then nil else "Needs gethiddenproperty"
					),
					switchRow("ShowDeprecated", "Deprecated properties"),
				},
			}
		),
		Controls.Group(
			scope,
			{
				Title = "Scripts",
				Rows = {
					choiceRow("CodeText", "Code text size", nil, sizes(11, 18, 13)),
					Controls.Row(
						scope,
						{
							Title = "Decompiler",
							Description = "Auto tries the executor's, then Advanced Decompiler, then lua.expert and Konstant",
							Detail = Settings.state("Decompiler"),
							Chevron = true,
							OnActivated = function()
								local items = {}
								for _, mode in Env.DECOMPILERS do
									local reason = nil
									if mode == "Executor" and not Env.has("decompile") then
										reason = "Unsupported"
									elseif mode == "Advanced"
										and not (Env.has("getscriptbytecode")
											and Env.has("loadstring")) then
										reason = "Unsupported"
									elseif (mode == "Konstant" or mode == "lua.expert")
										and not (Env.has("getscriptbytecode") and Env.has("request")) then
										reason = "Unsupported"
									end
									table.insert(
										items,
										{
											Text = mode,
											Icon = if Settings.get("Decompiler") == mode then "check"
												else nil,
											Disabled = reason,
											Detail = reason,
											OnActivated = function()
												Settings.set("Decompiler", mode)
											end,
										}
									)
								end
								Menu.open(
									UserInputService:GetMouseLocation()
										- Env.service("GuiService"):GetGuiInset(),
									items
								)
							end,
						}
					),
					switchRow(
						"SaveDecompile",
						"Decompile when saving instances",
						"Slower, but saved scripts keep their source"
					),
				},
			}
		),
		Controls.Group(
			scope,
			{
				Title = "Window",
				Rows = {
					Controls.Row(
						scope,
						{
							Title = "Show or hide key",
							Description = if State.Touch then "On touch, tap the floating button"
								else nil,
							Detail = keyText,
							Chevron = true,
							OnActivated = function()
								if peek(listening) then
									return
								end
								listening:set(true)
								local connection
								connection = UserInputService.InputBegan:Connect(function(input)
									if input.UserInputType == Enum.UserInputType.Keyboard then
										connection:Disconnect()
										if input.KeyCode ~= Enum.KeyCode.Escape then
											Settings.set("ToggleKey", input.KeyCode.Name)
										end
										listening:set(false)
									end
								end)
								table.insert(scope, connection)
							end,
						}
					),
					Controls.Row(
						scope,
						{
							Title = "Reset settings",
							Description = "Back to the defaults; keeps the key and panel sizes",
							Icon = "rotate-ccw",
							Chevron = true,
							OnActivated = function()
								Settings.reset()
								State.Hooks.rebuildTree()
								Toast.show("Settings reset", "success")
							end,
						}
					),
				},
			}
		),
		Controls.Group(
			scope,
			{
				Title = "Tools",
				Rows = {
					Controls.Row(
						scope,
						{
							Title = "Save the place",
							Description = "Writes an .rbxlx to workspace/EthosDex/saves",
							Icon = "save",
							Chevron = true,
							Disabled = if Env.canWrite()
									and (Env.has("saveinstance") or Env.has("loadstring")) then nil
								else "Needs saveinstance and file access",
							OnActivated = function()
								Actions.saveInstance({ game })
							end,
						}
					),
					Controls.Row(
						scope,
						{
							Title = "Reload the Roblox API",
							Description = scope:Computed(function(use)
								local status = use(apiState)
								return if status == "ready" then `Loaded {Api.Version or "from the mirror"}`
									elseif status == "failed" then "Couldn't load: "
										.. tostring(Api.Problem)
									else "Loading"
							end),
							Icon = "refresh-cw",
							Chevron = true,
							OnActivated = function()
								if Env.canWrite() and Env.raw.delfile and Api.Version then
									pcall(
										Env.raw.delfile,
										`{Env.ROOT}/cache/api-{Api.Version}.json`
									)
									pcall(Env.raw.delfile, `{Env.ROOT}/cache/rmd-{Api.Version}.xml`)
								end
								Api.Status = "idle"
								apiState:set("loading")
								task.spawn(function()
									Api.load()
									apiState:set(Api.Status)
									State.Hooks.rebuildTree()
									Toast.show(
										if Api.Status == "ready" then "Reloaded the Roblox API"
											else "Couldn't reload the API",
										if Api.Status == "ready" then "success" else "error"
									)
								end)
							end,
						}
					),
				},
			}
		),
		Controls.Group(
			scope,
			{
				Title = "This executor: " .. Env.executor,
				Rows = capabilityRows,
			}
		),
		Controls.Group(
			scope,
			{
				Title = "Credits",
				Rows = {
					Controls.Row(
						scope,
						{
							Title = "jashan",
							Description = "@jasha.n on Discord",
							Icon = "discord",
							Detail = "Copy",
							OnActivated = function()
								Actions.copy("jasha.n", "Discord username")
							end,
						}
					),
					Controls.Row(
						scope,
						{
							Title = "Inspired by Dex",
							Description = "Moon's Dex, Chillz's Dex++ and VEX Explorer",
						}
					),
				},
			}
		),
	}
	for index, group in content do
		group.LayoutOrder = index
	end

	local pane = scope:New("ScrollingFrame")({
		Name = "Settings",
		Size = UDim2.fromScale(1, 1),
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
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}),
			scope:New("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 16),
			}),
			content,
		},
	})
	return { Instance = pane }
end

return SettingsPage
