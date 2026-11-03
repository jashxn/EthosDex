local Root = script.Parent.Parent
local States = require(Root.packages.states)

local Motion = {}

function Motion.Snap(duration, delay)
	return TweenInfo.new(
		duration,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out,
		0,
		false,
		delay or 0
	)
end

function Motion.Soft(duration)
	return TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
end

function Motion.Animate(scope, goal, info)
	local tween = scope:Tween(goal, info)
	return scope:Computed(function(use)
		return if use(States.AnimationsEnabled) == false then use(goal) else use(tween)
	end)
end

function Motion.Fade(scope, base, ...)
	local opacities = { ... }
	return scope:Computed(function(use)
		local alpha = 1 - use(base)
		for _, opacity in opacities do
			alpha *= use(opacity)
		end
		return 1 - alpha
	end)
end

return table.freeze(Motion)
