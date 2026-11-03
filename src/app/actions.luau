--!nocheck
-- What can be done to selected instances: the context menu's entries and their effects.

local Root = script.Parent.Parent
local Env = require(Root.core.env)
local Api = require(Root.core.api)
local Path = require(Root.core.path)
local Settings = require(Root.core.settings)
local State = require(script.Parent.state)
local Toast = require(script.Parent.toast)

local Actions = {}

local UNSUPPORTED = "Not on this executor"

local function scriptLike(object): boolean
	return object:IsA("LuaSourceContainer")
end

local function folderFor(kind: string): string
	return `{Env.ROOT}/{kind}/{game.PlaceId}`
end

function Actions.copy(text: string, what: string)
	if Env.clipboard(text) then
		Toast.show(`Copied {what}`, "success")
	else
		Toast.show("This executor has no clipboard.", "error")
	end
end

function Actions.path(object): string
	return Path.of(object, game, State.LocalPlayer)
end

function Actions.delete(list)
	local count = 0
	for _, object in list do
		if pcall(object.Destroy, object) then
			count += 1
		end
	end
	State.select({})
	Toast.show(
		if count == #list then `Deleted {count}` else `Deleted {count} of {#list}`,
		if count == #list then "success" else "error"
	)
end

-- Clones even non-Archivable instances, into `parent`.
local function cloneInto(object, parent)
	local ok, clone = pcall(function()
		local archivable = object.Archivable
		object.Archivable = true
		local copy = object:Clone()
		object.Archivable = archivable
		copy.Parent = parent
		return copy
	end)
	return if ok then clone else nil
end

local function selectMade(made, failure: string)
	if #made > 0 then
		State.select(made)
		State.Hooks.reveal(made[1], true)
	else
		Toast.show(failure, "error")
	end
end

function Actions.duplicate(list)
	local clones = {}
	for _, object in list do
		table.insert(clones, cloneInto(object, object.Parent))
	end
	selectMade(clones, "Couldn't duplicate.")
end

-- Dex's cut / copy / paste into: copies clone on paste, cuts move.
local held = { List = {}, Cut = false }

function Actions.hold(list, cut: boolean)
	held = { List = table.clone(list), Cut = cut }
	Toast.show(`{if cut then "Cut" else "Copied"} {#list}`, "success")
end

function Actions.paste(parent)
	if #held.List == 0 then
		return
	end
	local made = {}
	for _, object in held.List do
		if held.Cut then
			if pcall(function()
				object.Parent = parent
			end) then
				table.insert(made, object)
			end
		else
			table.insert(made, cloneInto(object, parent))
		end
	end
	if held.Cut then
		held = { List = {}, Cut = false }
	end
	selectMade(made, "Couldn't paste here.")
end

-- View: the camera follows the object; stopViewing puts it back.
local savedSubject = nil

local function subjectOf(object)
	if object:IsA("BasePart") or object:IsA("Humanoid") then
		return object
	elseif object:IsA("Model") then
		return object:FindFirstChildWhichIsA("Humanoid")
			or object.PrimaryPart
			or object:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

function Actions.view(object)
	local camera = workspace.CurrentCamera
	local subject = subjectOf(object)
	if camera == nil or subject == nil then
		Toast.show("Nothing to look at in that.", "error")
		return
	end
	savedSubject = savedSubject or camera.CameraSubject
	camera.CameraSubject = subject
end

function Actions.stopViewing()
	local camera = workspace.CurrentCamera
	if savedSubject and camera then
		pcall(function()
			camera.CameraSubject = savedSubject
		end)
	end
	savedSubject = nil
end

function Actions.group(list)
	local ok, model = pcall(function()
		local group = Instance.new("Model")
		group.Parent = list[1].Parent
		for _, object in list do
			object.Parent = group
		end
		return group
	end)
	if ok then
		State.Hooks.reveal(model)
	else
		Toast.show("Couldn't group: " .. tostring(model), "error")
	end
end

function Actions.ungroup(list)
	local moved = {}
	for _, object in list do
		pcall(function()
			for _, child in object:GetChildren() do
				child.Parent = object.Parent
				table.insert(moved, child)
			end
			object:Destroy()
		end)
	end
	State.select(moved)
end

function Actions.teleport(object)
	local character = State.LocalPlayer.Character
	if character == nil then
		Toast.show("You have no character.", "error")
		return
	end
	local ok, problem = pcall(function()
		local pivot = if object:IsA("PVInstance") then object:GetPivot()
			else object.Parent:GetPivot()
		character:PivotTo(pivot + Vector3.new(0, 4, 0))
	end)
	if not ok then
		Toast.show("Couldn't teleport: " .. tostring(problem), "error")
	end
end

