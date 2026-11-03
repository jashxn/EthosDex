local Fusion = require(script.Parent.fusion)
local Maid = require(script.Parent.maid)

return {
	Scope = Fusion.scoped(Fusion),
	Maid = Maid.new(),
}
