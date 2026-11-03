--!nocheck
--[[
	The explorer's model. A node per instance the user has opened down to; children load the
	first time their parent opens and from then on follow ChildAdded/ChildRemoved on that one
	parent, so a game with 100k instances only costs what has been opened. Removals only mark
	the node; `flat()` drops marked nodes while it walks. `flat()` returns the visible rows in
	order and is what the virtualized list draws, rebuilt at most once a frame by the caller
	when `onDirty` fires.

	A filter (from a search) replaces expansion: a map of instance -> bits, 1 for a match and 2
	for an ancestor of one. Every instance in it is shown, and ancestors are open unless the user
	closes them.
]]

local Tree = {}
Tree.__index = Tree

local NIL_ROOT = table.freeze({ Name = "Nil instances", ClassName = "Folder", Virtual = true })
Tree.NIL_ROOT = NIL_ROOT

export type Node = {
	Instance: any,
	Parent: Node?,
	Children: { Node }?,
	Expanded: boolean,
	Closed: boolean, -- closed by the user while a filter is on
	Removed: boolean,
	Unsorted: boolean,
	Depth: number,
	Order: number,
	Key: string,
	Seq: number,
	Connections: { RBXScriptConnection }?,
}

-- options: Roots () -> { Instance }, Order (className) -> number, NilInstances (() -> {Instance})?,
-- OnDirty () -> ()
function Tree.new(options)
	local self = setmetatable({}, Tree)
	self.Options = options
	self.Nodes = {} -- Instance -> Node
	self.Roots = {}
	self.Filter = nil
	self.Dirty = true
	self.Seq = 0
	self.FlatCache = {}
	self.RootConnections = {}
	self:_buildRoots()
	return self
end

function Tree:_dirty()
	if not self.Dirty then
		self.Dirty = true
		if self.Options.OnDirty then
			self.Options.OnDirty()
		end
	end
end

function Tree:_node(instance, parent)
	self.Seq += 1
	local ok, name, className = pcall(function()
		return instance.Name, instance.ClassName
	end)
	local node = {
		Instance = instance,
		Parent = parent,
		Children = nil,
		Expanded = false,
		Closed = false,
		Removed = false,
		Unsorted = false,
		Depth = 0,
		Order = if ok then self.Options.Order(className) else 1000,
		Key = if ok then string.lower(name) else "",
		Seq = self.Seq,
		Connections = nil,
	}
	if instance ~= NIL_ROOT then
		self.Nodes[instance] = node
	end
	return node
end

local function compare(a, b)
	if a.Order ~= b.Order then
		return a.Order < b.Order
	elseif a.Key ~= b.Key then
		return a.Key < b.Key
	end
	return a.Seq < b.Seq
end

function Tree:_buildRoots()
	for _, root in self.Options.Roots() do
		table.insert(self.Roots, self:_node(root, nil))
	end
	if self.Options.NilInstances then
		table.insert(self.Roots, self:_node(NIL_ROOT, nil))
	end
	table.sort(
		self.Roots,
		function(a, b)
			if a.Instance == NIL_ROOT or b.Instance == NIL_ROOT then
				return b.Instance == NIL_ROOT and a.Instance ~= NIL_ROOT
			end
			return compare(a, b)
		end
	)
	-- New services appear at the top level.
	local game = self.Options.Game
	if game then
		table.insert(
			self.RootConnections,
			game.ChildAdded:Connect(function(child)
				if self.Nodes[child] == nil then
					local node = self:_node(child, nil)
					table.insert(
						self.Roots,
						#self.Roots + (if self.Options.NilInstances then 0 else 1),
						node
					)
					self:_dirty()
				end
			end)
		)
	end
end

function Tree:_forget(node)
	if node.Connections then
		for _, connection in node.Connections do
			connection:Disconnect()
		end
		node.Connections = nil
	end
	node.Removed = true
	if self.Nodes[node.Instance] == node then
		self.Nodes[node.Instance] = nil
	end
	if node.Children then
		for _, child in node.Children do
			self:_forget(child)
		end
	end
end

function Tree:_load(node)
	if node.Children then
		return
	end
	node.Children = {}
	local instance = node.Instance
	if instance == NIL_ROOT then
		for _, object in self.Options.NilInstances() or {} do
			if self.Nodes[object] == nil then
				table.insert(node.Children, self:_node(object, node))
			end
		end
		table.sort(node.Children, compare)
		return
	end
	local ok, children = pcall(instance.GetChildren, instance)
	if not ok then
		return
	end
	for _, child in children do
		table.insert(node.Children, self:_node(child, node))
	end
	table.sort(node.Children, compare)
	node.Connections = {
		instance.ChildAdded:Connect(function(child)
			if node.Removed or (self.Nodes[child] and not self.Nodes[child].Removed) then
				return
			end
			table.insert(node.Children, self:_node(child, node))
			node.Unsorted = true
			self:_dirty()
		end),
		instance.ChildRemoved:Connect(function(child)
			local removed = self.Nodes[child]
			if removed and removed.Parent == node then
				self:_forget(removed)
				self:_dirty()
			end
		end),
	}
end

