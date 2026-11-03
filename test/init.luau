--!nocheck
-- In-game self-checks for the core modules. Build with test.project.json and run the bundle on
-- a client; it returns { passed, failed, failures }.

local Core = script.EthosDex.core
local Values = require(Core.values)
local Path = require(Core.path)
local Search = require(Core.search)
local Api = require(Core.api)
local Tree = require(Core.tree)
local Env = require(Core.env)

local results = { passed = 0, failed = 0, failures = {} }

local function check(name: string, condition: boolean, detail: any?)
	if condition then
		results.passed += 1
	else
		results.failed += 1
		table.insert(
			results.failures,
			name .. (if detail ~= nil then ": " .. tostring(detail) else "")
		)
	end
end

local function test(name: string, fn)
	local ok, problem = pcall(fn)
	if not ok then
		check(name .. " (threw)", false, problem)
	end
end

test(
	"values",
	function()
		check("format number", Values.format(1.5) == "1.5", Values.format(1.5))
		check("format int", Values.format(3) == "3")
		check(
			"format vector3",
			Values.format(Vector3.new(1, 2.25, -3)) == "1, 2.25, -3",
			Values.format(Vector3.new(1, 2.25, -3))
		)
		check("format color", Values.format(Color3.fromRGB(255, 128, 0)) == "255, 128, 0")
		check(
			"format udim2",
			Values.format(UDim2.new(0.5, 10, 1, -4)) == "{0.5, 10}, {1, -4}",
			Values.format(UDim2.new(0.5, 10, 1, -4))
		)
		local ok, v = Values.parse("4, 5, 6", Vector3.zero)
		check("parse vector3", ok and v == Vector3.new(4, 5, 6))
		ok, v = Values.parse("{0.5, 10}, {1, -4}", UDim2.new())
		check("parse udim2 braces", ok and v == UDim2.new(0.5, 10, 1, -4), v)
		ok, v = Values.parse("#ff0000", Color3.new())
		check("parse hex", ok and v == Color3.new(1, 0, 0))
		ok, v = Values.parse("255, 0, 0", Color3.new())
		check("parse rgb", ok and v == Color3.new(1, 0, 0))
		ok, v = Values.parse("1, 2, 3", CFrame.Angles(0, math.pi / 2, 0))
		check(
			"parse cframe position keeps rotation",
			ok
				and v.Position == Vector3.new(1, 2, 3)
				and v.LookVector:FuzzyEq(CFrame.Angles(0, math.pi / 2, 0).LookVector)
		)
		ok = Values.parse("abc", 5)
		check("reject bad number", not ok)
		ok, v = Values.parse("Bright red", BrickColor.new("White"))
		check("parse brickcolor", ok and v == BrickColor.new("Bright red"))
		ok, v = Values.parse("2, 8", NumberRange.new(0))
		check("parse range", ok and v.Min == 2 and v.Max == 8)
		check("code color", Values.code(Color3.fromRGB(1, 2, 3)) == "Color3.fromRGB(1, 2, 3)")
		check("format inf", Values.format(math.huge) == "inf")
	end
)

