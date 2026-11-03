--!nocheck
-- Builds the GUI: the dock (explorer over properties) on the right and the floating window
-- (script viewer, console, preview, settings), like Dex.

local Root = script.Parent
local Fusion = require(Root.packages.fusion)
local States = require(Root.packages.states)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local TabPill = require(Root.ui.tabPill)
local Env = require(Root.core.env)
local Api = require(Root.core.api)
local Settings = require(Root.core.settings)
local State = require(script.state)
local Menu = require(script.menu)
local Toast = require(script.toast)
local Picker = require(script.picker)
local Actions = require(script.actions)
local Window = require(script.window)
local Dock = require(script.dock)
local Explorer = require(script.explorer)
local Properties = require(script.properties)
local ScriptViewer = require(script.scriptViewer)
local Console = require(script.console)
local Preview = require(script.preview)
local SettingsPage = require(script.settingsPage)

local Children = Fusion.Children
local peek = Fusion.peek

local UserInputService = Env.service("UserInputService")

local TOPBAR = 46
local COMPACT_WIDTH = 720
local TABS = { "Script", "Console", "Preview", "Settings" }

local App = {}

local function scale()
	return 1
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
	Menu.setLayer(layer, scale)
	Toast.setLayer(layer)
	Picker.setLayer(layer)

	local room = scope:Value(layer.AbsoluteSize)
	local function measure()
		room:set(layer.AbsoluteSize)
		State.Compact:set(layer.AbsoluteSize.X < COMPACT_WIDTH)
	end
	measure()
	table.insert(scope, layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure))

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

	-- The floating window's pages
	local pages = {
		Script = ScriptViewer.new(scope:innerScope()).Instance,
		Console = Console.new(scope:innerScope()).Instance,
		Preview = Preview.new(scope:innerScope()).Instance,
		Settings = SettingsPage.new(scope:innerScope()).Instance,
	}
	local content = scope:New("Frame")({
		Name = "Content",
		Position = UDim2.fromOffset(0, TOPBAR),
		Size = UDim2.new(1, 0, 1, -TOPBAR),
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

	local function iconButton(name, icon, order, onActivated, visible)
		return Controls.IconButton(
			scope,
			{
				Name = name,
				Icon = icon,
				Size = 28,
				LayoutOrder = order,
				Visible = visible,
				OnActivated = onActivated,
			}
		)
	end

	local window -- assigned below; the topbar's buttons call into it
	local maximizedIcon = scope:Value("maximize-2")
	local topbar = scope:New("Frame")({
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, TOPBAR),
		BackgroundTransparency = 1,
		Active = true,
		[Children] = {
			scope:New("ScrollingFrame")({
				Name = "Tabs",
				Position = UDim2.fromOffset(10, 6),
				Size = UDim2.new(1, -90, 0, 34),
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
			}),
			scope:New("Frame")({
				Name = "Actions",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(0, 28),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				[Children] = {
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					iconButton(
						"Maximize",
						maximizedIcon,
						1,
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
					iconButton(
						"Close",
						"x",
						2,
						function()
							State.WindowOpen:set(false)
						end
					),
				},
			}),
		},
	})

	local dock = Dock.new(
		scope,
		{
			Layer = layer,
			Room = room,
			Explorer = explorer.Instance,
			Properties = Properties.new(scope:innerScope()).Instance,
			Footer = explorer.Footer,
			Scale = scale,
		}
	)

	window = Window.new(
		scope,
		{
			Layer = layer,
			Room = room,
			Content = scope:New("Frame")({
				Name = "WindowContent",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				[Children] = { topbar, content },
			}),
			Reserve = dock.Reserve,
			Shown = dock.Open,
			Scale = scale,
		}
	)
	window.DragHandle(topbar)

	local destroy
	-- The dock header's buttons, after the explorer's own.
	for index, button in {
		iconButton(
			"Console",
			"terminal",
			10,
			function()
				if peek(State.WindowOpen) and peek(State.Tab) == "Console" then
					State.WindowOpen:set(false)
				else
					State.open("Console")
				end
			end
		),
		iconButton(
			"Settings",
			"settings",
			11,
			function()
				if peek(State.WindowOpen) and peek(State.Tab) == "Settings" then
					State.WindowOpen:set(false)
				else
					State.open("Settings")
				end
			end
		),
		iconButton(
			"Hide",
			"minus",
			12,
			function()
				dock.Toggle()
			end
		),
		iconButton(
			"Close",
			"x",
			13,
			function()
				destroy()
			end
		),
	} do
		button.Parent = explorer.Header.Actions
	end

	-- Keybind
	table.insert(
		scope,
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed or UserInputService:GetFocusedTextBox() then
				return
			end
			if input.KeyCode.Name == Settings.get("ToggleKey") then
				dock.Toggle()
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
		Actions.stopViewing()
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
		Dock = dock,
		Window = window,
		Destroy = destroy,
		State = State,
		Tree = explorer.Tree,
	}
end

return App
