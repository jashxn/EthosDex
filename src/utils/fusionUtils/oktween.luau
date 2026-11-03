--!strict
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Root = script.Parent.Parent.Parent
local Packages = Root.packages
local Fusion = require(Packages.fusion)

local ColorSpace = require(Root.utils.colorSpace)
local Oklab = ColorSpace.Oklab

local Observer = Fusion.Observer
local peek = Fusion.peek
local Value = Fusion.Value

local DEFAULT_TWEEN_INFO = TweenInfo.new()
local REBASE_EPSILON = 1e-6

local function GetTweenDuration(tweenInfo: TweenInfo): number
	LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
	if tweenInfo.RepeatCount <= -1 then
		return math.huge
	end
	local duration = tweenInfo.DelayTime + tweenInfo.Time
	if tweenInfo.Reverses then
		duration += tweenInfo.Time
	end
	return duration * (tweenInfo.RepeatCount + 1)
end

local function GetTweenRatio(tweenInfo: TweenInfo, elapsed: number): number
	LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
	local delay = tweenInfo.DelayTime
	local duration = tweenInfo.Time
	local cycleDuration = delay + duration
	if tweenInfo.Reverses then
		cycleDuration += duration
	end
	if elapsed == math.huge then
		return 1
	end
	if tweenInfo.RepeatCount > -1 and elapsed >= cycleDuration * (tweenInfo.RepeatCount + 1) then
		return 1
	end
	if cycleDuration == 0 then
		return 1
	end
	local cycleTime = elapsed % cycleDuration
	if cycleTime <= delay then
		return 0
	end
	local progress = (cycleTime - delay) / duration
	if progress > 1 then
		progress = 2 - progress
	end
	return TweenService:GetValue(progress, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
end

-- Rebasing extrapolates the Oklab origin far outside the sRGB gamut. Gamut
-- map each interpolated color before emitting it so hue is retained instead
-- of being changed by direct RGB channel clipping.
local function ToValidColor3(color: Color3): Color3
	LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
	local r = color.R
	local g = color.G
	local b = color.B
	if r ~= r then
		r = 0
	end
	if g ~= g then
		g = 0
	end
	if b ~= b then
		b = 0
	end
	return Color3.new(math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
end

local function RebaseOrigin(current: Color3, target: Color3, ratio: number)
	LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
	local currentL, currentA, currentB = Oklab.From(current):Components()
	local targetL, targetA, targetB = Oklab.From(target):Components()
	local remaining = 1 - ratio
	return Oklab.new(
		(currentL - targetL * ratio) / remaining,
		(currentA - targetA * ratio) / remaining,
		(currentB - targetB * ratio) / remaining
	)
end

local function Oktween(scope: Fusion.Scope<any>, goal: Fusion.UsedAs<Color3>, tweenInfo: TweenInfo?): Fusion.StateObject<Color3>
	LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
	local resolvedTweenInfo = tweenInfo or DEFAULT_TWEEN_INFO
	local initialColor = peek(goal)
	local output = Value(scope, ToValidColor3(initialColor))
	local activeGoal = initialColor
	local origin = Oklab.From(initialColor)
	local previousRatio = 0
	local startedAt = 0
	local totalDuration = GetTweenDuration(resolvedTweenInfo)
	local heartbeatConnection: RBXScriptConnection? = nil
	local destroyed = false

	local function Stop()
		if not heartbeatConnection then
			return
		end
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end

	local function Step()
		LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
		local nextGoal = peek(goal)
		local goalChanged = nextGoal ~= activeGoal
		if goalChanged then
			if math.abs(1 - previousRatio) > REBASE_EPSILON then
				origin = RebaseOrigin(peek(output), nextGoal, previousRatio)
			else
				origin = Oklab.From(peek(output))
			end
			activeGoal = nextGoal
		end
		local elapsed = os.clock() - startedAt
		local ratio = GetTweenRatio(resolvedTweenInfo, elapsed)
		output:set(
			ToValidColor3(
				ColorSpace.ToGamutMappedColor3(origin:Lerp(Oklab.From(activeGoal), ratio))
			)
		)
		previousRatio = ratio
		if elapsed >= totalDuration then
			output:set(ToValidColor3(activeGoal))
			previousRatio = 1
			if not goalChanged then
				Stop()
			end
		end
	end

	local function Start()
		if destroyed or heartbeatConnection then
			return
		end
		activeGoal = peek(goal)
		origin = Oklab.From(peek(output))
		previousRatio = 0
		startedAt = os.clock()
		totalDuration = GetTweenDuration(resolvedTweenInfo)
		heartbeatConnection = RunService.Heartbeat:Connect(Step)
	end

	local stopObserving = Observer(scope, goal):onChange(Start)
	table.insert(
		scope,
		function()
			destroyed = true
			stopObserving()
			Stop()
		end
	)

	return output
end

return Oktween
