local Root = script.Parent.Parent
local Internal = require(Root.packages.internal)

local scope = Internal.Scope

return {
	Theme = scope:Value("eclipse"),
	EffectiveDPIScale = scope:Value(1),
	AnimationsEnabled = scope:Value(true),
	ServerConnected = scope:Value(false),
	ServerConnecting = scope:Value(false),
	ServerAuthenticating = scope:Value(false),
	AgentNeedsAttention = scope:Value(false),
	Keybinds = scope:Value({}),
	ActiveKeybinds = scope:Value({}),
}
