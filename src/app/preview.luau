--!nocheck
-- A 3D preview of a model or part: a copy in a ViewportFrame you can orbit and zoom.

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local Controls = require(Root.ui.controls)
local Theme = require(Root.ui.tokens)
local Pointer = require(Root.ui.pointer)
local Env = require(Root.core.env)
local State = require(script.Parent.state)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local RunService = Env.service("RunService")

local MAX_PARTS = 6000

local Preview = {}

function Preview.new(scope)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 50
	local world = Instance.new("WorldModel")
	local yaw, pitch, distance, center = 0.6, -0.35, 10, Vector3.zero
	local spin = scope:Value(true)
	local title = scope:Value("")
	local problem = scope:Value(nil)
	local copy = nil

	local function place()
		local rotation = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
		camera.CFrame = CFrame.new(center) * rotation * CFrame.new(0, 0, distance)
		camera.Focus = CFrame.new(center)
	end

	local function load(object)
		if copy then
			copy:Destroy()
			copy = nil
		end
		problem:set(nil)
		if object == nil then
			title:set("")
			return
		end
		title:set(object.Name)
		local ok, result = pcall(function()
			local count = if object:IsA("BasePart") then 1 else 0
			for _, descendant in object:GetDescendants() do
				if descendant:IsA("BasePart") then
					count += 1
				end
			end
			if count > MAX_PARTS then
				error(`{count} parts is too many to preview.`, 0)
			end
			local restore = {}
			local function allow(instance)
				if not instance.Archivable then
					instance.Archivable = true
					table.insert(restore, instance)
				end
			end
			allow(object)
			for _, descendant in object:GetDescendants() do
				pcall(allow, descendant)
			end
			local clone = object:Clone()
			for _, instance in restore do
				pcall(function()
					instance.Archivable = false
				end)
			end
			if clone == nil then
				error("It can't be copied.", 0)
			end
			for _, descendant in clone:GetDescendants() do
				if descendant:IsA("LuaSourceContainer") then
					descendant:Destroy()
				end
			end
			return clone
		end)
		if not ok then
			problem:set(tostring(result))
			return
		end
		copy = result
		local cframe, size
		if copy:IsA("BasePart") then
			cframe, size = copy.CFrame, copy.Size
		else
			local model = copy
			if not copy:IsA("Model") then
				model = Instance.new("Model")
				copy.Parent = model
				copy = model
			end
			cframe, size = model:GetBoundingBox()
		end
		center = cframe.Position
		distance = math.max(size.Magnitude * 1.1, 2)
		copy.Parent = world
		place()
	end

	table.insert(
		scope,
		scope:Observer(State.PreviewTarget):onBind(function()
			load(peek(State.PreviewTarget))
		end)
	)

	local viewport = scope:New("ViewportFrame")({
		Name = "Viewport",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CurrentCamera = camera,
		Ambient = Color3.fromRGB(160, 160, 170),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-1, -2, -1),
		Active = true,
		[OnEvent("InputBegan")] = function(input)
			if not Pointer.isPress(input) then
				return
			end
			spin:set(false)
			local last = Vector2.new(input.Position.X, input.Position.Y)
			Pointer.drag(
				scope,
				function(point)
					local delta = point - last
					last = point
					yaw -= delta.X * 0.01
					pitch = math.clamp(pitch - delta.Y * 0.01, -1.5, 1.5)
					place()
				end
			)
		end,
		[OnEvent("InputChanged")] = function(input)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				distance = math.max(0.5, distance * (1 - input.Position.Z * 0.1))
				place()
			end
		end,
	})
	camera.Parent = viewport
	world.Parent = viewport

	table.insert(
		scope,
		RunService.RenderStepped:Connect(function(dt)
			if peek(spin) and copy then
				yaw += dt * 0.4
				place()
			end
		end)
	)
	table.insert(
		scope,
		function()
			if copy then
				copy:Destroy()
			end
		end
	)

	local function zoom(factor)
		distance = math.max(0.5, distance * factor)
		place()
	end

	local body = scope:New("Frame")({
		Name = "Stage",
		Position = UDim2.fromOffset(10, 52),
		Size = UDim2.new(1, -20, 1, -62),
		BackgroundColor3 = Theme.Ink,
		ClipsDescendants = true,
		Visible = scope:Computed(function(use)
			return use(State.PreviewTarget) ~= nil
		end),
		[Children] = {
			Controls.Fill(scope, scope:Value(0.04)),
			Controls.Edge(scope, nil, UDim.new(0, 12)),
			viewport,
			Controls.Label(
				scope,
				{
					Position = UDim2.new(0, 14, 1, -30),
					Size = UDim2.new(1, -28, 0, 20),
					Text = scope:Computed(function(use)
						return use(problem) or ""
					end),
					TextSize = 13,
					TextColor3 = Theme.Caution,
				}
			),
		},
	})

	local header = scope:New("Frame")({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Visible = scope:Computed(function(use)
			return use(State.PreviewTarget) ~= nil
		end),
		[Children] = {
			Controls.Label(
				scope,
				{
					Position = UDim2.fromOffset(16, 0),
					Size = UDim2.new(1, -170, 1, 0),
					Text = title,
					TextSize = 14,
				}
			),
			scope:New("Frame")({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(0, 30),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				[Children] = {
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Controls.IconButton(
						scope,
						{
							Name = "ZoomIn",
							Icon = "zoom-in",
							Size = 30,
							LayoutOrder = 1,
							OnActivated = function()
								zoom(0.8)
							end,
						}
					),
					Controls.IconButton(
						scope,
						{
							Name = "ZoomOut",
							Icon = "zoom-out",
							Size = 30,
							LayoutOrder = 2,
							OnActivated = function()
								zoom(1.25)
							end,
						}
					),
					Controls.IconButton(
						scope,
						{
							Name = "Spin",
							Icon = "rotate-ccw",
							Size = 30,
							LayoutOrder = 3,
							OnActivated = function()
								spin:set(not peek(spin))
							end,
						}
					),
				},
			}),
		},
	})

	local empty = Controls.Empty(
		scope,
		{
			Name = "Empty",
			Icon = "box",
			Title = "Right-click a model or part and choose Preview",
			Visible = scope:Computed(function(use)
				return use(State.PreviewTarget) == nil
			end),
		}
	)
	empty.AnchorPoint = Vector2.new(0.5, 0.5)
	empty.Position = UDim2.fromScale(0.5, 0.45)

	local pane = scope:New("Frame")({
		Name = "Preview",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[Children] = { header, body, empty },
	})
	return { Instance = pane }
end

return Preview
