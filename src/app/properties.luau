--!nocheck
--[[
	The properties panel. The list of rows (category headers, properties, attributes) is built
	from the API dump when the selection or a setting changes; rows on screen are a pool bound to
	it, each holding every editor kind and showing the one its value needs. Values are read
	fresh on each render, which runs when the selected instance reports a change, on scroll, and
	when the list is rebuilt. Edits go to every selected instance.
]]

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Scrollbar = require(Root.ui.scrollbar)
local Env = require(Root.core.env)
local Api = require(Root.core.api)
local Values = require(Root.core.values)
local Settings = require(Root.core.settings)
local State = require(script.Parent.state)
local ClassIcon = require(script.Parent.classIcon)
local Menu = require(script.Parent.menu)
local Picker = require(script.Parent.picker)
local Toast = require(script.Parent.toast)
local Actions = require(script.Parent.actions)
local History = require(script.Parent.history)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local RunService = Env.service("RunService")
local CollectionService = Env.service("CollectionService")

local ROW = State.rowHeight() + 4 -- re-read every render, from the density setting
local ORDER = {
	"Data",
	"Appearance",
	"Text",
	"Image",
	"Behavior",
	"Transform",
	"Pivot",
	"Part",
	"Collision",
	"Assembly",
	"Physics",
	"Surface",
	"Shape",
	"Character",
	"Camera",
	"Scripting",
}
local ORDER_INDEX = {}
for index, name in ORDER do
	ORDER_INDEX[name] = index
end
local BASIC = { "Name", "ClassName", "Parent", "Archivable" }

local Properties = {}

local function escape(text: string): string
	return (string.gsub(string.gsub(text, "\\", "\\\\"), "\n", "\\n"))
end

local function unescape(text: string): string
	return (string.gsub(
		text,
		"\\(.)",
		function(char)
			return if char == "n" then "\n" elseif char == "t" then "\t" else char
		end
	))
end