test(
	"path",
	function()
		local folder = Instance.new("Folder")
		folder.Name = "Dex Test"
		folder.Parent = workspace
		local part = Instance.new("Part")
		part.Name = "end"
		part.Parent = folder
		local ok = Path.of(part, game, nil) == 'game:GetService("Workspace")["Dex Test"]["end"]'
		check("path quoting", ok, Path.of(part, game, nil))
		local plain = Instance.new("Folder")
		plain.Name = "Plain_1"
		plain.Parent = folder
		check(
			"path dot",
			Path.of(plain, game, nil) == 'game:GetService("Workspace")["Dex Test"].Plain_1',
			Path.of(plain, game, nil)
		)
		local orphan = Instance.new("Folder")
		orphan.Name = "Orphan"
		check(
			"path nil",
			string.find(Path.of(orphan, game, nil), "getnilinstances", 1, true) ~= nil
		)
		local player = game:GetService("Players").LocalPlayer
		check(
			"path local player",
			Path.of(player, game, player) == 'game:GetService("Players").LocalPlayer'
		)
		local chain = Path.chain(part, game)
		check("chain", #chain == 3 and chain[1] == workspace and chain[3] == part)
		folder:Destroy()
	end
)

test(
	"search",
	function()
		local conditions = Search.parse("class:Part Big  Door")
		check("parse class", conditions.Class == "part")
		check("parse name words", conditions.Name == "big door", conditions.Name)
		local part = Instance.new("Part")
		part.Name = "The Big Door"
		check("matches", Search.matches(part, conditions))
		check(
			"no match class",
			not Search.matches(Instance.new("Folder"), Search.parse("class:Part"))
		)
		check("isa", Search.matches(part, Search.parse("isa:BasePart")))
	end
)

test(
	"metadata parse",
	function()
		local xml = [[
<Item class="ReflectionMetadataClasses"><Properties></Properties>
<Item class="ReflectionMetadataClass"><Properties><string name="Name">Alpha</string><string name="ExplorerOrder">10</string><string name="ExplorerImageIndex">113</string></Properties>
<Item class="ReflectionMetadataFunctions"><Item class="ReflectionMetadataMember"><Properties><string name="Name">Fire</string></Properties></Item></Item></Item>
<Item class="ReflectionMetadataClass"><Properties><string name="Name">Beta</string><string name="ExplorerImageIndex">7</string></Properties></Item>
</Item>]]
		local meta = Api.parseMetadata(xml)
		check("alpha icon", meta.Alpha and meta.Alpha.Icon == 113)
		check("alpha order", meta.Alpha and meta.Alpha.Order == 10)
		check("beta follows nested members", meta.Beta and meta.Beta.Icon == 7)
		check("member names aren't classes", meta.Fire == nil)
	end
)

test(
	"api live",
	function()
		Api.load()
		check("api ready", Api.Status == "ready", Api.Problem)
		check("part icon", Api.icon("Part") == 1, Api.icon("Part"))
		check("inherited icon", Api.icon("WedgePart") ~= nil)
		local names = {}
		for _, property in Api.properties("Part") do
			names[property.Name] = property
		end
		check("part has Anchored", names.Anchored ~= nil)
		check("part has inherited Name", names.Name ~= nil and names.Name.Class == "Instance")
		check("ClassName read only", names.ClassName and names.ClassName.Tags.ReadOnly)
		check(
			"workspace sorts first",
			Api.order("Workspace") < Api.order("Folder"),
			`{Api.order("Workspace")} {Api.order("Folder")}`
		)
		local creatable = Api.creatable()
		check("creatable has Part", table.find(creatable, "Part") ~= nil)
		check("creatable skips services", table.find(creatable, "Workspace") == nil)
	end
)

test(
	"tree",
	function()
		local root = Instance.new("Folder")
		root.Name = "Root"
		local b = Instance.new("Folder")
		b.Name = "b"
		b.Parent = root
		local a = Instance.new("Folder")
		a.Name = "A"
		a.Parent = root
		local deep = Instance.new("Part")
		deep.Name = "deep"
		deep.Parent = a
		root.Parent = workspace

		local tree = Tree.new({
			Roots = function()
				return { root }
			end,
			Order = function()
				return 0
			end,
		})
		local function names()
			local out = {}
			for _, node in tree:flat() do
				table.insert(out, node.Instance.Name)
			end
			return table.concat(out, ",")
		end
		check("collapsed", names() == "Root", names())
		tree:setExpanded(tree.Roots[1], true)
		check("expanded sorted", names() == "Root,A,b", names())
		local c = Instance.new("Folder")
		c.Name = "Aa"
		c.Parent = root
		task.wait()
		check("child added sorted", names() == "Root,A,Aa,b", names())
		b:Destroy()
		task.wait()
		check("child removed", names() == "Root,A,Aa", names())
		c.Name = "zz"
		tree:renamed(c)
		check("rename resorts", names() == "Root,A,zz", names())
		local node = tree:reveal(deep)
		check("reveal opens", node ~= nil and names() == "Root,A,deep,zz", names())
		tree:setFilter({ [root] = 2, [a] = 2, [deep] = 1 })
		check("filter", names() == "Root,A,deep", names())
		tree:setFilter(nil)
		tree:collapseAll()
		check("collapse all", names() == "Root", names())
		deep.Parent = c
		task.wait()
		tree:setExpandedDeep(tree.Roots[1], true)
		check("reparent followed", names() == "Root,A,zz,deep", names())
		tree:destroy()
		root:Destroy()
	end
)

test(
	"env",
	function()
		check("safe name", Env.safeName('a<b>:c?"') == "a_b_c_", Env.safeName('a<b>:c?"'))
		check("gui parent", typeof(Env.guiParent()) == "Instance")
		local server = Instance.new("Script")
		check("server script not decompilable", not Env.canDecompile(server))
		check(
			"module decompilable when supported",
			Env.canDecompile(Instance.new("ModuleScript"))
				== (Env.has("decompile") or Env.has("getscriptbytecode"))
		)
		check("cloneref keeps identity for non-instances", Env.cloneref(5) == 5)
		check("get property", select(2, Env.getProperty(workspace, "Name")) == "Workspace")
		check("base64 1", Env.base64("a") == "YQ==", Env.base64("a"))
		check("base64 2", Env.base64("hi") == "aGk=", Env.base64("hi"))
		check("base64 3", Env.base64("abc\0\255") == "YWJjAP8=", Env.base64("abc\0\255"))
	end
)

test(
	"actions",
	function()
		local App = script.EthosDex.app
		local Actions = require(App.actions)
		local State = require(App.state)
		local reveal = State.Hooks.reveal
		State.Hooks.reveal = function()
		end
		local from, to = Instance.new("Folder"), Instance.new("Folder")
		local part = Instance.new("Part")
		part.Archivable = false
		part.Parent = from
		Actions.hold({ part }, false)
		Actions.paste(to)
		check("copy clones non-archivable", #to:GetChildren() == 1 and part.Parent == from)
		check("copy keeps archivable flag", part.Archivable == false)
		Actions.hold({ part }, true)
		Actions.paste(to)
		check("cut moves", part.Parent == to and #to:GetChildren() == 2)
		Actions.paste(from)
		check("cut pastes once", #from:GetChildren() == 0)
		State.Hooks.reveal = reveal
		from:Destroy()
		to:Destroy()
	end
)

test(
	"cursor",
	function()
		local Cursor = require(script.EthosDex.app.cursor)
		local gui = Instance.new("ScreenGui")
		gui.Parent = Env.guiParent()
		local layer = Instance.new("Frame")
		layer.Size = UDim2.fromScale(1, 1)
		layer.Parent = gui
		local panel = Instance.new("Frame")
		panel.Position = UDim2.fromOffset(100, 100)
		panel.Size = UDim2.fromOffset(50, 50)
		panel.Parent = layer
		task.wait()
		local origin = layer.AbsolutePosition
		check("over panel", Cursor.over(layer, origin + Vector2.new(120, 120)))
		check("off panel", not Cursor.over(layer, origin + Vector2.new(10, 10)))
		panel.Visible = false
		check("hidden panel ignored", not Cursor.over(layer, origin + Vector2.new(120, 120)))
		gui:Destroy()
	end
)

test(
	"history",
	function()
		local History = require(script.EthosDex.app.history)
		History.clear()
		local order = {}
		History.push(
			"first",
			function()
				table.insert(order, 1)
			end
		)
		History.push(
			"second",
			function()
				table.insert(order, 2)
			end
		)
		History.push(
			"broken",
			function()
				error("nope")
			end
		)
		check("broken undo reports", History.undo() == false)
		check("undo returns ok", History.undo() == true)
		History.undo()
		check("newest first", order[1] == 2 and order[2] == 1, table.concat(order, ","))
		check("empty undo", History.undo() == false and History.size() == 0)
		for index = 1, 60 do
			History.push(
				tostring(index),
				function()
				end
			)
		end
		check("capped", History.size() == 50, History.size())
		History.clear()

		local State = require(script.EthosDex.app.state)
		local Settings = require(script.EthosDex.core.settings)
		local was = Settings.get("Density")
		Settings.set("Density", "Compact")
		local compact = State.rowHeight()
		Settings.set("Density", "Comfortable")
		check("density changes rows", State.rowHeight() > compact)
		Settings.set("Density", was)
	end
)

return results
