--!nocheck
--[[
	The explorer column: brand header, search, the virtualized tree and the credits footer.
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

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local UserInputService = Env.service("UserInputService")
local RunService = Env.service("RunService")

local ROW = State.ROW
local INDENT = 14
local NIL_ROOT = Tree.NIL_ROOT
local DISCORD = "jasha.n"

local Explorer = {}

function Explorer.new(scope)
	local tree = nil
	local dirty = true
	local hovering = false
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

	-- Search --------------------------------------------------------------------------------
	local query = scope:Value("")
	local status = scope:Value("")
	local generation = 0
	table.insert(
		scope,
		scope:Observer(query):onChange(function()
			generation += 1
			local mine = generation
			local text = peek(query)
			if string.match(text, "^%s*$") then
				status:set("")
				tree:setFilter(nil)
				return
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
	local list = scope:New("ScrollingFrame")({
		Name = "Tree",
		Position = UDim2.fromOffset(4, 104),
		Size = UDim2.new(1, -8, 1, -104 - 58),
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
		local height = list.AbsoluteWindowSize.Y
		local y = (index - 1) * ROW
		if y < top or y + ROW > top + height then
			list.CanvasPosition = Vector2.new(0, math.max(0, y - height / 2))
		end
	end

	local function selectOnly(instance)
		State.select({ instance })
		anchor = instance
	end

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
			tree:toggle(node)
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
			[OnEvent("MouseEnter")] = function()
				row.Hovered = true
				dirty = true
			end,
			[OnEvent("MouseLeave")] = function()
				row.Hovered = false
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
		flat = tree:flat()
		list.CanvasSize = UDim2.fromOffset(0, #flat * ROW + 8)
		local height = list.AbsoluteWindowSize.Y
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
			frame.BackgroundTransparency = if row.Hovered and not selected then 0.95 else 1
			bindName(row, instance)
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

	-- Keyboard: arrows move and open, F2 renames, Delete deletes, while the pointer is over the list.
	table.insert(
		scope,
		UserInputService.InputBegan:Connect(function(input, processed)
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
			elseif key == Enum.KeyCode.F2 and current then
				State.Hooks.rename(current)
			elseif key == Enum.KeyCode.Delete and current then
				Actions.delete(State.selection())
			end
		end)
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
		box.TextSize = 13
		box.TextColor3 = peek(Theme.Ink)
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.ClearTextOnFocus = false
		box.ZIndex = 5
		box.Parent = row.Frame
		box:CaptureFocus()
		box.SelectionStart, box.CursorPosition = 1, #box.Text + 1
		box.FocusLost:Connect(function(enter)
			if enter and box.Text ~= "" then
				local ok, problem = Env.setProperty(instance, "Name", box.Text)
				if not ok then
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

	-- Phones: a pill to open the panel for the selection.
	local inspect = Controls.Button(
		scope,
		{
			Name = "Inspect",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -12, 1, -66),
			Text = "Inspect",
			TrailingIcon = "chevron-right",
			Height = 34,
			Visible = scope:Computed(function(use)
				return use(State.Compact) and #use(State.Selection) > 0
			end),
			OnActivated = function()
				State.open("Properties")
			end,
		}
	)
	inspect.ZIndex = 4

	local footer = scope:New("TextButton")({
		Name = "Credits",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -8),
		Size = UDim2.new(1, -16, 0, 44),
		BackgroundColor3 = Theme.Ink,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		[OnEvent("Activated")] = function()
			if Env.clipboard(DISCORD) then
				Toast.show("Copied Discord username jasha.n", "success")
			else
				Toast.show("Discord: jasha.n")
			end
		end,
		[Children] = {
			scope:New("Frame")({
				Name = "Badge",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 6, 0.5, 0),
				Size = UDim2.fromOffset(32, 32),
				BackgroundColor3 = Theme.Ink,
				BackgroundTransparency = 0.92,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
					Controls.Icon(
						scope,
						"discord",
						17,
						{
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
						}
					),
				},
			}),
			Controls.Label(
				scope,
				{
					Position = UDim2.fromOffset(48, 5),
					Size = UDim2.new(1, -52, 0, 18),
					Text = "jashan",
					TextSize = 13,
				}
			),
			Controls.Label(
				scope,
				{
					Position = UDim2.fromOffset(48, 22),
					Size = UDim2.new(1, -52, 0, 16),
					Text = "@" .. DISCORD,
					TextSize = 12,
					FontFace = Theme.Body,
					TextColor3 = Theme.Muted,
				}
			),
		},
	})

	local header = scope:New("Frame")({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundTransparency = 1,
		[Children] = {
			scope:New("Frame")({
				Name = "Mark",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 14, 0.5, 2),
				Size = UDim2.fromOffset(32, 32),
				BackgroundColor3 = Theme.Ink,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
					Controls.Icon(
						scope,
						"ethos-e",
						18,
						{
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							ImageColor3 = Theme.Surface,
						}
					),
				},
			}),
			Controls.Label(
				scope,
				{
					Position = UDim2.fromOffset(56, 13),
					Size = UDim2.new(1, -110, 0, 18),
					Text = "Ethos Dex",
					TextSize = 14,
				}
			),
			Controls.Label(
				scope,
				{
					Position = UDim2.fromOffset(56, 31),
					Size = UDim2.new(1, -110, 0, 16),
					Text = Env.executor,
					TextSize = 12,
					FontFace = Theme.Body,
					TextColor3 = Theme.Muted,
				}
			),
			Controls.IconButton(
				scope,
				{
					Name = "MultiSelect",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 2),
					Icon = "list-checks",
					Size = 28,
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
		},
	})

	local pane = scope:New("Frame")({
		Name = "Explorer",
		BackgroundTransparency = 1,
		[Children] = {
			header,
			searchField,
			list,
			inspect,
			footer,
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