function Properties.new(scope)
	local query = scope:Value("")
	local collapsed = {}
	local expanded = {} -- property names whose components are open, kept across selections
	local entries = {}
	local dirty = true
	local target = nil
	local targetConnections = {}

	local header = scope:New("Frame")({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
	})
	local headerIcon = ClassIcon.new(
		scope,
		"Instance",
		{
			Parent = header,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
		}
	)
	local headerName = Controls.Label(
		scope,
		{
			Parent = header,
			Position = UDim2.fromOffset(40, 6),
			Size = UDim2.new(1, -54, 0, 18),
			TextSize = 14,
		}
	)
	local headerClass = Controls.Label(
		scope,
		{
			Parent = header,
			Position = UDim2.fromOffset(40, 23),
			Size = UDim2.new(1, -54, 0, 16),
			TextSize = 12,
			FontFace = Theme.Body,
			TextColor3 = Theme.Muted,
		}
	)

	local filterField = Controls.Field(
		scope,
		{
			Name = "Filter",
			Text = query,
			Placeholder = "Filter properties",
			Icon = "list-filter",
			Height = 32,
		}
	)
	filterField.Position = UDim2.fromOffset(10, 48)
	filterField.Size = UDim2.new(1, -20, 0, 32)

	local notice = Controls.Label(
		scope,
		{
			Name = "Notice",
			Position = UDim2.fromOffset(14, 84),
			Size = UDim2.new(1, -28, 0, 18),
			TextSize = 11,
			FontFace = Theme.Body,
			TextColor3 = Theme.Caution,
			Visible = false,
		}
	)

	local list = scope:New("ScrollingFrame")({
		Name = "Rows",
		Position = UDim2.fromOffset(6, 88),
		Size = UDim2.new(1, -12, 1, -94),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
	})
	Scrollbar.attach(scope, list)
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

	local empty = Controls.Empty(
		scope,
		{
			Name = "Empty",
			Icon = "mouse-pointer-click",
			Title = "Select something in the explorer",
		}
	)
	empty.AnchorPoint = Vector2.new(0.5, 0.5)
	empty.Position = UDim2.fromScale(0.5, 0.45)

	-- Reading and writing --------------------------------------------------------------------

	local function read(entry): (boolean, any)
		if entry.Kind == "component" then
			local ok, value = read(entry.Parent)
			for _, part in (ok and Values.components(value)) or {} do
				if part.Name == entry.Name then
					return true, part.Value
				end
			end
			return false, nil
		elseif entry.Kind == "attr" then
			return pcall(target.GetAttribute, target, entry.Name)
		elseif entry.Kind == "tags" then
			return pcall(function()
				return table.concat(CollectionService:GetTags(target), ", ")
			end)
		end
		return Env.getProperty(target, entry.Name)
	end

	local function set(object, entry, value)
		if entry.Kind == "attr" then
			return pcall(object.SetAttribute, object, entry.Name, value)
		end
		return Env.setProperty(object, entry.Name, value)
	end

	local function write(entry, value)
		local component = if entry.Kind == "component" then entry.Name else nil
		if component then
			entry = entry.Parent
		end
		local failures, problem = 0, nil
		local before = {}
		for _, object in State.selection() do
			-- Not an if-expression: those keep only the first value, which would lose old.
			local had, old = false, nil
			if entry.Kind == "attr" then
				had, old = pcall(object.GetAttribute, object, entry.Name)
			else
				had, old = Env.getProperty(object, entry.Name)
			end
			-- A component edit rebuilds each object's own value, so its other components stay.
			local new = if not component then value
				elseif had then Values.withComponent(old, component, value)
				else nil
			local ok, failure = false, `no {component}`
			if new ~= nil or not component then
				ok, failure = set(object, entry, new)
			end
			if ok and had then
				table.insert(before, { object, old })
			elseif not ok then
				failures += 1
				problem = failure
			end
		end
		if #before > 0 then
			History.push(
				`edit {entry.Name}`,
				function()
					for _, pair in before do
						set(pair[1], entry, pair[2])
					end
				end
			)
		end
		if failures > 0 then
			Toast.show(`Couldn't set {entry.Name}: {problem}`, "error")
		end
		dirty = true
	end

	-- Building the row list ------------------------------------------------------------------

	local function propertyList(object)
		local list = {}
		if Api.hasDump() then
			local showHidden = Settings.get("ShowHidden") and Env.has("gethiddenproperty")
			local showDeprecated = Settings.get("ShowDeprecated")
			for _, property in Api.properties(object.ClassName) do
				local tags = property.Tags
				if tags.Deprecated and not showDeprecated then
					continue
				end
				if (tags.Hidden or tags.NotScriptable) and not showHidden then
					continue
				end
				if Env.getProperty(object, property.Name) then
					table.insert(
						list,
						{
							Kind = "prop",
							Name = property.Name,
							Category = property.Category,
							ReadOnly = tags.ReadOnly == true,
							Hidden = tags.Hidden or tags.NotScriptable,
							EnumType = if property.ValueType.Category == "Enum" then property.ValueType.Name
								else nil,
							Object = property.ValueType.Category == "Class",
						}
					)
				end
			end
		elseif Env.has("getproperties") then
			local ok, found = pcall(Env.raw.getproperties, object)
			if ok and type(found) == "table" then
				for name in found do
					if type(name) == "string" then
						table.insert(list, { Kind = "prop", Name = name, Category = "Properties" })
					end
				end
				table.sort(
					list,
					function(a, b)
						return a.Name < b.Name
					end
				)
			end
		end
		if #list == 0 then
			for _, name in BASIC do
				table.insert(
					list,
					{
						Kind = "prop",
						Name = name,
						Category = "Data",
						ReadOnly = name == "ClassName",
					}
				)
			end
		end
		return list
	end

	local function build()
		entries = {}
		local selection = State.selection()
		target = selection[1]
		if target == nil then
			return
		end
		local props = propertyList(target)
		-- With several selected, only properties they all have.
		if #selection > 1 then
			local shared = {}
			for _, property in props do
				shared[property.Name] = true
			end
			local seenClass = { [target.ClassName] = true }
			for index = 2, #selection do
				local className = selection[index].ClassName
				if not seenClass[className] then
					seenClass[className] = true
					local names = {}
					for _, property in propertyList(selection[index]) do
						names[property.Name] = true
					end
					for name in shared do
						if not names[name] then
							shared[name] = nil
						end
					end
				end
			end
			local kept = {}
			for _, property in props do
				if shared[property.Name] then
					table.insert(kept, property)
				end
			end
			props = kept
		end

		local text = string.lower(peek(query))
		local groups, names = {}, {}
		local function add(category, entry)
			if text ~= "" and not string.find(string.lower(entry.Name), text, 1, true) then
				return
			end
			if groups[category] == nil then
				groups[category] = {}
				table.insert(names, category)
			end
			table.insert(groups[category], entry)
		end
		for _, property in props do
			add(property.Category, property)
		end
		local ok, attributes = pcall(target.GetAttributes, target)
		if ok then
			local attributeNames = {}
			for name in attributes do
				table.insert(attributeNames, name)
			end
			table.sort(attributeNames)
			for _, name in attributeNames do
				add("Attributes", { Kind = "attr", Name = name, Category = "Attributes" })
			end
		end
		local tagged, tags = pcall(CollectionService.GetTags, CollectionService, target)
		if tagged and #tags > 0 then
			add("Tags", { Kind = "tags", Name = "Tags", Category = "Tags", ReadOnly = true })
		end
		table.sort(
			names,
			function(a, b)
				local ra = ORDER_INDEX[a]
					or (if a == "Attributes" then 999 elseif a == "Tags" then 1000 else 500)
				local rb = ORDER_INDEX[b]
					or (if b == "Attributes" then 999 elseif b == "Tags" then 1000 else 500)
				if ra ~= rb then
					return ra < rb
				end
				return a < b
			end
		)
		for _, category in names do
			table.insert(entries, { Kind = "header", Name = category, Count = #groups[category] })
			if not collapsed[category] then
				for _, entry in groups[category] do
					table.insert(entries, entry)
					local has, value = false, nil
					if expanded[entry.Name] then
						has, value = read(entry)
					end
					for _, part in (has and Values.components(value)) or {} do
						table.insert(
							entries,
							{
								Kind = "component",
								Name = part.Name,
								Parent = entry,
								ReadOnly = entry.ReadOnly,
								Hidden = entry.Hidden,
							}
						)
					end
				end
			end
		end
	end

	local function retarget()
		for _, connection in targetConnections do
			connection:Disconnect()
		end
		table.clear(targetConnections)
		build()
		if target then
			table.insert(
				targetConnections,
				target.Changed:Connect(function()
					dirty = true
				end)
			)
			table.insert(
				targetConnections,
				target.AttributeChanged:Connect(function()
					build()
					dirty = true
				end)
			)
			local okName, name = pcall(function()
				return target.Name
			end)
			headerName.Text = if okName then name else "?"
			local count = #State.selection()
			headerClass.Text = if count > 1 then `{target.ClassName} · {count} selected`
				else target.ClassName
			ClassIcon.apply(headerIcon, target.ClassName)
		end
		local failed = Api.Status == "failed"
		notice.Visible = failed and target ~= nil
		notice.Text = if failed then "Roblox API unavailable: showing basic properties" else ""
		list.Position = UDim2.fromOffset(6, if notice.Visible then 104 else 88)
		list.Size = UDim2.new(1, -12, 1, if notice.Visible then -110 else -94)
		dirty = true
	end

	table.insert(scope, scope:Observer(State.Selection):onBind(retarget))
	table.insert(scope, scope:Observer(query):onChange(retarget))
	for _, key in { "ShowHidden", "ShowDeprecated" } do
		table.insert(scope, scope:Observer(Settings.state(key)):onChange(retarget))
	end
	Api.onReady(retarget)

	-- Rows ----------------------------------------------------------------------------------

	local pool = {}

	local function openEnum(row)
		local entry = row.Entry
		local ok, current = read(entry)
		local enumType = entry.EnumType
			or (ok and typeof(current) == "EnumItem" and tostring(current.EnumType))
		local enum = enumType and Enum[enumType]
		if enum == nil then
			return
		end
		local items = {}
		for _, item in enum:GetEnumItems() do
			table.insert(items, item.Name)
		end
		local function choose(name)
			write(entry, enum[name])
		end
		if #items <= 12 then
			local menuItems = {}
			for _, name in items do
				table.insert(
					menuItems,
					{
						Text = name,
						Icon = if ok and current and current.Name == name then "check" else nil,
						OnActivated = function()
							choose(name)
						end,
					}
				)
			end
			local at = row.EnumButton.AbsolutePosition
			Menu.open(Vector2.new(at.X, at.Y + row.EnumButton.AbsoluteSize.Y + 2), menuItems)
		else
			Picker.open({
				Title = entry.Name,
				Items = items,
				Current = ok and current and current.Name or nil,
				OnPick = choose,
			})
		end
	end

	local function commit(row)
		local entry = row.Entry
		if entry == nil or entry.ReadOnly then
			return
		end
		local ok, current = read(entry)
		if not ok then
			return
		end
		local text = row.Box.Text
		if typeof(current) == "string" then
			text = unescape(text)
		end
		if text == row.Shown then
			return
		end
		local parsed, value = Values.parse(text, current)
		if parsed then
			write(entry, value)
		else
			Toast.show(`Not a valid {typeof(current)}`, "error")
			dirty = true
		end
	end

	local function newRow(index)
		local row = { Entry = nil, Shown = nil, OnT = scope:Value(0), PressT = scope:Value(0) }
		local frame = scope:New("Frame")({
			Name = "Row" .. index,
			Parent = list,
			Size = UDim2.new(1, -4, 0, ROW),
			BackgroundColor3 = Theme.Ink,
			BackgroundTransparency = 1,
			Visible = false,
		})
		row.Frame = frame
		row.Fold = scope:New("TextButton")({
			Name = "Fold",
			Parent = frame,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			[OnEvent("Activated")] = function()
				local entry = row.Entry
				if entry then
					-- Only headers and compound values show this button.
					local flags = if entry.Kind == "header" then collapsed else expanded
					flags[entry.Name] = not flags[entry.Name]
					build()
					dirty = true
				end
			end,
		})
		row.Chevron = Controls.Icon(
			scope,
			"chevron-right",
			12,
			{
				Parent = frame,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 6, 0.5, 0),
				ImageColor3 = Theme.Muted,
			}
		)
		row.Name = Controls.Label(
			scope,
			{
				Name = "PropName",
				Parent = frame,
				Position = UDim2.fromOffset(10, 0),
				TextSize = 13,
				FontFace = Theme.Body,
				TextColor3 = Theme.Ink2,
			}
		)
		row.Line = scope:New("Frame")({
			Name = "Line",
			Parent = frame,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Theme.Ink,
			BackgroundTransparency = 0.95,
			BorderSizePixel = 0,
		})
		row.Swatch = scope:New("Frame")({
			Name = "Swatch",
			Parent = frame,
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(14, 14),
			Visible = false,
			[Children] = {
				scope:New("UICorner")({ CornerRadius = UDim.new(0, 4) }),
				scope:New("UIStroke")({ Color = Theme.Ink, Transparency = 0.8 }),
			},
		})
		row.Box = scope:New("TextBox")({
			Name = "Value",
			Parent = frame,
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			FontFace = Theme.Body,
			TextSize = 13,
			TextColor3 = Theme.Ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = "",
			[OnEvent("FocusLost")] = function()
				commit(row)
			end,
		})
		local interaction = Controls.Interaction(scope)
		row.Toggle = scope:New("TextButton")(
			Controls.merge(
				{
					Name = "Toggle",
					Parent = frame,
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.fromOffset(40, 24),
					BackgroundTransparency = 1,
					Text = "",
					Visible = false,
					[OnEvent("Activated")] = function()
						local entry = row.Entry
						if entry and not entry.ReadOnly then
							local ok, current = read(entry)
							if ok and type(current) == "boolean" then
								write(entry, not current)
							end
						end
					end,
					[Children] = (function()
						local switch = Controls.Switch(scope, row.OnT, interaction.PressT)
						switch.AnchorPoint = Vector2.new(0, 0.5)
						switch.Position = UDim2.fromScale(0, 0.5)
						return switch
					end)(),
				},
				interaction.Events
			)
		)
		row.EnumCaption = Controls.Label(
			scope,
			{
				Name = "Caption",
				Size = UDim2.new(1, -20, 1, 0),
				TextSize = 13,
				FontFace = Theme.Body,
				TextColor3 = Theme.Ink,
			}
		)
		row.EnumButton = scope:New("TextButton")({
			Name = "Enum",
			Parent = frame,
			BackgroundTransparency = 1,
			Text = "",
			Visible = false,
			[OnEvent("Activated")] = function()
				if row.Entry and not row.Entry.ReadOnly then
					openEnum(row)
				end
			end,
			[Children] = {
				row.EnumCaption,
				Controls.Icon(
					scope,
					"chevrons-up-down",
					12,
					{
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -4, 0.5, 0),
						ImageColor3 = Theme.Muted,
					}
				),
			},
		})
		row.Link = scope:New("TextButton")({
			Name = "Link",
			Parent = frame,
			BackgroundTransparency = 1,
			FontFace = Theme.Body,
			TextSize = 13,
			TextColor3 = Theme.Accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = "",
			Visible = false,
			[OnEvent("Activated")] = function()
				local entry = row.Entry
				if entry then
					local ok, value = read(entry)
					if ok and typeof(value) == "Instance" then
						State.Hooks.reveal(value)
					end
				end
			end,
		})
		for _, connection in Menu.bind(
			frame,
			function(point)
				local entry = row.Entry
				if entry == nil or entry.Kind == "header" then
					return
				elseif entry.Kind == "component" then
					entry = entry.Parent
				end
				local ok, value = read(entry)
				local code = if ok then Values.code(value) else "nil"
				local items = {
					{
						Text = "Copy value",
						Icon = "copy",
						OnActivated = function()
							Actions.copy(if ok then Values.format(value) else "", "value")
						end,
					},
					{
						Text = "Copy as code",
						Icon = "code",
						Detail = "obj.Prop = value",
						OnActivated = function()
							local path = Actions.path(target)
							Actions.copy(
								if entry.Kind == "attr" then `{path}:SetAttribute("{entry.Name}", {code})`
									elseif entry.Kind == "tags" then `-- tags: {if ok then value else ""}`
									else `{path}.{entry.Name} = {code}`,
								"code"
							)
						end,
					},
					{
						Text = "Copy value as Luau",
						Icon = "braces",
						OnActivated = function()
							Actions.copy(code, "value")
						end,
					},
					{
						Text = "Copy name",
						Icon = "type",
						OnActivated = function()
							Actions.copy(entry.Name, "name")
						end,
					},
				}
				-- An object-valued property can be set by picking its new value in the explorer.
				if entry.Kind == "prop"
					and (entry.Object or ok and typeof(value) == "Instance")
					and not entry.ReadOnly then
					table.insert(items, 1, "divider")
					table.insert(
						items,
						1,
						{
							Text = "Clear",
							Icon = "x",
							Detail = "Set to nil",
							OnActivated = function()
								write(entry, nil)
							end,
						}
					)
					table.insert(
						items,
						1,
						{
							Text = "Pick in explorer",
							Icon = "crosshair",
							Detail = "Click the new value",
							OnActivated = function()
								State.PickFor:set({
									Text = `Click the new {entry.Name} in the explorer`,
									Pick = function(object)
										write(entry, object)
									end,
								})
							end,
						}
					)
				end
				Menu.open(point, items)
			end
		) do
			table.insert(scope, connection)
		end
		return row
	end

	local function show(row, kind)
		row.Box.Visible = kind == "box"
		row.Toggle.Visible = kind == "toggle"
		row.EnumButton.Visible = kind == "enum"
		row.Link.Visible = kind == "link"
	end

	local function render()
		dirty = false
		list.Visible = target ~= nil
		filterField.Visible = target ~= nil
		header.Visible = target ~= nil
		empty.Visible = target == nil
		if target == nil then
			return
		end
		ROW = State.rowHeight() + 4
		local textSize = Settings.get("PropertiesText")
		list.CanvasSize = UDim2.fromOffset(0, #entries * ROW + 8)
		local scale = State.scale()
		local width = list.AbsoluteWindowSize.X / scale
		local nameWidth = math.clamp(
			math.floor(width * Settings.get("NameColumn")),
			80,
			math.max(80, width - 110)
		)
		local valueX = nameWidth + 8
		local height = list.AbsoluteWindowSize.Y / scale
		local first = math.max(1, math.floor(list.CanvasPosition.Y / ROW) + 1)
		local needed = math.ceil(height / ROW) + 2
		while #pool < needed do
			table.insert(pool, newRow(#pool + 1))
		end
		local ink = peek(Theme.Ink)
		local faint = peek(Theme.Faint)
		for slot, row in pool do
			local index = first + slot - 1
			local entry = if slot <= needed then entries[index] else nil
			local frame = row.Frame
			if entry == nil then
				frame.Visible = false
				row.Entry = nil
				continue
			end
			if row.Entry ~= entry and row.Box:IsFocused() then
				row.Box:ReleaseFocus()
			end
			row.Entry = entry
			frame.Visible = true
			frame.Position = UDim2.fromOffset(2, (index - 1) * ROW + 4)
			frame.Size = UDim2.new(1, -4, 0, ROW)
			row.Name.TextSize = textSize
			row.Box.TextSize = textSize
			row.EnumCaption.TextSize = textSize
			row.Link.TextSize = textSize
			if entry.Kind == "header" then
				frame.BackgroundTransparency = 0.97
				row.Fold.Visible = true
				row.Fold.Size = UDim2.fromScale(1, 1)
				row.Chevron.Visible = true
				row.Chevron.Position = UDim2.new(0, 6, 0.5, 0)
				row.Chevron.Rotation = if collapsed[entry.Name] then 0 else 90
				row.Name.Position = UDim2.fromOffset(24, 0)
				row.Name.Size = UDim2.new(1, -30, 1, 0)
				row.Name.Text = entry.Name
				row.Name.FontFace = peek(Theme.Title)
				row.Line.Visible = false
				row.Swatch.Visible = false
				show(row, nil)
				continue
			end
			frame.BackgroundTransparency = 1
			row.Line.Visible = true
			local indent = if entry.Kind == "component" then 14 else 0
			row.Name.Position = UDim2.fromOffset(14 + indent, 0)
			row.Name.Size = UDim2.new(0, nameWidth - 10 - indent, 1, 0)
			row.Name.Text = entry.Name
			row.Name.FontFace = peek(Theme.Body)
			row.Name.TextTransparency = if entry.Hidden then 0.4 else 0
			local ok, value = read(entry)
			local kind = typeof(value)
			local opens = ok and Values.components(value) ~= nil
			row.Fold.Visible = opens
			row.Chevron.Visible = opens
			if opens then
				row.Fold.Size = UDim2.new(0, nameWidth, 1, 0)
				row.Chevron.Position = UDim2.new(0, 1, 0.5, 0)
				row.Chevron.Rotation = if expanded[entry.Name] then 90 else 0
			end
			local x = valueX
			local swatch = ok and (kind == "Color3" or kind == "BrickColor")
			row.Swatch.Visible = swatch
			if swatch then
				row.Swatch.BackgroundColor3 = if kind == "Color3" then value else value.Color
				row.Swatch.Position = UDim2.new(0, x, 0.5, 0)
				x += 22
			end
			local valueSize = UDim2.new(1, -x - 8, 1, 0)
			if not ok then
				show(row, "box")
				row.Box.Text = "?"
				row.Box.TextEditable = false
			elseif kind == "boolean" then
				show(row, "toggle")
				row.Toggle.Position = UDim2.new(0, x, 0.5, 0)
				row.OnT:set(if value then 1 else 0)
			elseif kind == "EnumItem" then
				show(row, "enum")
				row.EnumButton.Position = UDim2.fromOffset(x, 0)
				row.EnumButton.Size = valueSize
				row.EnumCaption.Text = value.Name
				row.EnumCaption.TextColor3 = if entry.ReadOnly then faint else ink
			elseif kind == "Instance" then
				show(row, "link")
				row.Link.Position = UDim2.fromOffset(x, 0)
				row.Link.Size = valueSize
				row.Link.Text = value.Name
			else
				show(row, "box")
				row.Box.Position = UDim2.fromOffset(x, 0)
				row.Box.Size = valueSize
				local editable = not entry.ReadOnly and (Values.TEXT_TYPES[kind] == true)
				row.Box.TextEditable = editable
				row.Box.TextColor3 = if editable then ink else faint
				if not row.Box:IsFocused() then
					local text = if value == nil then "nil"
						elseif kind == "string" then escape(value)
						else Values.format(value)
					row.Shown = if kind == "string" then value else text
					row.Box.Text = text
				end
			end
		end
	end

	table.insert(
		scope,
		RunService.Heartbeat:Connect(function()
			if dirty then
				render()
			end
		end)
	)
	-- Theme changes recolour the read-only text.
	table.insert(
		scope,
		scope:Observer(Theme.Ink):onChange(function()
			dirty = true
		end)
	)
	for _, key in { "Density", "PropertiesText", "NameColumn", "UIScale" } do
		table.insert(
			scope,
			scope:Observer(Settings.state(key)):onChange(function()
				dirty = true
			end)
		)
	end

	local pane = scope:New("Frame")({
		Name = "Properties",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[Children] = { header, filterField, notice, list, empty },
	})
	return { Instance = pane }
end

return Properties
