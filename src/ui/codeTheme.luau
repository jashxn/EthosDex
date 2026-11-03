-- Catppuccin for VS Code's token colors; pinned sources and licenses:
-- assets/vendor/catppuccin/README.md
local ColorSpace = require(script.Parent.Parent.utils.colorSpace)

local MOCHA = table.freeze({
	iden = Color3.fromHex("cdd6f4"),
	punctuation = Color3.fromHex("9399b2"),
	comment = Color3.fromHex("9399b2"),
	keyword = Color3.fromHex("cba6f7"),
	["function"] = Color3.fromHex("89b4fa"),
	type = Color3.fromHex("f9e2af"),
	string = Color3.fromHex("a6e3a1"),
	number = Color3.fromHex("fab387"),
	constant = Color3.fromHex("fab387"),
	operator = Color3.fromHex("94e2d5"),
	property = Color3.fromHex("94e2d5"),
	parameter = Color3.fromHex("eba0ac"),
	builtin = Color3.fromHex("eba0ac"),
	self = Color3.fromHex("f38ba8"),
})

local LATTE = table.freeze({
	iden = Color3.fromHex("4c4f69"),
	punctuation = Color3.fromHex("7c7f93"),
	comment = Color3.fromHex("7c7f93"),
	keyword = Color3.fromHex("8839ef"),
	["function"] = Color3.fromHex("1e66f5"),
	type = Color3.fromHex("df8e1d"),
	string = Color3.fromHex("40a02b"),
	number = Color3.fromHex("fe640b"),
	constant = Color3.fromHex("fe640b"),
	operator = Color3.fromHex("179299"),
	property = Color3.fromHex("179299"),
	parameter = Color3.fromHex("e64553"),
	builtin = Color3.fromHex("e64553"),
	self = Color3.fromHex("d20f39"),
})

return function(background: Color3)
	return if ColorSpace.Oklch.From(background):IsDark() then MOCHA else LATTE
end
