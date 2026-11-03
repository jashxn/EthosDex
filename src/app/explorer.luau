--!nocheck
--[[
	The explorer: brand header, search and the virtualized tree.
	Rows are a fixed pool, as many as fit on screen, re-bound to whichever nodes are in view, so
	the cost doesn't grow with the game. A render happens when the tree reports a change, on
	scroll, and every half second (collapsed nodes don't listen, so their arrows refresh then).
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Env = require(Root.core.env)
local Api = require(Root.core.api)
local Tree = require(Root.core.tree)
local Search = require(Root.core.search)
local Settings = require(Root.core.settings)
local State = require(script.Parent.state)
local ClassIcon = require(script.Parent.classIcon)
local Menu = require(script.Parent.menu)
local Toast = require(script.Parent.toast)
local Actions = require(script.Parent.actions)
local History = require(script.Parent.history)
local Cursor = require(script.Parent.cursor)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local UserInputService = Env.service("UserInputService")
local RunService = Env.service("RunService")

local ROW = State.rowHeight() -- re-read every render, from the density setting
local INDENT = 14
local NIL_ROOT = Tree.NIL_ROOT
local MARK_TILE = Color3.fromRGB(15, 15, 18)

local Explorer = {}

function Explorer.new(scope)
	local tree = nil
	local dirty = true
	local hovering = false
	local hoveredRow = nil

	local markColors = scope:Computed(
		function(use)
			-- The theme's accent into the same accent with its hue turned, so both ends follow the theme.
			local accent = use(Theme.Accent)
			local hue, saturation, value = accent:ToHSV()
			return ColorSequence.new(accent, Color3.fromHSV((hue - 0.12) % 1, saturation, value))
		end
	)
	for _, key in { "Density", "ExplorerText", "UIScale" } do
		table.insert(
			scope,
			scope:Observer(Settings.state(key)):onChange(function()
				dirty = true
			end)
		)
	end
	local anchor = nil -- instance shift-click ranges start from
	local lastClick = { Instance = nil, At = 0 }

	local function buildTree()
		if tree then
			tree:destroy()
		end
		local nilSource = if Env.has("getnilinstances") and Settings.get("ShowNil") then Env.nilInstances
			else nil
		tree = Tree.new({
			Game = game,
			Roots = function()
				return game:GetChildren()
			end,
			Order = Api.order,
			NilInstances = nilSource,
			OnDirty = function()
				dirty = true
			end,
		})
		dirty = true
	end
	buildTree()

	local list -- the rows' ScrollingFrame, made below

	-- Search --------------------------------------------------------------------------------
	local query = scope:Value("")
	local status = scope:Value("")
	local generation = 0
	-- Where the tree was when a search began. Clearing the search goes back there, or to what
	-- you selected while searching.
	local before = nil
	-- The search shown now, so instances added while it's up join the results.
	local live = nil
	table.insert(
		scope,
		game.DescendantAdded:Connect(function(instance)
			if live and tree.Filter == live.Filter and Search.matches(instance, live.Conditions) then
				Search.mark(live.Filter, instance, game)
				tree:_dirty()
			end
		end)
	)
	table.insert(
		scope,
		scope:Observer(query):onChange(function()
			generation += 1
			local mine = generation
			local text = peek(query)
			if string.match(text, "^%s*$") then
				status:set("")
				tree:setFilter(nil)
				live = nil
				local saved = before
				before = nil
				if saved then
					local first = State.first()
					if first and first ~= saved.First then
						State.Hooks.reveal(first, true)
					else
						task.defer(function()
							list.CanvasPosition = saved.Scroll
						end)
					end
				end
				return
			end
			if before == nil then
				before = { Scroll = list.CanvasPosition, First = State.first() }
			end
			task.delay(
				0.25,
				function()
					if mine ~= generation then
						return
					end
					status:set("Searching")
					local nilList = if Settings.get("ShowNil") then Env.nilInstances() else nil
					local filter, count, capped = Search.run(
						game,
						text,
						nilList,
						function()
							return mine ~= generation
						end
					)
					if mine ~= generation or filter == nil then
						return
					end
					tree:setFilter(filter)
					live = { Filter = filter, Conditions = Search.parse(text) }
					status:set(
						if count == 0 then "No results"
							else `{count}{if capped then "+" else ""} found`
					)
				end
			)
		end)
	)

	local searchField, searchBox = Controls.Field(
		scope,
		{
			Name = "Search",
			Text = query,
			Placeholder = "Search   class:  isa:  tag:",
			Icon = "search",
			Height = 34,
			TrailingWidth = 84,
			Trailing = scope:New("Frame")({
				Name = "Trailing",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.fromOffset(80, 24),
				BackgroundTransparency = 1,
				[Children] = {
					Controls.Label(
						scope,
						{
							Size = UDim2.new(1, -26, 1, 0),
							Text = status,
							TextSize = 11,
							FontFace = Theme.Body,
							TextColor3 = Theme.Muted,
							TextXAlignment = Enum.TextXAlignment.Right,
						}
					),
					Controls.IconButton(
						scope,
						{
							Name = "Clear",
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, 0, 0.5, 0),
							Icon = "x",
							Size = 22,
							IconSize = 13,
							Visible = scope:Computed(function(use)
								return use(query) ~= ""
							end),
							OnActivated = function()
								query:set("")
							end,
						}
					),
				},
			}),
		}
	)
	searchField.Position = UDim2.fromOffset(10, 62)
	searchField.Size = UDim2.new(1, -16, 0, 34)

	-- List ----------------------------------------------------------------------------------
	list = scope:New("ScrollingFrame")({
		Name = "Tree",
		Position = UDim2.fromOffset(4, 104),
		Size = UDim2.new(1, -8, 1, -104 - 4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = if State.Touch then 0 else 4,
		ScrollBarImageColor3 = Theme.Ink,
		ScrollBarImageTransparency = 0.8,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		[OnEvent("MouseEnter")] = function()
			hovering = true
		end,
		[OnEvent("MouseLeave")] = function()
			hovering = false
			dirty = true
		end,
	})
	table.insert(
		scope,
		list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			dirty = true
		end)
	)
	table.insert(
		scope,
		list:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			dirty = true
		end)
	)

	local pool = {}
	local flat = {}

	local function hasChildren(node): boolean
		local instance = node.Instance
		if instance == NIL_ROOT then
			return true
		elseif tree.Filter then
			return bit32.band(tree.Filter[instance] or 0, 2) ~= 0
		elseif node.Children then
			for _, child in node.Children do
				if not child.Removed then
					return true
				end
			end
			return false
		end
		local ok, child = pcall(instance.FindFirstChildWhichIsA, instance, "Instance")
		return ok and child ~= nil
	end

	local function indexOf(instance): number?
		for index, node in flat do
			if node.Instance == instance then
				return index
			end
		end
		return nil
	end

	local function scrollTo(index: number)
		local top = list.CanvasPosition.Y
		local height = list.AbsoluteWindowSize.Y / State.scale()
		local y = (index - 1) * ROW
		if y < top or y + ROW > top + height then
			list.CanvasPosition = Vector2.new(0, math.max(0, y - height / 2))
		end
	end

	local function selectOnly(instance)
		State.select({ instance })
		anchor = instance
	end

	-- Drag rows onto another row to move them into it. A press only becomes a drag past a few
	-- pixels, and a selected row carries the whole selection.
	local drag = nil -- { Items, Start, Moving, Ghost }
	local function beginDrag(object, input)
		if object == nil or object == NIL_ROOT or State.Touch then
			return
		end
		drag = {
			Items = if State.isSelected(object) then table.clone(State.selection()) else { object },
			Start = Vector2.new(input.Position.X, input.Position.Y),
			Moving = false,
		}
	end
	local function endDrag()
		if drag and drag.Ghost then
			drag.Ghost:Destroy()
		end
		drag = nil
		dirty = true
	end
	table.insert(
		scope,
		UserInputService.InputChanged:Connect(
			function(input)
				if drag == nil or input.UserInputType ~= Enum.UserInputType.MouseMovement then
					return
				end
				local point = Vector2.new(input.Position.X, input.Position.Y)
				if not drag.Moving and (point - drag.Start).Magnitude > 6 then
					drag.Moving = true
					local first = drag.Items[1]
					drag.Ghost = Controls.Label(
						scope,
						{
							Name = "DragGhost",
							Parent = list:FindFirstAncestor("Layer"),
							Size = UDim2.fromOffset(0, 24),
							AutomaticSize = Enum.AutomaticSize.X,
							BackgroundColor3 = Theme.Surface,
							Text = if #drag.Items == 1 then first.Name else `{#drag.Items} items`,
							TextSize = 13,
							ZIndex = 80,
							[Children] = {
								scope:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
								scope:New("UIPadding")({
									PaddingLeft = UDim.new(0, 10),
									PaddingRight = UDim.new(0, 10),
								}),
							},
						}
					)
					drag.Ghost.BackgroundTransparency = 0.1 -- Label makes it see-through
				end
				if drag.Moving and drag.Ghost then
					local layer = drag.Ghost.Parent
					local at = (point - layer.AbsolutePosition) / State.scale()
					drag.Ghost.Position = UDim2.fromOffset(at.X + 14, at.Y + 10)
					dirty = true
				end
			end
		)
	)
	table.insert(
		scope,
		UserInputService.InputEnded:Connect(function(input)
			if drag == nil or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local target = hovering and hoveredRow and hoveredRow.Node and hoveredRow.Node.Instance
			local items = drag.Items
			local moving = drag.Moving
			endDrag()
			if moving and target and target ~= NIL_ROOT and table.find(items, target) == nil then
				Actions.move(items, target)
			end
		end)
	)
	table.insert(scope, endDrag)

	local function onClick(row)
		local node = row.Node
		if node == nil or Menu.justLongPressed() then
			return
		end
		local instance = node.Instance
		if instance == NIL_ROOT then
			tree:toggle(node)
			return
		end
		-- Picking a property's value: the click sets it and the selection stays put.
		local pickFor = peek(State.PickFor)
		if pickFor then
			State.PickFor:set(nil)
			pickFor.Pick(instance)
			return
		end
		local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
			or peek(State.MultiSelect)
		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		if shift and anchor then
			local from, to = indexOf(anchor), row.Index
			if from then
				local range = {}
				for index = math.min(from, to), math.max(from, to) do
					local object = flat[index].Instance
					if object ~= NIL_ROOT then
						table.insert(range, object)
					end
				end
				State.select(range)
				return
			end
		end
		if ctrl then
			local selection = table.clone(State.selection())
			local at = table.find(selection, instance)
			if at then
				table.remove(selection, at)
			else
				table.insert(selection, instance)
			end
			State.select(selection)
			anchor = instance
			return
		end
		local now = os.clock()
		if lastClick.Instance == instance and now - lastClick.At < 0.35 then
			-- Double-click: a script opens decompiled, anything else expands.
			if not Actions.openScript(instance) then
				tree:toggle(node)
			end
			lastClick.Instance = nil
		else
			lastClick.Instance, lastClick.At = instance, now
		end
		selectOnly(instance)
	end

	local function openMenu(row, point)
		local node = row.Node
		if node == nil then
			return
		end
		if node.Instance == NIL_ROOT then
			Menu.open(
				point,
				{
					{
						Text = "Refresh nil instances",
						Icon = "refresh-cw",
						OnActivated = function()
							tree:refreshNil()
						end,
					},
				}
			)
			return
		end
		if not State.isSelected(node.Instance) then
			selectOnly(node.Instance)
		end
		Menu.open(
			point,
			Actions.entries(
				State.selection(),
				{
					Expand = function(deep)
						for _, object in State.selection() do
							local target = tree.Nodes[object]
							if target then
								if deep then
									tree:setExpandedDeep(target, true)
								else
									tree:setExpanded(target, true)
								end
							end
						end
					end,
					Collapse = function()
						for _, object in State.selection() do
							local target = tree.Nodes[object]
							if target then
								tree:setExpandedDeep(target, false)
							end
						end
					end,
				}
			)
		)
	end

	local function newRow(index: number)
		local row = { Index = 0, Node = nil, Bound = nil, NameConnection = nil, Hovered = false }
		local arrow = Controls.Icon(
			scope,
			"chevron-right",
			12,
			{
				Name = "Chevron",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				ImageColor3 = Theme.Muted,
			}
		)
		local toggle = scope:New("TextButton")({
			Name = "Toggle",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 2, 0.5, 0),
			Size = UDim2.fromOffset(if State.Touch then 26 else 18, ROW),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 2,
			[OnEvent("Activated")] = function()
				if row.Node then
					tree:toggle(row.Node)
				end
			end,
			[Children] = arrow,
		})
		local icon = ClassIcon.new(
			scope,
			"Instance",
			{
				Name = "Class",
				AnchorPoint = Vector2.new(0, 0.5),
			}
		)
		local label = Controls.Label(
			scope,
			{
				Name = "Label",
				Size = UDim2.new(1, -40, 1, 0),
				TextSize = 13,
				FontFace = Theme.Body,
				TextColor3 = Theme.Ink,
			}
		)
		local highlight = scope:New("Frame")({
			Name = "Selected",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.78,
			Visible = false,
			[Children] = scope:New("UICorner")({ CornerRadius = UDim.new(0, 7) }),
		})
		local frame = scope:New("TextButton")({
			Name = "Row" .. index,
			Parent = list,
			Size = UDim2.new(1, -4, 0, ROW),
			BackgroundColor3 = Theme.Ink,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Visible = false,
			[OnEvent("Activated")] = function()
				onClick(row)
			end,
			-- Middle-click views it, or stops viewing it. A left press may become a drag.
			[OnEvent("InputBegan")] = function(input)
				local object = row.Node and row.Node.Instance
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					beginDrag(object, input)
				elseif input.UserInputType == Enum.UserInputType.MouseButton3
					and object
					and object ~= NIL_ROOT
					and Actions.viewable(object) then
					if peek(State.Viewing) == object then
						Actions.stopViewing()
					else
						Actions.view(object)
					end
				end
			end,
			[OnEvent("MouseEnter")] = function()
				row.Hovered = true
				hoveredRow = row
				dirty = true
			end,
			[OnEvent("MouseLeave")] = function()
				row.Hovered = false
				if hoveredRow == row then
					hoveredRow = nil
				end
				dirty = true
			end,
			[Children] = {
				scope:New("UICorner")({ CornerRadius = UDim.new(0, 7) }),
				highlight,
				toggle,
				icon,
				label,
			},
		})
		row.Frame, row.Toggle, row.Arrow, row.Icon, row.Label = frame, toggle, arrow, icon, label
		row.Selected = highlight
		for _, connection in Menu.bind(
			frame,
			function(point)
				openMenu(row, point)
			end
		) do
			table.insert(scope, connection)
		end
		return row
	end

	local function bindName(row, instance)
		if row.Bound == instance then
			return
		end
		if row.NameConnection then
			row.NameConnection:Disconnect()
			row.NameConnection = nil
		end
		row.Bound = instance
		if instance ~= NIL_ROOT and typeof(instance) == "Instance" then
			local ok, signal = pcall(instance.GetPropertyChangedSignal, instance, "Name")
			if ok then
				row.NameConnection = signal:Connect(function()
					row.Label.Text = instance.Name
					tree:renamed(instance)
				end)
			end
		end
	end

	local selectedSet = {}
	table.insert(
		scope,
		scope:Observer(State.Selection):onBind(function()
			table.clear(selectedSet)
			for _, object in State.selection() do
				selectedSet[object] = true
			end
			dirty = true
		end)
	)

	local function render()
		dirty = false
		ROW = State.rowHeight()
		local textSize = Settings.get("ExplorerText")
		flat = tree:flat()
		list.CanvasSize = UDim2.fromOffset(0, #flat * ROW + 8)
		local height = list.AbsoluteWindowSize.Y / State.scale()
		local first = math.max(1, math.floor(list.CanvasPosition.Y / ROW) + 1)
		local needed = math.ceil(height / ROW) + 2
		while #pool < needed do
			table.insert(pool, newRow(#pool + 1))
		end
		for slot, row in pool do
			local index = first + slot - 1
			local node = if slot <= needed then flat[index] else nil
			if node == nil then
				if row.Frame.Visible then
					row.Frame.Visible = false
					row.Node = nil
					bindName(row, nil)
				end
				continue
			end
			row.Node, row.Index = node, index
			local instance = node.Instance
			local name, className
			if instance == NIL_ROOT then
				name, className = "Nil instances", "Folder"
			else
				local ok
				ok, name, className = pcall(function()
					return instance.Name, instance.ClassName
				end)
				if not ok then
					name, className = "<locked>", "Instance"
				end
			end
			local depth = node.Depth * INDENT
			local frame = row.Frame
			frame.Position = UDim2.fromOffset(2, (index - 1) * ROW + 4)
			frame.Size = UDim2.new(1, -4, 0, ROW)
			row.Toggle.Size = UDim2.fromOffset(if State.Touch then 26 else 18, ROW)
			row.Label.TextSize = textSize
			frame.Visible = true
			local open = hasChildren(node)
			row.Toggle.Position = UDim2.new(0, depth, 0.5, 0)
			row.Arrow.Visible = open
			row.Arrow.Rotation = if open and tree:isOpen(node) then 90 else 0
			local iconX = depth + (if State.Touch then 26 else 18)
			row.Icon.Position = UDim2.new(0, iconX, 0.5, 0)
			ClassIcon.apply(row.Icon, className)
			row.Label.Position = UDim2.fromOffset(iconX + 22, 0)
			row.Label.Size = UDim2.new(1, -(iconX + 26), 1, 0)
			row.Label.Text = name
			row.Label.TextTransparency = if instance ~= NIL_ROOT
					and tree.Filter
					and bit32.band(tree.Filter[instance] or 0, 1) == 0 then 0.45
				else 0
			local selected = selectedSet[instance] == true
			row.Selected.Visible = selected
			local dropping = drag ~= nil and drag.Moving and row.Hovered
			frame.BackgroundTransparency = if dropping then 0.85
				elseif row.Hovered and not selected then 0.95
				else 1
			bindName(row, instance)
		end
		-- The hover glow follows the row under the pointer (pick mode drives it instead).
		if not peek(State.Picking) then
			local hovered = hoveredRow and hovering and hoveredRow.Node and hoveredRow.Node.Instance
			State.Hovered:set(if hovered ~= NIL_ROOT then hovered else nil)
		end
	end

	local elapsed = 0
	table.insert(
		scope,
		RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			if dirty or tree.Dirty or elapsed > 0.5 then
				elapsed = 0
				render()
			end
		end)
	)

	-- Keyboard, while the pointer is over the list: arrows move and open, F2 renames, Delete
	-- deletes, Ctrl+C/X/V copy, cut and paste into, Ctrl+D duplicates.
	table.insert(
		scope,
		UserInputService.InputBegan:Connect(
			function(input, processed)
				if processed or not hovering or UserInputService:GetFocusedTextBox() then
					return
				end
				local key = input.KeyCode
				local current = State.first()
				local index = current and indexOf(current)
				if key == Enum.KeyCode.Up or key == Enum.KeyCode.Down then
					local target = if index then index + (if key == Enum.KeyCode.Up then -1 else 1)
						else 1
					local node = flat[math.clamp(target, 1, math.max(1, #flat))]
					if node and node.Instance ~= NIL_ROOT then
						selectOnly(node.Instance)
						scrollTo(math.clamp(target, 1, #flat))
					end
				elseif (key == Enum.KeyCode.Right or key == Enum.KeyCode.Left) and index then
					local node = flat[index]
					if key == Enum.KeyCode.Right then
						if not tree:isOpen(node) then
							tree:setExpanded(node, true)
						end
					elseif tree:isOpen(node) and hasChildren(node) then
						tree:setExpanded(node, false)
					elseif node.Parent and node.Parent.Instance ~= NIL_ROOT then
						selectOnly(node.Parent.Instance)
					end
				elseif key == Enum.KeyCode.Return and index then
					-- Enter does what a double-click does.
					if not Actions.openScript(current) then
						tree:toggle(flat[index])
					end
				elseif key == Enum.KeyCode.F2 and current then
					State.Hooks.rename(current)
				elseif key == Enum.KeyCode.Delete and current then
					Actions.delete(State.selection())
				elseif current
					and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
						or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
					if key == Enum.KeyCode.C or key == Enum.KeyCode.X then
						Actions.hold(State.selection(), key == Enum.KeyCode.X)
					elseif key == Enum.KeyCode.V then
						Actions.paste(current)
					elseif key == Enum.KeyCode.D then
						Actions.duplicate(State.selection())
					end
				end
			end
		)
	)

	-- Rename in place: a box over the row.
	State.Hooks.rename = function(instance)
		local index = indexOf(instance)
		if index == nil then
			return
		end
		scrollTo(index)
		render()
		local row = nil
		for _, candidate in pool do
			if candidate.Node and candidate.Node.Instance == instance then
				row = candidate
			end
		end
		if row == nil then
			return
		end
		local box = Instance.new("TextBox")
		box.Name = "Rename"
		box.Position = row.Label.Position
		box.Size = row.Label.Size
		box.BackgroundColor3 = peek(Theme.Surface)
		box.BorderSizePixel = 0
		box.Text = instance.Name
		box.FontFace = peek(Theme.Body)
		box.TextSize = Settings.get("ExplorerText")
		box.TextColor3 = peek(Theme.Ink)
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.ClearTextOnFocus = false
		box.ZIndex = 5
		box.Parent = row.Frame
		box:CaptureFocus()
		box.SelectionStart, box.CursorPosition = 1, #box.Text + 1
		local before = instance.Name
		box.FocusLost:Connect(function(enter)
			if enter and box.Text ~= "" and box.Text ~= before then
				local ok, problem = Env.setProperty(instance, "Name", box.Text)
				if ok then
					History.push(
						"rename",
						function()
							instance.Name = before
						end
					)
				else
					Toast.show("Couldn't rename: " .. tostring(problem), "error")
				end
			end
			box:Destroy()
		end)
	end

	State.Hooks.reveal = function(instance, keepSelection)
		local node = tree:reveal(instance)
		if node == nil then
			Toast.show("That instance isn't in the tree.", "error")
			return
		end
		if not keepSelection then
			selectOnly(instance)
		end
		flat = tree:flat()
		local index = indexOf(instance)
		if index then
			task.defer(function()
				scrollTo(index)
			end)
		end
	end

	State.Hooks.selectChildren = function(list)
		local children = {}
		for _, object in list do
			State.Hooks.reveal(object, true)
			local node = tree.Nodes[object]
			if node then
				tree:setExpanded(node, true)
			end
			for _, child in object:GetChildren() do
				table.insert(children, child)
			end
		end
		State.select(children)
	end

	State.Hooks.rebuildTree = function()
		local selection = State.selection()
		buildTree()
		for _, object in selection do
			tree:reveal(object)
		end
	end

	State.Hooks.collapseAll = function()
		tree:collapseAll()
	end

	-- Pick mode (Dex's "select object"): the part under the pointer glows, and the next click in
	-- the world selects it. The activity card shows it and cancels it.
	local function partAt(position): Instance?
		local camera = workspace.CurrentCamera
		local ray = camera:ScreenPointToRay(position.X, position.Y)
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000)
		return hit and hit.Instance
	end
	local function shows(object): boolean
		if object.BackgroundTransparency < 1 then
			return true
		elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
			return object.Image ~= "" and object.ImageTransparency < 1
		elseif object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			return object.Text ~= "" and object.TextTransparency < 1
		end
		return false
	end
	-- A game's custom cursor is a small image pinned to the pointer (by its centre or corner);
	-- it's always on top, so it would be picked every time.
	local function cursorLike(object, position): boolean
		local size = object.AbsoluteSize
		if object.Active or size.X > 96 or size.Y > 96 then
			return false
		end
		-- AbsolutePosition is in the same space as the pointer, top bar or not.
		local at = object.AbsolutePosition
		return (at + size / 2 - position).Magnitude < 12 or (at - position).Magnitude < 12
	end
	-- The game's own UI under the point (the topmost thing you can see), never ours.
	local function guiAt(position): Instance?
		local playerGui = State.LocalPlayer and State.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui == nil then
			return nil
		end
		local ok, hits = pcall(playerGui.GetGuiObjectsAtPosition, playerGui, position.X, position.Y)
		if ok then
			for _, object in hits do
				if shows(object) and not cursorLike(object, position) then
					return object
				end
			end
		end
		return nil
	end
	local function overUs(position): boolean
		local layer = list:FindFirstAncestor("Layer")
		return layer ~= nil and Cursor.over(layer, position)
	end
	local function pickAt(position, processed: boolean): Instance?
		if overUs(position) then
			return nil
		end
		return guiAt(position) or (if processed then nil else partAt(position))
	end
	local pickConnections = {}
	local function stopPicking()
		for _, connection in pickConnections do
			connection:Disconnect()
		end
		table.clear(pickConnections)
		State.Hovered:set(nil)
	end
	local function setPicking(on: boolean)
		State.Picking:set(on)
	end
	table.insert(
		scope,
		scope:Observer(State.Picking):onChange(
			function()
				stopPicking()
				if not peek(State.Picking) then
					return
				end
				table.insert(
					pickConnections,
					RunService.RenderStepped:Connect(function()
						local point = UserInputService:GetMouseLocation()
							- Env.service("GuiService"):GetGuiInset()
						State.Hovered:set(pickAt(point, false))
					end)
				)
				table.insert(
					pickConnections,
					UserInputService.InputBegan:Connect(
						function(input, processed)
							local kind = input.UserInputType
							if kind ~= Enum.UserInputType.MouseButton1
								and kind ~= Enum.UserInputType.Touch then
								return
							end
							local position = Vector2.new(input.Position.X, input.Position.Y)
							if overUs(position) then
								return -- our own buttons, like the card's Cancel
							end
							local hit = pickAt(position, processed)
							setPicking(false)
							if hit then
								State.Hooks.reveal(hit)
							end
						end
					)
				)
			end
		)
	)
	table.insert(scope, stopPicking)

	local header = scope:New("Frame")({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundTransparency = 1,
		[Children] = {
			-- The mark: a dark tile whatever the theme, the E in the theme's accent gradient.
			scope:New("Frame")({
				Name = "Mark",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 14, 0.5, 2),
				Size = UDim2.fromOffset(32, 32),
				BackgroundColor3 = MARK_TILE,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
					scope:New("UIStroke")({
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.new(1, 1, 1),
						Transparency = 0.9,
					}),
					Controls.Icon(
						scope,
						"ethos-e",
						18,
						{
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							ImageColor3 = Color3.new(1, 1, 1),
						}
					),
				},
			}),
			Controls.Label(
				scope,
				{
					Position = UDim2.fromOffset(56, 13),
					Size = UDim2.new(1, -56, 0, 18),
					Text = "Ethos Dex",
					TextSize = 14,
				}
			),
			Controls.Label(
				scope,
				{
					Position = UDim2.fromOffset(56, 31),
					Size = UDim2.new(1, -56, 0, 16),
					Text = Env.executor,
					TextSize = 12,
					FontFace = Theme.Body,
					TextColor3 = Theme.Muted,
				}
			),
			-- The app adds its buttons (console, settings, hide, close) after these.
			scope:New("Frame")({
				Name = "Actions",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 2),
				Size = UDim2.fromOffset(0, 28),
				AutomaticSize = Enum.AutomaticSize.X,
				-- Covers a long title; as see-through as the panel so it doesn't show as a box.
				BackgroundColor3 = Theme.Surface,
				BackgroundTransparency = scope:Computed(function(use)
					return 1 - math.clamp(use(Settings.state("PanelOpacity")), 0.3, 1)
				end),
				BorderSizePixel = 0,
				ZIndex = 2,
				[Children] = {
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Controls.IconButton(
						scope,
						{
							Name = "MultiSelect",
							Icon = "list-checks",
							Size = 28,
							LayoutOrder = 1,
							Visible = State.Touch,
							OnActivated = function()
								State.MultiSelect:set(not peek(State.MultiSelect))
								Toast.show(
									if peek(State.MultiSelect) then "Multi-select on: taps add to the selection"
										else "Multi-select off"
								)
							end,
						}
					),
					Controls.IconButton(
						scope,
						{
							Name = "Pick",
							Icon = scope:Computed(function(use)
								return if use(State.Picking) then "x" else "crosshair"
							end),
							Size = 28,
							LayoutOrder = 2,
							OnActivated = function()
								setPicking(not peek(State.Picking))
							end,
						}
					),
				},
			}),
		},
	})
	-- Icons draw as a font glyph in a child TextLabel, so the gradient has to sit on that.
	local markGradient = scope:New("UIGradient")({ Rotation = 45, Color = markColors })
	local function tintGlyph(child)
		if child.Name == "IconGlyph" then
			markGradient.Parent = child
		end
	end
	local markIcon = header.Mark.Icon
	for _, child in markIcon:GetChildren() do
		tintGlyph(child)
	end
	table.insert(scope, markIcon.ChildAdded:Connect(tintGlyph))

	local pane = scope:New("Frame")({
		Name = "Explorer",
		BackgroundTransparency = 1,
		[Children] = {
			header,
			searchField,
			list,
		},
	})

	return {
		Instance = pane,
		Header = header,
		SearchBox = searchBox,
		Tree = function()
			return tree
		end,
	}
end

return Explorer
