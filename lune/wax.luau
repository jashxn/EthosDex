--[[
	Wax - A Fast Runtime-Based Lua 5.1x+/Luau Project Bundler, Using Roblox Models and Module-Require Semantics
	MIT License | Copyright (c) 2023-2024 Latte Softworks <https://latte.to>
]]

-- You set the following string to "latest" (case insensitive), or any version tag
-- on Wax's releases page (e.g. "0.4.1")
local WaxVersion = "latest"

-------------------------------------------------------------------------------

local net = require("@lune/net")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local serde = require("@lune/serde")

local RUNTIME_MARKER = "-- ++++++++ RUNTIME IMPL BELOW ++++++++ --"
local PATCH_MARKER = "-- ++++++++ ETHOS WAX LURAPH RUNTIME PATCH ++++++++ --"

local function readOption(name: string): string?
	local prefix = name .. "="
	for _, argument in ipairs(process.args) do
		if string.sub(argument, 1, #prefix) == prefix then
			return string.sub(argument, #prefix + 1)
		end
	end
	return nil
end

local function outputCandidates(): { string }
	local explicitOutput = readOption("output")
	if explicitOutput then
		return { explicitOutput }
	end

	local input = readOption("input") or "default.project.json"
	local candidates = {}
	local function add(candidate: string)
		if candidate ~= "" and not table.find(candidates, candidate) then
			table.insert(candidates, candidate)
		end
	end

	-- Wax names Rojo-project output after the project's `name`, not after the
	-- *.project.json filename. For this project that means `Ethos Suite.wax.lua`.
	if string.match(input, "%.project%.json$") and fs.isFile(input) then
		local ok, project = pcall(function()
			return serde.decode("json", fs.readFile(input))
		end)
		if ok and type(project) == "table" and type(project.name) == "string" then
			add(project.name .. ".wax.lua")
			add(project.name .. ".lua")
		end
	end

	local stems = {
		(string.gsub(input, "%.project%.json$", "")),
		(string.gsub(input, "%.rbxmx$", "")),
		(string.gsub(input, "%.rbxm$", "")),
		(string.gsub(input, "%.[^./\\]+$", "")),
	}
	for _, stem in ipairs(stems) do
		add(stem .. ".wax.lua")
		add(stem .. ".lua")
	end
	return candidates
end

local function indent(block: string): string
	return "\t" .. string.gsub(block, "\n", "\n\t")
end

local requestedMinify = process.args[1] == "bundle" and string.lower(readOption("minify") or "false") == "true"
local waxArgs = table.clone(process.args)

if requestedMinify then
	-- Wax runs Darklua before this wrapper regains control. Darklua removes the
	-- runtime marker and can merge declarations across it, so patching after
	-- Wax's minification is not safe. Ask Wax for readable output first; after
	-- the runtime is patched below, we run the same project Darklua pass.
	for index, argument in ipairs(waxArgs) do
		if string.sub(argument, 1, #"minify=") == "minify=" then
			waxArgs[index] = "minify=false"
			break
		end
	end
end

local waxProcess = setmetatable({
	args = waxArgs,
}, {
	__index = process,
})

local hostRequire = require
local waxEnvironment = {
	require = function(moduleName: string)
		if moduleName == "@lune/process" then
			return waxProcess
		end
		return hostRequire(moduleName)
	end,
}

local function patchWaxRuntime(path: string)
	local source = fs.readFile(path)
	if string.find(source, PATCH_MARKER, 1, true) then
		return
	end

	local _, markerEnd = string.find(source, RUNTIME_MARKER, 1, true)
	assert(markerEnd ~= nil, "Wax output is missing the runtime marker: " .. path)

	local prefix = string.sub(source, 1, markerEnd)
	local runtime = string.sub(source, markerEnd + 1)
	runtime = string.gsub(runtime, "^\r?\n", "")

	local shim = [[
-- ++++++++ ETHOS WAX LURAPH RUNTIME PATCH ++++++++ --
if not LPH_OBFUSCATED then
	function LPH_ATTRIBUTES(...) end
	function VM(...) return ... end
	function PRESET(...) return ... end
	function ERROR_HANDLING(...) return ... end
end

local function __ETHOS_WAX_RUNTIME()
	LPH_ATTRIBUTES(VM(NONE), PRESET(FAST), ERROR_HANDLING(false))
]]

	local patched = prefix
		.. "\n\n"
		.. shim
		.. indent(runtime)
		.. "\nend\n\nreturn __ETHOS_WAX_RUNTIME()\n"
	fs.writeFile(path, patched)
	print("Patched Wax runtime for Luraph VM(NONE): " .. path)
end

local function minifyPatchedWax(path: string)
	local tempPath = path .. ".ethos-minify.tmp"
	if fs.isFile(tempPath) then
		fs.removeFile(tempPath)
	end

	local result = process.exec("darklua", { "process", path, tempPath })
	if not result.ok then
		if result.stdout ~= "" then
			print(result.stdout)
		end
		if result.stderr ~= "" then
			warn(result.stderr)
		end
		error("Darklua failed while minifying the patched Wax bundle", 0)
	end

	fs.move(tempPath, path, true)
	print("Minified patched Wax bundle: " .. path)
end

local FileLink = if string.lower(WaxVersion) == "latest" then "https://github.com/latte-soft/wax/releases/latest/download/wax.luau"
	else `https://github.com/latte-soft/wax/releases/download/{WaxVersion}/wax.luau`

luau.load(
	net.request(FileLink).body,
	{
		debugName = "Wax",
		environment = waxEnvironment,
	}
)()

if process.args[1] == "bundle" then
	local outputPath = nil
	for _, candidate in ipairs(outputCandidates()) do
		if fs.isFile(candidate) then
			outputPath = candidate
			break
		end
	end
	assert(outputPath ~= nil, "Unable to locate Wax bundle output for Luraph runtime patching")
	patchWaxRuntime(outputPath)
	if requestedMinify then
		minifyPatchedWax(outputPath)
	end
end
