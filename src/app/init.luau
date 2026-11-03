--!nocheck
-- Builds the GUI: the window, the explorer, and the panel with its topbar, tabs and pages.

local Root = script.Parent
local Fusion = require(Root.packages.fusion)
local States = require(Root.packages.states)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local TabPill = require(Root.ui.tabPill)
local Env = require(Root.core.env)
local Api = require(Root.core.api)
local Path = require(Root.core.path)
local Settings = require(Root.core.settings)
local State = require(script.state)
local Menu = require(script.menu)
local Toast = require(script.toast)
local Picker = require(script.picker)
local Actions = require(script.actions)
local Window = require(script.window)
local Explorer = require(script.explorer)
local Properties = require(script.properties)
local ScriptViewer = require(script.scriptViewer)
local Console = require(script.console)
local Preview = require(script.preview)
local SettingsPage = require(script.settingsPage)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local UserInputService = Env.service("UserInputService")

local TOPBAR = 46
local TABS = { "Properties", "Script", "Console", "Preview" }

local App = {}

local function breadcrumb(scope)
	local holder = scope:New("Frame")({
		Name = "Breadcrumb",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		[Children] = scope:New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local partScope = nil
	local function rebuild()
		if partScope then
			Fusion.doCleanup(partScope)
		end
		partScope = scope:innerScope()
		local first = State.first()
		local chain = {}
		if first then
			local ok, result = pcall(Path.chain, first, game)
			chain = if ok then result else { first }
		end
		local start = math.max(1, #chain - 2)
		local order = 0
		local function add(child)
			order += 1
			child.LayoutOrder = order
			child.Parent = holder
		end
		if first == nil then
			add(
				Controls.Label(
					partScope,
					{
						AutomaticSize = Enum.AutomaticSize.X,
						Size = UDim2.fromOffset(0, 30),
						Text = "Nothing selected",
						TextSize = 13,
						TextColor3 = Theme.Muted,
						TextTruncate = Enum.TextTruncate.None,
					}
				)
			)
			return
		end
		if start > 1 then
			add(
				Controls.Label(
					partScope,
					{
						AutomaticSize = Enum.AutomaticSize.X,
						Size = UDim2.fromOffset(0, 30),
						Text = "…",
						TextSize = 13,
						TextColor3 = Theme.Muted,
						TextTruncate = Enum.TextTruncate.None,
					}
				)
			)
		end
		for index = start, #chain do
			local object = chain[index]
			if index > start or start > 1 then
				add(Controls.Icon(partScope, "chevron-right", 12, { ImageColor3 = Theme.Faint }))
			end
			local last = index == #chain
			local ok, name = pcall(function()
				return object.Name
			end)
			add(
				partScope:New("TextButton")({
					Name = "Crumb",
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 30),
					BackgroundTransparency = 1,
					Text = if ok then name else "?",
					FontFace = if last then Theme.Title else Theme.Body,
					TextSize = 13,
					TextColor3 = if last then Theme.Ink else Theme.Muted,
					[OnEvent("Activated")] = function()
						State.Hooks.reveal(object)
					end,
					[Children] = scope:New("UISizeConstraint")({ MaxSize = Vector2.new(180, 30) }),
				})
			)
		end
	end
	table.insert(scope, scope:Observer(State.Selection):onBind(rebuild))
	return holder
end

function App.start()
	local scope = Fusion.scoped(Fusion)

	-- Theme follows the setting.
	States.Theme:set(Settings.get("Theme"))
	table.insert(
		scope,
		scope:Observer(Settings.state("Theme")):onChange(function()
			States.Theme:set(Settings.get("Theme"))
		end)
	)

	local gui = Instance.new("ScreenGui")
	gui.Name = Env.safeName(game:GetService("HttpService"):GenerateGUID(false))
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10000
	gui.IgnoreGuiInset = false
	Env.protect(gui)
	gui.Parent = Env.guiParent()
	table.insert(scope, gui)

	local layer = scope:New("Frame")({
		Name = "Layer",
		Parent = gui,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	Menu.setLayer(
		layer,
		function()
			return 1
		end
	)
	Toast.setLayer(layer)
	Picker.setLayer(layer)

	local explorer = Explorer.new(scope)

	State.Hooks.insert = function(parent)
		if not Api.hasDump() then
			Toast.show("Insert object needs the Roblox API, which didn't load.", "error")
			return
		end
		Picker.open({
			Title = "Insert into " .. parent.Name,
			Items = Api.creatable(),
			ClassIcons = true,
			OnPick = function(className)
				Actions.insert(parent, className)
			end,
		})
	end

	-- Pages
	local pages = {
		Properties = Properties.new(scope:innerScope()).Instance,
		Script = ScriptViewer.new(scope:innerScope()).Instance,
		Console = Console.new(scope:innerScope()).Instance,
		Preview = Preview.new(scope:innerScope()).Instance,
		Settings = SettingsPage.new(scope:innerScope()).Instance,
	}
	local content = scope:New("Frame")({
		Name = "Content",
		Position = UDim2.fromOffset(0, TOPBAR + 38),
		Size = UDim2.new(1, 0, 1, -(TOPBAR + 38)),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	})
	for name, page in pages do
		page.Parent = content
		scope:Hydrate(page)({
			Visible = scope:Computed(function(use)
				return use(State.Tab) == name
			end),
		})
	end

	local tabs = {}
	for index, name in TABS do
		table.insert(
			tabs,
			TabPill(
				scope,
				name,
				index,
				scope:Computed(function(use)
					return use(State.Tab) == name
				end),
				function()
					State.Tab:set(name)
				end
			)
		)
	end

	local window -- assigned below; the topbar's buttons call into it
	local function topButton(name, icon, order, onActivated, visible)
		return Controls.IconButton(
			scope,
			{
				Name = name,
				Icon = icon,
				Size = 30,
				LayoutOrder = order,
				Visible = visible,
				OnActivated = onActivated,
			}
		)
	end

	local destroy
	local maximizedIcon = scope:Value("maximize-2")
	local topbar = scope:New("Frame")({
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, TOPBAR),
		BackgroundTransparency = 1,
		Active = true,
		[Children] = {
			Controls.IconButton(
				scope,
				{
					Name = "Back",
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Icon = "chevron-left",
					Size = 30,
					Visible = State.Compact,
					OnActivated = function()
						State.MobileView:set("explorer")
					end,
				}
			),
			scope:New("Frame")({
				Name = "Crumbs",
				Position = scope:Computed(function(use)
					return UDim2.fromOffset(if use(State.Compact) then 44 else 16, 8)
				end),
				Size = scope:Computed(function(use)
					return UDim2.new(1, -(if use(State.Compact) then 44 else 16) - 176, 0, 30)
				end),
				BackgroundTransparency = 1,
				[Children] = breadcrumb(scope),
			}),
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
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					topButton(
						"More",
						"ellipsis",
						1,
						function()
							local selection = State.selection()
							if #selection == 0 then
								Toast.show("Select something first")
								return
							end
							local button = topbar.Actions.More
							local at = button.AbsolutePosition
								+ Vector2.new(-190, button.AbsoluteSize.Y + 4)
							Menu.open(
								at,
								Actions.entries(
									selection,
									{
										Expand = function()
											for _, object in State.selection() do
												State.Hooks.reveal(object, true)
											end
										end,
										Collapse = State.Hooks.collapseAll,
									}
								)
							)
						end
					),
					topButton(
						"Settings",
						"settings",
						2,
						function()
							State.open(
								if peek(State.Tab) == "Settings" then "Properties" else "Settings"
							)
						end
					),
					topButton(
						"Minimize",
						"minus",
						3,
						function()
							window.Toggle()
						end
					),
					topButton(
						"Maximize",
						maximizedIcon,
						4,
						function()
							window.Maximized:set(not peek(window.Maximized))
							maximizedIcon:set(
								if peek(window.Maximized) then "minimize-2" else "maximize-2"
							)
						end,
						scope:Computed(function(use)
							return not use(State.Compact)
						end)
					),
					topButton(
						"Close",
						"x",
						5,
						function()
							destroy()
						end
					),
				},
			}),
		},
	})

	local tabRow = scope:New("ScrollingFrame")({
		Name = "Tabs",
		Position = UDim2.fromOffset(10, TOPBAR),
		Size = UDim2.new(1, -20, 0, 34),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		[Children] = {
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			tabs,
		},
	})

	local panel = scope:New("Frame")({
		Name = "PanelContent",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[Children] = { topbar, tabRow, content },
	})

	window = Window.new(
		scope,
		{
			Layer = layer,
			Explorer = explorer.Instance,
			Panel = panel,
			Scale = function()
				return 1
			end,
		}
	)
	window.DragHandle(explorer.Header)
	window.DragHandle(topbar)

	-- Keybind
	table.insert(
		scope,
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed or UserInputService:GetFocusedTextBox() then
				return
			end
			local key = Settings.get("ToggleKey")
			if input.KeyCode.Name == key then
				window.Toggle()
			end
		end)
	)

	-- The first selected part or model glows in the world.
	local glow = Instance.new("Highlight")
	glow.Name = "Selection"
	glow.FillTransparency = 0.85
	glow.OutlineTransparency = 0
	glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	glow.Parent = gui
	table.insert(scope, glow)
	table.insert(
		scope,
		scope:Observer(State.Selection):onBind(function()
			local first = State.first()
			local ok, isWorld = pcall(function()
				return first ~= nil
					and (first:IsA("BasePart") or first:IsA("Model") and not first:IsA("WorldRoot"))
					and first:IsDescendantOf(workspace)
			end)
			glow.Adornee = if ok and isWorld then first else nil
			glow.OutlineColor = peek(Theme.Accent)
			glow.FillColor = peek(Theme.Accent)
		end)
	)

	-- The API loads in the background; the tree re-sorts by Studio's order when it lands.
	task.spawn(function()
		Api.load()
		if Api.Status == "failed" then
			Toast.show(tostring(Api.Problem), "error")
		end
		if State.Hooks.rebuildTree then
			State.Hooks.rebuildTree()
		end
	end)

	local destroyed = false
	destroy = function()
		if destroyed then
			return
		end
		destroyed = true
		Menu.close()
		Picker.close()
		local tree = explorer.Tree()
		if tree then
			tree:destroy()
		end
		Fusion.doCleanup(scope)
		if gui.Parent then
			gui:Destroy()
		end
	end

	return {
		Gui = gui,
		Window = window,
		Destroy = destroy,
		State = State,
		Tree = explorer.Tree,
	}
end

return App