function Actions.saveScript(object)
	Toast.show("Decompiling " .. object.Name)
	local source, problem = Env.decompile(object, Settings.get("Decompiler"))
	if source == nil then
		Toast.show("Couldn't decompile: " .. tostring(problem), "error")
		return
	end
	local file = `{folderFor("scripts")}/{Env.safeName(object.Name)}.lua`
	local header = `-- {Actions.path(object)}\n-- Decompiled by Ethos Dex\n\n`
	local ok, failure = Env.writeFile(file, header .. source)
	Toast.show(
		if ok then "Saved to workspace/" .. file else "Couldn't save: " .. tostring(failure),
		if ok then "success" else "error"
	)
end

function Actions.saveBytecode(object)
	local bytecode, problem = Env.bytecode(object)
	if bytecode == nil then
		Toast.show(tostring(problem), "error")
		return
	end
	local file = `{folderFor("bytecode")}/{Env.safeName(object.Name)}.luac`
	local ok, failure = Env.writeFile(file, bytecode)
	Toast.show(
		if ok then "Saved to workspace/" .. file else "Couldn't save: " .. tostring(failure),
		if ok then "success" else "error"
	)
end

function Actions.saveInstance(list)
	local first = list[1]
	local name = if first == game then `place-{game.PlaceId}` else Env.safeName(first.Name)
	local file = `{folderFor("saves")}/{name}`
	Env.ensureFolder(folderFor("saves"))
	Toast.show("Saving " .. (if first == game then "the place" else first.Name) .. "...")
	task.spawn(function()
		local options = {
			FilePath = file,
			Decompile = Settings.get("SaveDecompile"),
			ShowStatus = true,
			SafeMode = false,
		}
		if first ~= game then
			options.Object = if #list == 1 then first else nil
			options.ExtraInstances = if #list > 1 then list else nil
			options.IsModel = true
		end
		local ok, problem = Env.saveInstance(options)
		Toast.show(
			if ok then "Saved to workspace/" .. file else "Couldn't save: " .. tostring(problem),
			if ok then "success" else "error"
		)
	end)
end

local function fireTarget(object, className: string)
	if object:IsA(className) then
		return object
	end
	return object:FindFirstChildWhichIsA(className)
end

