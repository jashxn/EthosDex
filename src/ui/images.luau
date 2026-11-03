--!nocheck

local RuntimeAssets = require(script.Parent.Parent.utils.runtimeAssets)
local Molto = require(script.Parent.Parent.assets.molto)
local EthosIcons = require(script.Parent.Parent.assets.ethosIcons)

local UPLOADS = {}
for _, uploads in ipairs({
	require(script.Parent.icons.cascader),
	require(script.Parent.icons.shared),
	require(script.Parent.icons.dock),
}) do
	for name, image in pairs(uploads) do
		UPLOADS[name] = image
	end
end

local Images = {}
local bindings = {}
local warnedFontFailure = false

local function imageInstance(instance)
	return instance:IsA("ImageLabel") or instance:IsA("ImageButton")
end

local function disconnect(connections)
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

function Images:IsIcon(name)
	return type(name) == "string" and (EthosIcons.Has(name) or Molto.IsIcon(name))
end

function Images:GetFontAsset(name)
	if type(name) == "string" and EthosIcons.Has(name) then
		return EthosIcons.GetFontAsset(name)
	end
	if self:IsIcon(name) then
		return Molto.GetFontAsset(name)
	end
	return nil, "Unknown icon: " .. tostring(name)
end

function Images:Untrack(instance)
	local binding = bindings[instance]
	if binding == nil then
		return
	end
	bindings[instance] = nil
	disconnect(binding.Connections)
	disconnect(binding.ScaleConnections)
	if binding.Glyph then
		binding.Glyph:Destroy()
	end
end

local function scaleAt(instance)
	local scale = 1
	local current = instance
	while current do
		local uiScale = current:FindFirstChildOfClass("UIScale")
		if uiScale then
			scale *= uiScale.Scale
		end
		current = current.Parent
	end
	return math.max(scale, 0.001)
end

function Images:Track(name, instance)
	assert(
		typeof(instance) == "Instance" and imageInstance(instance),
		"Icon host must be an ImageLabel or ImageButton"
	)
	self:Untrack(instance)
	instance.Image = ""
	instance.ImageRectOffset = Vector2.zero
	instance.ImageRectSize = Vector2.zero
	if not self:IsIcon(name) then
		return instance
	end

	local binding = { Connections = {}, ScaleConnections = {} }
	bindings[instance] = binding
	table.insert(
		binding.Connections,
		instance.Destroying:Connect(function()
			if bindings[instance] == binding then
				self:Untrack(instance)
			end
		end)
	)
	local asset, message = self:GetFontAsset(name)
	if bindings[instance] ~= binding then
		return instance
	end
	if asset == nil then
		local fallback = EthosIcons.Fallback(name) or UPLOADS[name]
		if fallback then
			instance.Image = RuntimeAssets.resolve(fallback)
			return instance
		end
		self:Untrack(instance)
		if not warnedFontFailure then
			warnedFontFailure = true
			warn("Icon font could not load: " .. tostring(message))
		end
		return instance
	end
	warnedFontFailure = false
	local glyph = Instance.new("TextLabel")
	binding.Glyph = glyph
	glyph.Name = "IconGlyph"
	glyph.BackgroundTransparency = 1
	glyph.BorderSizePixel = 0
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.FontFace = asset.FontFace
	glyph.Text = asset.Text
	glyph.RichText = false
	glyph.TextScaled = false
	glyph.TextWrapped = false
	glyph.TextXAlignment = Enum.TextXAlignment.Center
	glyph.TextYAlignment = Enum.TextYAlignment.Center
	glyph.TextStrokeTransparency = 1
	glyph.Active = false
	glyph.Selectable = false
	local function refreshStyle()
		if bindings[instance] ~= binding then
			return
		end
		glyph.TextColor3 = instance.ImageColor3
		glyph.TextTransparency = instance.ImageTransparency
		glyph.ZIndex = instance.ZIndex
	end
	local function refreshSize()
		if bindings[instance] ~= binding then
			return
		end
		local size = instance.AbsoluteSize
		local extent = math.min(size.X, size.Y) / scaleAt(instance)
		if extent <= 0 then
			extent = math.min(instance.Size.X.Offset, instance.Size.Y.Offset)
		end
		glyph.TextSize = math.max(1, extent)
	end
	local bindScaleChanges: () -> ()
	local function scaleChildrenChanged(child)
		if child:IsA("UIScale") then
			bindScaleChanges()
		end
	end
	bindScaleChanges = function()
		if bindings[instance] ~= binding then
			return
		end
		disconnect(binding.ScaleConnections)
		local current = instance
		while current do
			local uiScale = current:FindFirstChildOfClass("UIScale")
			if uiScale then
				table.insert(
					binding.ScaleConnections,
					uiScale:GetPropertyChangedSignal("Scale"):Connect(refreshSize)
				)
			end
			if current:IsA("GuiBase2d") then
				table.insert(
					binding.ScaleConnections,
					current.ChildAdded:Connect(scaleChildrenChanged)
				)
				table.insert(
					binding.ScaleConnections,
					current.ChildRemoved:Connect(scaleChildrenChanged)
				)
			end
			current = current.Parent
		end
		refreshSize()
	end
	table.insert(
		binding.Connections,
		instance.Changed:Connect(function(property)
			if property == "ImageColor3" or property == "ImageTransparency" or property == "ZIndex" then
				refreshStyle()
			elseif property == "AbsoluteSize" or property == "Size" then
				refreshSize()
			end
		end)
	)
	table.insert(binding.Connections, instance.AncestryChanged:Connect(bindScaleChanges))
	refreshStyle()
	bindScaleChanges()
	glyph.Parent = instance
	return instance
end

function Images:cleanup()
	local release = {}
	for instance in pairs(bindings) do
		table.insert(release, instance)
	end
	for _, instance in ipairs(release) do
		self:Untrack(instance)
	end
end

return Images