-- Re-reads the nil-instance list (it has no events).
function Tree:refreshNil()
	for _, root in self.Roots do
		if root.Instance == NIL_ROOT and root.Children then
			for _, child in root.Children do
				self:_forget(child)
			end
			root.Children = nil
			if root.Expanded then
				self:_load(root)
			end
		end
	end
	self:_dirty()
end

-- A node's name changed: its sort key and its parent's order are stale.
function Tree:renamed(instance)
	local node = self.Nodes[instance]
	if node then
		local ok, name = pcall(function()
			return instance.Name
		end)
		if ok and string.lower(name) ~= node.Key then
			node.Key = string.lower(name)
			if node.Parent then
				node.Parent.Unsorted = true
			end
			self:_dirty()
		end
	end
end

function Tree:isOpen(node): boolean
	if self.Filter then
		return not node.Closed
	end
	return node.Expanded
end

function Tree:setExpanded(node, expanded: boolean)
	if self.Filter then
		node.Closed = not expanded
	else
		node.Expanded = expanded
	end
	if expanded then
		self:_load(node)
	end
	self:_dirty()
end

function Tree:toggle(node)
	self:setExpanded(node, not self:isOpen(node))
end

-- Opens or closes a node and everything under it that's loaded (or loads, when opening).
function Tree:setExpandedDeep(node, expanded: boolean, limit: number?)
	local budget = limit or 2000
	local function walk(current)
		if budget <= 0 then
			return
		end
		budget -= 1
		self:setExpanded(current, expanded)
		if current.Children then
			for _, child in current.Children do
				if not child.Removed then
					walk(child)
				end
			end
		end
	end
	walk(node)
end

function Tree:collapseAll()
	for _, node in self.Nodes do
		node.Expanded = false
	end
	for _, root in self.Roots do
		root.Expanded = false
	end
	self:_dirty()
end

-- The node for an instance, opening every ancestor so it is visible. nil when it isn't in the
-- tree (destroyed, or parented to nil and nil instances are off).
function Tree:reveal(instance)
	if instance == nil then
		return nil
	end
	local chain = {}
	local current = instance
	local game = self.Options.Game
	while current ~= nil and current ~= game do
		table.insert(chain, 1, current)
		local known = self.Nodes[current]
		if known and known.Parent == nil then
			break -- a top-level row
		end
		local ok, parent = pcall(function()
			return current.Parent
		end)
		current = if ok then parent else nil
	end
	local parentNode = nil
	if current == nil then
		-- Parented to nil at the top: it lives under the nil root.
		for _, root in self.Roots do
			if root.Instance == NIL_ROOT then
				parentNode = root
			end
		end
		if parentNode == nil then
			return nil
		end
		self:setExpanded(parentNode, true)
		if self.Nodes[chain[1]] == nil then
			self:refreshNil()
			self:setExpanded(parentNode, true)
		end
	end
	local node = nil
	for _, object in chain do
		node = self.Nodes[object]
		if node == nil and parentNode then
			self:setExpanded(parentNode, true)
			node = self.Nodes[object]
		end
		if node == nil then
			return nil
		end
		parentNode = node
	end
	local up = node and node.Parent
	while up do
		self:setExpanded(up, true)
		up = up.Parent
	end
	return node
end

-- filter: set of instances to show (matches and their ancestors), or nil for the normal tree.
function Tree:setFilter(filter)
	self.Filter = filter
	if filter then
		for _, node in self.Nodes do
			node.Closed = false
		end
		for _, root in self.Roots do
			root.Closed = false
		end
	end
	self:_dirty()
end

local function compact(children)
	local write = 0
	for read = 1, #children do
		local child = children[read]
		if not child.Removed then
			write += 1
			children[write] = child
		end
	end
	for index = #children, write + 1, -1 do
		children[index] = nil
	end
end

-- The visible rows, top to bottom.
function Tree:flat(): { Node }
	if not self.Dirty then
		return self.FlatCache
	end
	self.Dirty = false
	local flat = table.create(#self.FlatCache)
	local filter = self.Filter
	local function push(node, depth)
		node.Depth = depth
		table.insert(flat, node)
		if not self:isOpen(node) then
			return
		end
		-- With a filter only ancestors of matches (bit 2) have rows under them.
		if filter and bit32.band(filter[node.Instance] or 0, 2) == 0 then
			return
		end
		self:_load(node)
		local children = node.Children
		if children == nil then
			return
		end
		if node.Unsorted then
			compact(children)
			table.sort(children, compare)
			node.Unsorted = false
		end
		local hasRemoved = false
		for _, child in children do
			if child.Removed then
				hasRemoved = true
			elseif filter == nil or filter[child.Instance] then
				push(child, depth + 1)
			end
		end
		if hasRemoved then
			compact(children)
		end
	end
	for _, root in self.Roots do
		if not root.Removed
			and (filter == nil
				or filter[root.Instance]
				or root.Instance == NIL_ROOT and filter[NIL_ROOT]) then
			push(root, 0)
		end
	end
	self.FlatCache = flat
	return flat
end

function Tree:destroy()
	for _, connection in self.RootConnections do
		connection:Disconnect()
	end
	for _, node in self.Roots do
		self:_forget(node)
	end
	table.clear(self.Nodes)
	table.clear(self.Roots)
end

return Tree
