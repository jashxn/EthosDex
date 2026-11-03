--!nocheck
-- Undo for what the explorer and properties change: each step is a description and a function
-- that puts things back. Ctrl+Z over the UI calls History.undo.

local Toast = require(script.Parent.toast)

local LIMIT = 50

local History = {}
local steps = {}

function History.push(text: string, undo: () -> ())
	table.insert(steps, { Text = text, Undo = undo })
	if #steps > LIMIT then
		table.remove(steps, 1)
	end
end

function History.undo(): boolean
	local step = table.remove(steps)
	if step == nil then
		Toast.show("Nothing to undo")
		return false
	end
	local ok, problem = pcall(step.Undo)
	Toast.show(
		if ok then "Undid " .. step.Text else `Couldn't undo {step.Text}: {problem}`,
		if ok then "success" else "error"
	)
	return ok
end

function History.size(): number
	return #steps
end

function History.clear()
	table.clear(steps)
end

return History