-- The menu for a selection. `tree` has Expand(deep) and Collapse().
function Actions.entries(list, tree)
	local first = list[1]
	if first == nil then
		return {}
	end
	local single = #list == 1
	local entries = {}
	local function add(entry)
		table.insert(entries, entry)
	end
	local function divider()
		if #entries > 0 and entries[#entries] ~= "divider" then
			table.insert(entries, "divider")
		end
	end

	add({
		Text = "Copy path",
		Icon = "copy",
		OnActivated = function()
			local paths = {}
			for _, object in list do
				table.insert(paths, Actions.path(object))
			end
			Actions.copy(table.concat(paths, "\n"), if single then "path" else `{#list} paths`)
		end,
	})
	add({
		Text = "Copy name",
		Icon = "type",
		OnActivated = function()
			Actions.copy(first.Name, "name")
		end,
	})
	divider()

	if single then
		add({
			Text = "Rename",
			Icon = "pencil",
			Detail = "F2",
			OnActivated = function()
				State.Hooks.rename(first)
			end,
		})
	end
	add({
		Text = "Cut",
		Icon = "scissors",
		Detail = "Ctrl+X",
		OnActivated = function()
			Actions.hold(list, true)
		end,
	})
	add({
		Text = "Copy",
		Icon = "clipboard-copy",
		Detail = "Ctrl+C",
		OnActivated = function()
			Actions.hold(list, false)
		end,
	})
	if #held.List > 0 then
		add({
			Text = `Paste into {first.Name}`,
			Icon = "clipboard-paste",
			Detail = "Ctrl+V",
			OnActivated = function()
				Actions.paste(first)
			end,
		})
	end
	add({
		Text = "Duplicate",
		Icon = "copy-plus",
		Detail = "Ctrl+D",
		OnActivated = function()
			Actions.duplicate(list)
		end,
	})
	add({
		Text = "Group",
		Icon = "group",
		OnActivated = function()
			Actions.group(list)
		end,
	})
	if first:IsA("Model") or first:IsA("Folder") then
		add({
			Text = "Ungroup",
			Icon = "ungroup",
			OnActivated = function()
				Actions.ungroup(list)
			end,
		})
	end
	add({
		Text = "Insert object",
		Icon = "plus",
		OnActivated = function()
			State.Hooks.insert(first)
		end,
	})
	add({
		Text = if single then "Delete" else `Delete {#list}`,
		Icon = "trash-2",
		Danger = true,
		Detail = "Del",
		OnActivated = function()
			Actions.delete(list)
		end,
	})
	divider()

	add({
		Text = "Select children",
		Icon = "list-tree",
		OnActivated = function()
			State.Hooks.selectChildren(list)
		end,
	})
	if first.Parent and first.Parent ~= game then
		add({
			Text = "Jump to parent",
			Icon = "corner-left-up",
			OnActivated = function()
				State.Hooks.reveal(first.Parent)
			end,
		})
	end
	add({
		Text = "Expand all",
		Icon = "chevrons-up-down",
		OnActivated = function()
			tree.Expand(true)
		end,
	})
	add({
		Text = "Collapse all",
		Icon = "chevrons-down-up",
		OnActivated = function()
			tree.Collapse()
		end,
	})
	divider()

	if scriptLike(first) then
		local can = Env.canDecompile(first)
		add({
			Text = "View script",
			Icon = "code",
			Disabled = if can then nil else UNSUPPORTED,
			Detail = if can then nil else "Unsupported",
			OnActivated = function()
				State.ScriptTarget:set(first)
				State.open("Script")
			end,
		})
		add({
			Text = "Save script",
			Icon = "download",
			Disabled = if can and Env.canWrite() then nil else UNSUPPORTED,
			OnActivated = function()
				Actions.saveScript(first)
			end,
		})
		if Env.has("getscriptbytecode") then
			add({
				Text = "Save bytecode",
				Icon = "binary",
				Disabled = if Env.canWrite() then nil else UNSUPPORTED,
				OnActivated = function()
					Actions.saveBytecode(first)
				end,
			})
		end
	end
	if first:IsA("PVInstance") and not first:IsA("WorldRoot") then
		add({
			Text = "Preview",
			Icon = "box",
			OnActivated = function()
				State.PreviewTarget:set(first)
				State.open("Preview")
			end,
		})
		add({
			Text = "Teleport to",
			Icon = "map-pin",
			OnActivated = function()
				Actions.teleport(first)
			end,
		})
	end
	if first:IsA("PVInstance") and not first:IsA("WorldRoot") or first:IsA("Humanoid") then
		add({
			Text = "View",
			Icon = "eye",
			OnActivated = function()
				Actions.view(first)
			end,
		})
	end
	if savedSubject then
		add({
			Text = "Stop viewing",
			Icon = "eye-off",
			OnActivated = Actions.stopViewing,
		})
	end
	local click = fireTarget(first, "ClickDetector")
	if click then
		add({
			Text = "Fire click detector",
			Icon = "mouse-pointer-click",
			Disabled = if Env.has("fireclickdetector") then nil else UNSUPPORTED,
			OnActivated = function()
				local ok, problem = Env.fire("fireclickdetector", click)
				Toast.show(
					if ok then "Fired" else tostring(problem),
					if ok then "success" else "error"
				)
			end,
		})
	end
	local prompt = fireTarget(first, "ProximityPrompt")
	if prompt then
		add({
			Text = "Fire proximity prompt",
			Icon = "hand",
			Disabled = if Env.has("fireproximityprompt") then nil else UNSUPPORTED,
			OnActivated = function()
				local ok, problem = Env.fire("fireproximityprompt", prompt)
				Toast.show(
					if ok then "Fired" else tostring(problem),
					if ok then "success" else "error"
				)
			end,
		})
	end
	if first:IsA("BasePart") and first:FindFirstChildWhichIsA("TouchTransmitter") then
		add({
			Text = "Fire touch",
			Icon = "pointer",
			Disabled = if Env.has("firetouchinterest") then nil else UNSUPPORTED,
			OnActivated = function()
				local ok, problem = Env.fire("firetouchinterest", first)
				Toast.show(
					if ok then "Fired" else tostring(problem),
					if ok then "success" else "error"
				)
			end,
		})
	end
	if first:IsA("Player") then
		add({
			Text = "Select character",
			Icon = "person-standing",
			OnActivated = function()
				if first.Character then
					State.Hooks.reveal(first.Character)
				end
			end,
		})
	end
	divider()

	add({
		Text = "Save to file",
		Icon = "save",
		Disabled = if Env.canWrite() and (Env.has("saveinstance") or Env.has("loadstring")) then nil
			else UNSUPPORTED,
		OnActivated = function()
			Actions.saveInstance(list)
		end,
	})
	add({
		Text = "Copy in console",
		Icon = "terminal",
		OnActivated = function()
			State.Hooks.consoleInsert(`local object = {Actions.path(first)}\n`)
			State.open("Console")
		end,
	})
	add({
		Text = "Open API page",
		Icon = "external-link",
		OnActivated = function()
			local class = first.ClassName
			Actions.copy(
				"https://create.roblox.com/docs/reference/engine/classes/" .. class,
				"API page link"
			)
		end,
	})
	if entries[#entries] == "divider" then
		table.remove(entries)
	end
	return entries
end

-- Instance.new under `parent`, then selects it.
function Actions.insert(parent, className: string)
	local ok, object = pcall(function()
		local made = Instance.new(className)
		made.Parent = parent
		return made
	end)
	if ok then
		State.Hooks.reveal(object)
	else
		Toast.show(`Couldn't create {className}: {object}`, "error")
	end
end

Actions.creatable = Api.creatable

return Actions
