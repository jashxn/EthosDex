if not LPH_OBFUSCATED then
	local env = getfenv()
	env.LPH_ATTRIBUTES = env.LPH_ATTRIBUTES
		or function()
		end
	env.VM = env.VM
		or function(...)
			return ...
		end
	env.PRESET = env.PRESET
		or function(...)
			return ...
		end
	env.ERROR_HANDLING = env.ERROR_HANDLING
		or function(...)
			return ...
		end
end

local a
local function resolveLibraryRoot(startAt)
	local current = startAt
	while current do
		if current:FindFirstChild("packages") and current:FindFirstChild("utils") then
			return current
		end
		current = current.Parent
	end

	error(("Unable to resolve library root from %s"):format(startAt:GetFullName()))
end

local Root = resolveLibraryRoot(script)
local services = require(Root.packages.services)
local b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, v =
	{
		function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(1)
			local e
			return (function(...)
				local f, g, h = d(c.Types), (d(c.External))
				type Fusion = f.Fusion
				export type Animatable = f.Animatable
				export type UsedAs<T> = f.UsedAs<T>
				export type Child = f.Child
				export type Computed<T> = f.Computed<T>
				export type Contextual<T> = f.Contextual<T>
				export type GraphObject = f.GraphObject
				export type For<KO, VO> = f.For<KO, VO>
				export type Observer = f.Observer
				export type PropertyTable = f.PropertyTable
				export type Scope<Constructors = Fusion> = f.Scope<Constructors>
				export type ScopedObject = f.ScopedObject
				export type SpecialKey = f.SpecialKey
				export type Spring<T> = f.Spring<T>
				export type StateObject<T> = f.StateObject<T>
				export type Task = f.Task
				export type Tween<T> = f.Tween<T>
				export type Use = f.Use
				export type Value<T, S = T> = f.Value<T, S>
				export type Version = f.Version
				do
					local i = d(c.RobloxExternal)
					g.setExternalProvider(i)
				end
				local i: Fusion = table.freeze({
					version = { major = 0, minor = 4, isRelease = false },
					cleanup = function()
						return g.stopUpdateStep()
					end,
					Contextual = d(c.Utility.Contextual),
					Safe = d(c.Utility.Safe),
					deriveScope = d(c.Memory.deriveScope),
					doCleanup = d(c.Memory.doCleanup),
					innerScope = d(c.Memory.innerScope),
					insert = d(c.Memory.insert),
					scoped = d(c.Memory.scoped),
					Observer = d(c.Graph.Observer),
					Computed = d(c.State.Computed),
					ForKeys = d(c.State.ForKeys) :: f.ForKeysConstructor,
					ForPairs = d(c.State.ForPairs) :: f.ForPairsConstructor,
					ForValues = d(c.State.ForValues) :: f.ForValuesConstructor,
					peek = d(c.State.peek),
					Value = d(c.State.Value),
					Attribute = d(c.Instances.Attribute),
					AttributeChange = d(c.Instances.AttributeChange),
					AttributeOut = d(c.Instances.AttributeOut),
					Child = d(c.Instances.Child),
					Children = d(c.Instances.Children),
					Hydrate = d(c.Instances.Hydrate),
					New = d(c.Instances.New),
					OnChange = d(c.Instances.OnChange),
					OnEvent = d(c.Instances.OnEvent),
					Out = d(c.Instances.Out),
					Tag = d(c.Instances.Tag),
					Tween = d(c.Animation.Tween),
					Spring = d(c.Animation.Spring),
				})
				return i
			end)()
		end,
		[3] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(3)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k =
					d(f.Types),
					d(f.External),
					d(f.Graph.change),
					d(f.Utility.nicknames)
				type ExternalTime = h.StateObject<number>
				type Self = ExternalTime
				local l = {}
				l.type = "State"
				l.kind = "ExternalTime"
				l.timeliness = "lazy"
				l.dependencySet = table.freeze({})
				setmetatable(
					l,
					{
						__index = function(_, key)
							if key == "_EXTREMELY_DANGEROUS_usedAsValue" then
								return i.lastUpdateStep()
							end
							return nil
						end,
					}
				)
				local m, n = table.freeze({ __index = l }), {}
				local function o(p: h.Scope<unknown>): ExternalTime
					local q = os.clock()
					local r: Self
					r = setmetatable(
						{
							createdAt = q,
							-- Graph.depend adds dependents by assignment, which marks the clock active.
							dependentSet = setmetatable(
								{},
								{
									__newindex = function(t, key, value)
										rawset(t, key, value)
										n[r] = true
									end,
								}
							),
							lastChange = nil,
							scope = p,
							validity = "invalid",
						},
						m
					) :: any
					local s = function()
						r.scope = nil
						n[r] = nil
					end
					r.oldestTask = s
					k[r.oldestTask] = "ExternalTime"
					table.insert(p, s)
					return r
				end
				function l._evaluate(p: Self): boolean
					return true
				end
				local stepping = {}
				i.bindToUpdateStep(function(p: number): ()
					for r in n do
						if next(r.dependentSet) == nil then
							n[r] = nil
						else
							table.insert(stepping, r)
						end
					end
					for _, r in stepping do
						j(r)
					end
					table.clear(stepping)
				end)
				return o
			end)()
		end,
		[4] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(4)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m, n, o, p, q, r, s, t, u, v =
					d(f.Types),
					d(f.External),
					d(f.Memory.checkLifetime),
					d(f.Graph.depend),
					d(f.Graph.change),
					d(f.Graph.evaluate),
					d(f.State.castToState),
					d(f.State.peek),
					d(f.Animation.ExternalTime),
					d(f.Animation.Stopwatch),
					d(f.Animation.packType),
					d(f.Animation.unpackType),
					d(f.Animation.springCoefficients),
					d(f.Utility.nicknames),
					0.00001
				type Self<T> = h.Spring<T> & {
					_activeDamping: number,
					_activeGoal: T,
					_activeLatestP: { number },
					_activeLatestV: { number },
					_activeNumSprings: number,
					_activeSpeed: number,
					_activeStartP: { number },
					_activeStartV: { number },
					_activeTargetP: { number },
					_activeType: string,
					_speed: h.UsedAs<number>,
					_damping: h.UsedAs<number>,
					_goal: h.UsedAs<T>,
					_stopwatch: q.Stopwatch,
				}
				local w = {}
				w.type = "State"
				w.kind = "Spring"
				w.timeliness = "eager"
				local x = table.freeze({ __index = w })
				local function y<T>(
					z: h.Scope<unknown>,
					A: h.UsedAs<T>,
					B: h.UsedAs<number>?,
					C: h.UsedAs<number>?
				): h.Spring<T>
					local D, E, F = os.clock(), (n(A))
					if E ~= nil then
						F = q(z, p(z))
						F:unpause()
					end
					local G, H = B or 10, C or 1
					local I: Self<T> = setmetatable(
						{
							createdAt = D,
							dependencySet = {},
							dependentSet = {},
							lastChange = nil,
							scope = z,
							validity = "invalid",
							_activeDamping = -1,
							_activeGoal = nil,
							_activeLatestP = {},
							_activeLatestV = {},
							_activeNumSprings = 0,
							_activeSpeed = -1,
							_activeStartP = {},
							_activeStartV = {},
							_activeTargetP = {},
							_activeType = "",
							_damping = H,
							_EXTREMELY_DANGEROUS_usedAsValue = o(A),
							_goal = A,
							_speed = G,
							_stopwatch = F,
						},
						x
					) :: any
					local J = function()
						I.scope = nil
						for J in pairs(I.dependencySet) do
							J.dependentSet[I] = nil
						end
					end
					I.oldestTask = J
					u[I.oldestTask] = "Spring"
					table.insert(z, J)
					if E ~= nil then
						j.bOutlivesA(
							z,
							I.oldestTask,
							E.scope,
							E.oldestTask,
							j.formatters.animationGoal
						)
					end
					local K = n(G)
					if K ~= nil then
						j.bOutlivesA(
							z,
							I.oldestTask,
							K.scope,
							K.oldestTask,
							j.formatters.parameter,
							"speed"
						)
					end
					local L = n(H)
					if L ~= nil then
						j.bOutlivesA(
							z,
							I.oldestTask,
							L.scope,
							L.oldestTask,
							j.formatters.parameter,
							"damping"
						)
					end
					m(I, true)
					return I
				end
				function w.addVelocity<T>(z: Self<T>, A: T): ()
					m(z, false)
					local B = typeof(A)
					if B ~= z._activeType then
						i.logError("springTypeMismatch", nil, B, z._activeType)
					end
					local C = s(A, B)
					for D, E in z._activeLatestV do
						C[D] += E
					end
					z._activeStartP = table.clone(z._activeLatestP)
					z._activeStartV = C
					z._stopwatch:zero()
					z._stopwatch:unpause()
					l(z)
				end
				function w.setPosition<T>(z: Self<T>, A: T): ()
					m(z, false)
					local B = typeof(A)
					if B ~= z._activeType then
						i.logError("springTypeMismatch", nil, B, z._activeType)
					end
					z._activeStartP = s(A, B)
					z._activeStartV = table.clone(z._activeLatestV)
					z._stopwatch:zero()
					z._stopwatch:unpause()
					l(z)
				end
				function w.setVelocity<T>(z: Self<T>, A: T): ()
					m(z, false)
					local B = typeof(A)
					if B ~= z._activeType then
						i.logError("springTypeMismatch", nil, B, z._activeType)
					end
					z._activeStartP = table.clone(z._activeLatestP)
					z._activeStartV = s(A, B)
					z._stopwatch:zero()
					z._stopwatch:unpause()
					l(z)
				end
				function w._evaluate<T>(z: Self<T>): boolean
					local A = n(z._goal)
					if A == nil then
						z._EXTREMELY_DANGEROUS_usedAsValue = z._goal :: T
						return false
					end
					local B, C = k(z, A), z._stopwatch :: q.Stopwatch
					local D = k(z, C)
					if B ~= B then
						i.logWarn("springNanGoal")
						return false
					end
					local E = typeof(B)
					local F, G: T = (E ~= z._activeType)
					if F then
						G = B
					else
						local H, I, J, K = t(D, z._activeDamping, z._activeSpeed)
						local L = false
						for M = 1, z._activeNumSprings do
							local N, O, P =
								z._activeStartP[M],
								z._activeTargetP[M],
								z._activeStartV[M]
							local Q = N - O
							local R, S = Q * H + P * I, Q * J + P * K
							if R ~= R or S ~= S then
								i.logWarn("springNanMotion")
								R, S = 0, 0
							end
							if math.abs(R) > v or math.abs(S) > v then
								L = true
							end
							local T = R + O
							z._activeLatestP[M] = T
							z._activeLatestV[M] = S
						end
						if not L and C:isPlaying() then
							z._activeLatestP = table.clone(z._activeTargetP)
							z._activeLatestV = table.create(z._activeNumSprings, 0)
							C:pause()
							C:zero()
						end
						G = r(z._activeLatestP, z._activeType) :: any
					end
					local H, I = o(z._speed) :: number, o(z._damping) :: number
					if F or B ~= z._activeGoal or H ~= z._activeSpeed or I ~= z._activeDamping then
						z._activeTargetP = s(B, E)
						z._activeNumSprings = #z._activeTargetP
						if F then
							z._activeStartP = table.clone(z._activeTargetP)
							z._activeLatestP = table.clone(z._activeTargetP)
							z._activeStartV = table.create(z._activeNumSprings, 0)
							z._activeLatestV = table.create(z._activeNumSprings, 0)
						else
							z._activeStartP = table.clone(z._activeLatestP)
							z._activeStartV = table.clone(z._activeLatestV)
						end
						z._activeType = E
						z._activeGoal = B
						z._activeDamping = I
						z._activeSpeed = H
						C:zero()
						C:unpause()
					end
					local J = z._EXTREMELY_DANGEROUS_usedAsValue
					z._EXTREMELY_DANGEROUS_usedAsValue = G
					return J ~= G
				end
				table.freeze(w)
				return y :: h.SpringConstructor
			end)()
		end,
		[5] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(5)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m =
					d(f.Types),
					d(f.Memory.checkLifetime),
					d(f.Graph.depend),
					d(f.Graph.change),
					d(f.State.peek),
					d(f.Utility.nicknames)
				export type Stopwatch = h.StateObject<number> & {
					zero: (Stopwatch) -> (),
					pause: (Stopwatch) -> (),
					unpause: (Stopwatch) -> (),
					isPlaying: (Stopwatch) -> boolean,
				}
				type Self = Stopwatch & {
					_measureTimeSince: number,
					_playing: boolean,
					_zeroFlag: boolean,
					_timer: h.StateObject<number>,
				}
				local n = {}
				n.type = "State"
				n.kind = "Stopwatch"
				n.timeliness = "lazy"
				local o = table.freeze({
					__index = n,
				})
				local function p(q: h.Scope<unknown>, r: h.StateObject<number>): Stopwatch
					local s = os.clock()
					local t: Self = setmetatable(
						{
							awake = true,
							createdAt = s,
							dependencySet = {},
							dependentSet = {},
							lastChange = nil,
							scope = q,
							validity = "invalid",
							_EXTREMELY_DANGEROUS_usedAsValue = 0,
							_measureTimeSince = 0,
							_playing = false,
							_zeroFlag = true,
							_timer = r,
						},
						o
					) :: any
					local u = function()
						t.scope = nil
					end
					t.oldestTask = u
					m[t.oldestTask] = "Stopwatch"
					table.insert(q, u)
					i.bOutlivesA(
						q,
						t.oldestTask,
						r.scope,
						r.oldestTask,
						i.formatters.parameter,
						"timer"
					)
					j(t, r)
					return t
				end
				function n.zero(q: Self): ()
					q._zeroFlag = true
					q._measureTimeSince = l(q._timer)
					k(q)
				end
				function n.pause(q: Self): ()
					if q._playing == true then
						q._playing = false
						k(q)
					end
				end
				function n.unpause(q: Self): ()
					if q._playing == false then
						q._playing = true
						q._measureTimeSince = l(q._timer)
							- (if q._zeroFlag then 0 else q._EXTREMELY_DANGEROUS_usedAsValue)
						k(q)
					end
				end
				function n.isPlaying(q: Self): boolean
					return q._playing
				end
				function n._evaluate(q: Self): boolean
					if q._playing then
						q._zeroFlag = false
						local r, s = j(q, q._timer), q._EXTREMELY_DANGEROUS_usedAsValue
						local t = r - q._measureTimeSince
						q._EXTREMELY_DANGEROUS_usedAsValue = t
						return s ~= t
					else
						return false
					end
				end
				table.freeze(n)
				return p
			end)()
		end,
		[6] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(6)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m, n, o, p, q, r, s, t =
					d(f.Types),
					d(f.External),
					d(f.Memory.checkLifetime),
					d(f.Graph.depend),
					d(f.Graph.evaluate),
					d(f.State.castToState),
					d(f.State.peek),
					d(f.Animation.ExternalTime),
					d(f.Animation.Stopwatch),
					d(f.Animation.lerpType),
					d(f.Animation.getTweenRatio),
					d(f.Animation.getTweenDuration),
					d(f.Utility.nicknames)
				export type Self<T> = h.Tween<T> & {
					_activeDuration: number,
					_activeElapsed: number,
					_activeFrom: T,
					_activeTo: T,
					_activeTweenInfo: TweenInfo,
					_goal: h.UsedAs<T>,
					_stopwatch: p.Stopwatch?,
					_tweenInfo: h.UsedAs<TweenInfo>,
				}
				local u = {}
				u.type = "State"
				u.kind = "Tween"
				u.timeliness = "eager"
				local v = table.freeze({ __index = u })
				local function w<T>(x: h.Scope<unknown>, y: h.UsedAs<T>, z: h.UsedAs<TweenInfo>?): h.Tween<T>
					local A, B, C = os.clock(), (m(y))
					if B ~= nil then
						C = p(x, o(x))
					end
					local D: Self<T> = setmetatable(
						{
							createdAt = A,
							dependencySet = {},
							dependentSet = {},
							lastChange = nil,
							scope = x,
							validity = "invalid",
							_activeDuration = nil,
							_activeElapsed = nil,
							_activeFrom = nil,
							_activeTo = nil,
							_activeTweenInfo = nil,
							_EXTREMELY_DANGEROUS_usedAsValue = n(y),
							_goal = y,
							_stopwatch = C,
							_tweenInfo = z or TweenInfo.new(),
						},
						v
					) :: any
					local E = function()
						D.scope = nil
						for E in pairs(D.dependencySet) do
							E.dependentSet[D] = nil
						end
					end
					D.oldestTask = E
					t[D.oldestTask] = "Tween"
					table.insert(x, E)
					if B ~= nil then
						j.bOutlivesA(
							x,
							D.oldestTask,
							B.scope,
							B.oldestTask,
							j.formatters.animationGoal
						)
					end
					local F = m(z)
					if F ~= nil then
						j.bOutlivesA(
							x,
							D.oldestTask,
							F.scope,
							F.oldestTask,
							j.formatters.parameter,
							"tween info"
						)
					end
					l(D, true)
					return D
				end
				function u._evaluate<T>(x: Self<T>): boolean
					local y = m(x._goal)
					if y == nil then
						x._EXTREMELY_DANGEROUS_usedAsValue = x._goal :: T
						return false
					end
					k(x, y)
					local z = n(y)
					if z ~= z then
						i.logWarn("tweenNanGoal")
						return false
					end
					local A, B = x._stopwatch :: p.Stopwatch, n(x._tweenInfo) :: TweenInfo
					if x._activeTo ~= z
						or (x._activeElapsed < x._activeDuration and x._activeTweenInfo ~= B) then
						x._activeDuration = s(B)
						x._activeFrom = x._EXTREMELY_DANGEROUS_usedAsValue
						x._activeTo = z
						x._activeTweenInfo = B
						A:zero()
						A:unpause()
					end
					k(x, A)
					x._activeElapsed = n(A)
					if x._activeFrom == x._activeTo
						or x._activeElapsed >= x._activeDuration
						or typeof(x._activeTo) ~= typeof(x._activeFrom) then
						x._activeFrom = x._activeTo
						x._activeElapsed = x._activeDuration
						A:pause()
					end
					local C, D = r(B, x._activeElapsed), x._EXTREMELY_DANGEROUS_usedAsValue
					local E = q(x._activeFrom, x._activeTo, C) :: T
					if E ~= E then
						i.logWarn("tweenNanMotion")
						E = x._activeTo
					end
					x._EXTREMELY_DANGEROUS_usedAsValue = E
					return D ~= E
				end
				table.freeze(u)
				return w :: h.TweenConstructor
			end)()
		end,
		[7] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(7)
			local e
			return (function(...)
				local f, g = (services.TweenService)
				local function h(i: TweenInfo): number
					if i.RepeatCount <= -1 then
						return math.huge
					end
					local j = i.DelayTime + i.Time
					if i.Reverses then
						j += i.Time
					end
					j *= i.RepeatCount + 1
					return j
				end
				return h
			end)()
		end,
		[8] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(8)
			local e
			return (function(...)
				local f, g = (services.TweenService)
				local function h(i: TweenInfo, j: number): number
					local k, l, m, n, o, p =
						i.DelayTime,
						i.Time,
						i.Reverses,
						1 + i.RepeatCount,
						i.EasingStyle,
						i.EasingDirection
					local q = k + l
					if m then
						q += l
					end
					if j == math.huge then
						return 1
					end
					if j >= q * n and i.RepeatCount > -1 then
						return 1
					end
					local r = j % q
					if r <= k then
						return 0
					end
					local s = (r - k) / l
					if s > 1 then
						s = 2 - s
					end
					local t = f:GetValue(s, o, p)
					return t
				end
				return h
			end)()
		end,
		[9] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(9)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h = d(f.Colour.Oklab)
				local function i(j: unknown, k: unknown, l: number): unknown
					local m = typeof(j)
					if typeof(k) == m then
						if m == "number" then
							local n, o = k :: number, j :: number
							return (n - o) * l + o
						elseif m == "CFrame" then
							local n, o = k :: CFrame, j :: CFrame
							return o:Lerp(n, l)
						elseif m == "Color3" then
							local n, o = k :: Color3, j :: Color3
							local p, q = h.fromSRGB(o), h.fromSRGB(n)
							return h.toSRGB(p:Lerp(q, l), false)
						elseif m == "ColorSequenceKeypoint" then
							local n, o = k :: ColorSequenceKeypoint, j :: ColorSequenceKeypoint
							local p, q = h.fromSRGB(o.Value), h.fromSRGB(n.Value)
							return ColorSequenceKeypoint.new(
								(n.Time - o.Time) * l + o.Time,
								h.toSRGB(p:Lerp(q, l), false)
							)
						elseif m == "DateTime" then
							local n, o = k :: DateTime, j :: DateTime
							return DateTime.fromUnixTimestampMillis(
								(n.UnixTimestampMillis - o.UnixTimestampMillis) * l
									+ o.UnixTimestampMillis
							)
						elseif m == "NumberRange" then
							local n, o = k :: NumberRange, j :: NumberRange
							return NumberRange.new(
								(n.Min - o.Min) * l + o.Min,
								(n.Max - o.Max) * l + o.Max
							)
						elseif m == "NumberSequenceKeypoint" then
							local n, o = k :: NumberSequenceKeypoint, j :: NumberSequenceKeypoint
							return NumberSequenceKeypoint.new(
								(n.Time - o.Time) * l + o.Time,
								(n.Value - o.Value) * l + o.Value,
								(n.Envelope - o.Envelope) * l + o.Envelope
							)
						elseif m == "PhysicalProperties" then
							local n, o = k :: PhysicalProperties, j :: PhysicalProperties
							return PhysicalProperties.new(
								(n.Density - o.Density) * l + o.Density,
								(n.Friction - o.Friction) * l + o.Friction,
								(n.Elasticity - o.Elasticity) * l + o.Elasticity,
								(n.FrictionWeight - o.FrictionWeight) * l + o.FrictionWeight,
								(n.ElasticityWeight - o.ElasticityWeight) * l + o.ElasticityWeight
							)
						elseif m == "Ray" then
							local n, o = k :: Ray, j :: Ray
							return Ray.new(
								o.Origin:Lerp(n.Origin, l),
								o.Direction:Lerp(n.Direction, l)
							)
						elseif m == "Rect" then
							local n, o = k :: Rect, j :: Rect
							return Rect.new(o.Min:Lerp(n.Min, l), o.Max:Lerp(n.Max, l))
						elseif m == "Region3" then
							local n, o = k :: Region3, j :: Region3
							local p, q =
								o.CFrame.Position:Lerp(n.CFrame.Position, l),
								o.Size:Lerp(n.Size, l) / 2
							return Region3.new(p - q, p + q)
						elseif m == "Region3int16" then
							local n, o = k :: Region3int16, j :: Region3int16
							return Region3int16.new(
								Vector3int16.new(
									(n.Min.X - o.Min.X) * l + o.Min.X,
									(n.Min.Y - o.Min.Y) * l + o.Min.Y,
									(n.Min.Z - o.Min.Z) * l + o.Min.Z
								),
								Vector3int16.new(
									(n.Max.X - o.Max.X) * l + o.Max.X,
									(n.Max.Y - o.Max.Y) * l + o.Max.Y,
									(n.Max.Z - o.Max.Z) * l + o.Max.Z
								)
							)
						elseif m == "UDim" then
							local n, o = k :: UDim, j :: UDim
							return UDim.new(
								(n.Scale - o.Scale) * l + o.Scale,
								(n.Offset - o.Offset) * l + o.Offset
							)
						elseif m == "UDim2" then
							local n, o = k :: UDim2, j :: UDim2
							return o:Lerp(n, l)
						elseif m == "Vector2" then
							local n, o = k :: Vector2, j :: Vector2
							return o:Lerp(n, l)
						elseif m == "Vector2int16" then
							local n, o = k :: Vector2int16, j :: Vector2int16
							return Vector2int16.new((n.X - o.X) * l + o.X, (n.Y - o.Y) * l + o.Y)
						elseif m == "Vector3" then
							local n, o = k :: Vector3, j :: Vector3
							return o:Lerp(n, l)
						elseif m == "Vector3int16" then
							local n, o = k :: Vector3int16, j :: Vector3int16
							return Vector3int16.new(
								(n.X - o.X) * l + o.X,
								(n.Y - o.Y) * l + o.Y,
								(n.Z - o.Z) * l + o.Z
							)
						end
					end
					if l < 0.5 then
						return j
					else
						return k
					end
				end
				return i
			end)()
		end,
		[10] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(10)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i = d(f.Types), d(f.Colour.Oklab)
				local function j(k: { number }, l: string): h.Animatable?
					if l == "number" then
						return k[1]
					elseif l == "CFrame" then
						return CFrame.new(k[1], k[2], k[3])
							* CFrame.fromAxisAngle(Vector3.new(k[4], k[5], k[6]).Unit, k[7])
					elseif l == "Color3" then
						return i.toSRGB(Vector3.new(k[1], k[2], k[3]), false)
					elseif l == "ColorSequenceKeypoint" then
						return ColorSequenceKeypoint.new(
							k[4],
							i.toSRGB(Vector3.new(k[1], k[2], k[3]), false)
						)
					elseif l == "DateTime" then
						return DateTime.fromUnixTimestampMillis(k[1])
					elseif l == "NumberRange" then
						return NumberRange.new(k[1], k[2])
					elseif l == "NumberSequenceKeypoint" then
						return NumberSequenceKeypoint.new(k[2], k[1], k[3])
					elseif l == "PhysicalProperties" then
						return PhysicalProperties.new(k[1], k[2], k[3], k[4], k[5])
					elseif l == "Ray" then
						return Ray.new(Vector3.new(k[1], k[2], k[3]), Vector3.new(k[4], k[5], k[6]))
					elseif l == "Rect" then
						return Rect.new(k[1], k[2], k[3], k[4])
					elseif l == "Region3" then
						local m, n =
							Vector3.new(k[1], k[2], k[3]),
							Vector3.new(k[4] / 2, k[5] / 2, k[6] / 2)
						return Region3.new(m - n, m + n)
					elseif l == "Region3int16" then
						return Region3int16.new(
							Vector3int16.new(math.round(k[1]), math.round(k[2]), math.round(k[3])),
							Vector3int16.new(math.round(k[4]), math.round(k[5]), math.round(k[6]))
						)
					elseif l == "UDim" then
						return UDim.new(k[1], math.round(k[2]))
					elseif l == "UDim2" then
						return UDim2.new(k[1], math.round(k[2]), k[3], math.round(k[4]))
					elseif l == "Vector2" then
						return Vector2.new(k[1], k[2])
					elseif l == "Vector2int16" then
						return Vector2int16.new(math.round(k[1]), math.round(k[2]))
					elseif l == "Vector3" then
						return Vector3.new(k[1], k[2], k[3])
					elseif l == "Vector3int16" then
						return Vector3int16.new(
							math.round(k[1]),
							math.round(k[2]),
							math.round(k[3])
						)
					else
						return nil
					end
				end
				return j
			end)()
		end,
		[11] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(11)
			local e
			return (function(...)
				local f
				local function g(h: number, i: number, j: number): (number, number, number, number)
					if h == 0 or j == 0 then
						return 1, 0, 0, 1
					end
					local k, l, m, n
					if i > 1 then
						local o = math.sqrt(i ^ 2 - 1)
						local p, q, r = -0.5 / (o * j), j * (o + i) * -1, j * (o - i)
						local s, t = math.exp(h * q), math.exp(h * r)
						k = (t * q - s * r) * p
						l = (s - t) * p / j
						m = (t - s) * p * j
						n = (s * q - t * r) * p
					elseif i == 1 then
						local o = h * j
						local p = o * -1
						local q = math.exp(p)
						k = q * (o + 1)
						l = q * h
						m = q * (p * j)
						n = q * (p + 1)
					else
						local o = j * math.sqrt(1 - i ^ 2)
						local p, q, r, s =
							1 / o,
							math.exp(-1 * h * j * i),
							math.sin(o * h),
							math.cos(o * h)
						local t, u = q * r, q * s
						local v = t * j * i * p
						k = v + u
						l = t * p
						m = -1 * (t * o + j * i * v)
						n = u - v
					end
					return k, l, m, n
				end
				return g
			end)()
		end,
		[12] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(12)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h = d(f.Colour.Oklab)
				local function i(j: unknown, k: string): { number }
					if k == "number" then
						local l = j :: number
						return { l }
					elseif k == "CFrame" then
						local l = j :: CFrame
						local m, n = l:ToAxisAngle()
						return { l.X, l.Y, l.Z, m.X, m.Y, m.Z, n }
					elseif k == "Color3" then
						local l = j :: Color3
						local m = h.fromSRGB(l)
						return { m.X, m.Y, m.Z }
					elseif k == "ColorSequenceKeypoint" then
						local l = j :: ColorSequenceKeypoint
						local m = h.fromSRGB(l.Value)
						return { m.X, m.Y, m.Z, l.Time }
					elseif k == "DateTime" then
						local l = j :: DateTime
						return { l.UnixTimestampMillis }
					elseif k == "NumberRange" then
						local l = j :: NumberRange
						return { l.Min, l.Max }
					elseif k == "NumberSequenceKeypoint" then
						local l = j :: NumberSequenceKeypoint
						return { l.Value, l.Time, l.Envelope }
					elseif k == "PhysicalProperties" then
						local l = j :: PhysicalProperties
						return {
							l.Density,
							l.Friction,
							l.Elasticity,
							l.FrictionWeight,
							l.ElasticityWeight,
						}
					elseif k == "Ray" then
						local l = j :: Ray
						return {
							l.Origin.X,
							l.Origin.Y,
							l.Origin.Z,
							l.Direction.X,
							l.Direction.Y,
							l.Direction.Z,
						}
					elseif k == "Rect" then
						local l = j :: Rect
						return { l.Min.X, l.Min.Y, l.Max.X, l.Max.Y }
					elseif k == "Region3" then
						local l = j :: Region3
						return { l.CFrame.X, l.CFrame.Y, l.CFrame.Z, l.Size.X, l.Size.Y, l.Size.Z }
					elseif k == "Region3int16" then
						local l = j :: Region3int16
						return { l.Min.X, l.Min.Y, l.Min.Z, l.Max.X, l.Max.Y, l.Max.Z }
					elseif k == "UDim" then
						local l = j :: UDim
						return { l.Scale, l.Offset }
					elseif k == "UDim2" then
						local l = j :: UDim2
						return { l.X.Scale, l.X.Offset, l.Y.Scale, l.Y.Offset }
					elseif k == "Vector2" then
						local l = j :: Vector2
						return { l.X, l.Y }
					elseif k == "Vector2int16" then
						local l = j :: Vector2int16
						return { l.X, l.Y }
					elseif k == "Vector3" then
						local l = j :: Vector3
						return { l.X, l.Y, l.Z }
					elseif k == "Vector3int16" then
						local l = j :: Vector3int16
						return { l.X, l.Y, l.Z }
					else
						return {}
					end
				end
				return i
			end)()
		end,
		[14] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(14)
			local e
			return (function(...)
				local f, g, h = d(c.Parent.sRGB), {}
				function g.fromLinear(i: Color3): Vector3
					local j, k, l =
						i.R * 0.4122214708 + i.G * 0.5363325363 + i.B * 0.0514459929,
						i.R * 0.2119034982 + i.G * 0.6806995451 + i.B * 0.1073969566,
						i.R * 0.0883024619 + i.G * 0.2817188376 + i.B * 0.6299787005
					local m, n, o =
						j ^ 0.3333333333333333,
						k ^ 0.3333333333333333,
						l ^ 0.3333333333333333
					return Vector3.new(
						m * 0.2104542553 + n * 0.793617785 - o * 0.0040720468,
						m * 1.9779984951 - n * 2.428592205 + o * 0.4505937099,
						m * 0.0259040371 + n * 0.7827717662 - o * 0.808675766
					)
				end
				function g.fromSRGB(i: Color3): Vector3
					return g.fromLinear(f.toLinear(i))
				end
				function g.toLinear(i: Vector3, j: boolean?): Color3
					local k, l, m =
						i.X + i.Y * 0.3963377774 + i.Z * 0.2158037573,
						i.X - i.Y * 0.1055613458 - i.Z * 0.0638541728,
						i.X - i.Y * 0.0894841775 - i.Z * 1.291485548
					local n, o, p = k ^ 3, l ^ 3, m ^ 3
					local q, r, s =
						n * 4.0767416621 - o * 3.3077115913 + p * 0.2309699292,
						n * -1.2684380046 + o * 2.6097574011 - p * 0.3413193965,
						n * -4.1960863E-3 - o * 0.7034186147 + p * 1.707614701
					if not j then
						q = math.clamp(q, 0, 1)
						r = math.clamp(r, 0, 1)
						s = math.clamp(s, 0, 1)
					end
					return Color3.new(q, r, s)
				end
				function g.toSRGB(i: Vector3, j: boolean?): Color3
					return f.fromLinear(g.toLinear(i, j))
				end
				return g
			end)()
		end,
		[15] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(15)
			local e
			return (function(...)
				local f, g = {}
				local function h(i: number): number
					if i < 0.04045 then
						return i / 12.92
					end
					return ((i + 0.055) / 1.055) ^ 2.4
				end
				local function i(j: number): number
					if j < 0.0031308 then
						return 12.92 * j
					end
					return (1.055 * j ^ 0.4166666666666667) - 0.055
				end
				function f.fromLinear(j: Color3): Color3
					return Color3.new(i(j.R), i(j.G), i(j.B))
				end
				function f.toLinear(j: Color3): Color3
					return Color3.new(h(j.R), h(j.G), h(j.B))
				end
				return f
			end)()
		end,
		[16] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(16)
			local e
			return (function(...)
				local f, g = c.Parent
				local h, i, j, k =
					d(f.Logging.formatError),
					d(f.Types),
					"https://elttob.uk/Fusion/0.3/api-reference/general/errors/#",
					{}
				k.safetyTimerMultiplier = 1
				local l, m, n: i.ExternalProvider? = {}, 0
				function k.setExternalProvider(o: i.ExternalProvider?): i.ExternalProvider?
					local p = n
					if p ~= nil then
						p.stopScheduler()
					end
					n = o
					if o ~= nil then
						o.startScheduler()
					end
					return p
				end
				function k.stopUpdateStep(): () -> ()
					local p = n
					if p == nil then
						return function()
						end
					end
					p.stopScheduler()
					return function()
						if n == p then
							p.startScheduler()
						end
					end
				end
				function k.doTaskImmediate(o: () -> ())
					if n == nil then
						k.logError("noTaskScheduler")
					else
						n.doTaskImmediate(o)
					end
				end
				function k.doTaskDeferred(o: () -> ())
					if n == nil then
						k.logError("noTaskScheduler")
					else
						n.doTaskDeferred(o)
					end
				end
				function k.logError(o: string, p: i.Error?, ...: unknown): never
					error(h(n, o, p, ...), 0)
				end
				function k.logErrorNonFatal(o: string, p: i.Error?, ...: unknown): ()
					local q = h(n, o, p, ...)
					if n ~= nil then
						n.logErrorNonFatal(q)
					else
						print(q)
					end
				end
				function k.logWarn(o: string, ...: unknown): ()
					local p = h(n, o, debug.traceback(nil, 2), ...)
					if n ~= nil then
						n.logWarn(p)
					else
						print(p)
					end
				end
				function k.bindToUpdateStep(o: (now: number) -> ()): () -> ()
					local p = {}
					l[p] = o
					return function()
						l[p] = nil
					end
				end
				function k.performUpdateStep(o: number)
					m = o
					for p, q in l do
						q(o)
					end
				end
				function k.lastUpdateStep()
					return m
				end
				return k
			end)()
		end,
		[17] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(17)
			local e
			return (function(...)
				local f, g = c.Parent
				local h, i, j, k: Types.ExternalDebugger? = d(f.Types), 0, {}
				function j.setDebugger(l: h.ExternalDebugger?): h.ExternalDebugger?
					local m = k
					if m ~= nil then
						m.stopDebugging()
					end
					k = l
					if l ~= nil then
						l.startDebugging()
					end
					return m
				end
				function j.trackScope(l: h.Scope<unknown>): ()
					if k == nil then
						return
					end
					k.trackScope(l)
				end
				function j.untrackScope(l: h.Scope<unknown>): ()
					if k == nil then
						return
					end
					k.trackScope(l)
				end
				return j
			end)()
		end,
		[19] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(19)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m, n =
					d(f.Types),
					d(f.External),
					d(f.Memory.checkLifetime),
					d(f.Graph.castToGraph),
					d(f.Graph.depend),
					d(f.Graph.evaluate),
					d(f.Utility.nicknames)
				type Self = h.Observer & {
					_watchingGraph: h.GraphObject?,
					_changeListeners: { [unknown]: () -> () },
				}
				local o = {}
				o.type = "Observer"
				o.timeliness = "eager"
				o.dependentSet = table.freeze({})
				local p = table.freeze({ __index = o })
				local function q(r: h.Scope<unknown>, s: unknown): h.Observer
					local t = os.clock()
					local u: Self = setmetatable(
						{
							scope = r,
							createdAt = t,
							dependencySet = {},
							lastChange = nil,
							validity = "invalid",
							_watchingGraph = k(s),
							_changeListeners = {},
						},
						p
					) :: any
					local v = function()
						u.scope = nil
						for v in pairs(u.dependencySet) do
							v.dependentSet[u] = nil
						end
					end
					u.oldestTask = v
					n[u.oldestTask] = "Observer"
					table.insert(r, v)
					if u._watchingGraph ~= nil then
						j.bOutlivesA(
							r,
							u.oldestTask,
							u._watchingGraph.scope,
							u._watchingGraph.oldestTask,
							j.formatters.observer
						)
					end
					m(u, true)
					return u
				end
				function o.onBind(r: Self, s: () -> ()): () -> ()
					i.doTaskImmediate(s)
					return r:onChange(s)
				end
				function o.onChange(r: Self, s: () -> ()): () -> ()
					local t = table.freeze({})
					r._changeListeners[t] = s
					return function()
						r._changeListeners[t] = nil
					end
				end
				function o._evaluate(r: Self): ()
					if r._watchingGraph ~= nil then
						l(r, r._watchingGraph)
					end
					for s, t in r._changeListeners do
						i.doTaskImmediate(t)
					end
					return true
				end
				table.freeze(o)
				return q :: h.ObserverConstructor
			end)()
		end,
		[20] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(20)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h = d(f.Types)
				local function i(j: any): h.GraphObject?
					if typeof(j) == "table"
						and typeof(j.validity) == "string"
						and typeof(j.timeliness) == "string"
						and typeof(j.dependencySet) == "table"
						and typeof(j.dependentSet) == "table" then
						return j
					else
						return nil
					end
				end
				return i
			end)()
		end,
		[21] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(21)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k = d(f.Types), d(f.External), d(f.Graph.evaluate), 1
				local function l(m: h.GraphObject): ()
					if m.validity == "busy" then
						return i.logError("infiniteLoop")
					end
					local n = j(m, true)
					if not n then
						return
					end
					local o: { h.GraphObject }, p: { h.GraphObject }, q: { h.GraphObject } =
						{},
						{},
						{}
					o[1] = m
					local r = os.clock() + k * i.safetyTimerMultiplier
					repeat
						if os.clock() > r then
							return i.logError("infiniteLoop")
						end
						local s = true
						for t, u in o do
							for v in u.dependentSet do
								if v.validity == "valid" then
									s = false
									table.insert(q, v)
									table.insert(p, v)
								end
							end
						end
						o, p = p, o
						table.clear(p)
					until s
					local s: { h.GraphObject } = {}
					for t, u in q do
						u.validity = "invalid"
						if u.timeliness == "eager" then
							table.insert(s, u)
						end
					end
					table.sort(
						s,
						function(t, u)
							return t.createdAt < u.createdAt
						end
					)
					for t, u in s do
						j(u, false)
					end
				end
				return l
			end)()
		end,
		[22] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(22)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m =
					d(f.Types),
					d(f.External),
					d(f.Graph.evaluate),
					d(f.Graph.castToGraph),
					d(f.State.castToState),
					d(f.Utility.nameOf)
				local n = function<T>(n: h.GraphObject, o: h.UsedAs<T> | h.GraphObject): any
					if k(o) then
						local p = o :: h.GraphObject
						j(p, false)
						if table.isfrozen(n.dependencySet) or table.isfrozen(p.dependentSet) then
							i.logError("cannotDepend", nil, m(n, "Dependent"), m(p, "dependency"))
						end
						p.dependentSet[n] = true
						n.dependencySet[p] = true
						if l(p) then
							return (p :: h.StateObject<T>)._EXTREMELY_DANGEROUS_usedAsValue :: T
						else
							return nil
						end
					end
					return o :: T
				end :: (<T>(h.GraphObject, h.UsedAs<T>) -> T) & ((h.GraphObject, h.GraphObject) -> ())
				return n
			end)()
		end,
		[23] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(23)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i = d(f.Types), d(f.External)
				local function j(k: h.GraphObject, l: boolean): boolean
					if k.validity == "busy" then
						return i.logError("infiniteLoop")
					end
					local m, n = k.lastChange == nil, k.validity == "invalid"
					if m or n or l then
						local o = m or l
						if not o then
							for p in k.dependencySet do
								j(p, false)
								if p.lastChange > k.lastChange then
									o = true
									break
								end
							end
						end
						local p = false
						if o then
							for q in k.dependencySet do
								q.dependentSet[k] = nil
								k.dependencySet[q] = nil
							end
							k.validity = "busy"
							p = k:_evaluate() or m
						end
						if p then
							k.lastChange = os.clock()
						end
						k.validity = "valid"
						return p
					else
						return false
					end
				end
				return j
			end)()
		end,
		[25] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(25)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m: { [string]: Types.SpecialKey } =
					d(f.Types),
					d(f.Memory.checkLifetime),
					d(f.Graph.Observer),
					d(f.State.castToState),
					d(f.State.peek),
					{}
				local function n(o: string): h.SpecialKey
					local p = m[o]
					if p == nil then
						p = {
							type = "SpecialKey",
							kind = "Attribute",
							stage = "self",
							apply = function(
								q: h.SpecialKey,
								r: h.Scope<unknown>,
								s: unknown,
								t: Instance
							)
								if k(s) then
									local u = s :: h.StateObject<unknown>
									i.bOutlivesA(
										r,
										t,
										u.scope,
										u.oldestTask,
										i.formatters.boundAttribute,
										o
									)
									j(r, u :: any):onBind(function()
										t:SetAttribute(o, l(u))
									end)
								else
									t:SetAttribute(o, s)
								end
							end,
						}
						m[o] = p
					end
					return p
				end
				return n
			end)()
		end,
		[26] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(26)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j: { [string]: Types.SpecialKey } = d(f.Types), d(f.External), {}
				local function k(l: string): h.SpecialKey
					local m = j[l]
					if m == nil then
						m = {
							type = "SpecialKey",
							kind = "AttributeChange",
							stage = "observer",
							apply = function(
								n: h.SpecialKey,
								o: h.Scope<unknown>,
								p: unknown,
								q: Instance
							)
								if typeof(p) ~= "function" then
									i.logError("invalidAttributeChangeHandler", nil, l)
								end
								local r, s =
									p :: (...unknown) -> ...unknown,
									q:GetAttributeChangedSignal(l)
								table.insert(
									o,
									s:Connect(function()
										r((q :: any):GetAttribute(l))
									end)
								)
							end,
						}
						j[l] = m
					end
					return m
				end
				return k
			end)()
		end,
		[27] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(27)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l: { [string]: Types.SpecialKey } =
					d(f.Types),
					d(f.External),
					d(f.Memory.checkLifetime),
					d(f.State.castToState),
					{}
				local function m(n: string): h.SpecialKey
					local o = l[n]
					if o == nil then
						o = {
							type = "SpecialKey",
							kind = "AttributeOut",
							stage = "observer",
							apply = function(
								p: h.SpecialKey,
								q: h.Scope<unknown>,
								r: unknown,
								s: Instance
							)
								local t = s:GetAttributeChangedSignal(n)
								if not k(r) then
									i.logError("invalidAttributeOutType")
								end
								local u = r :: h.StateObject<unknown>
								if u.kind ~= "Value" then
									i.logError("invalidAttributeOutType")
								end
								local v = u :: h.Value<unknown>
								j.bOutlivesA(
									q,
									s,
									v.scope,
									v.oldestTask,
									j.formatters.attributeOutputsTo,
									n
								)
								v:set((s :: any):GetAttribute(n))
								table.insert(
									q,
									t:Connect(function()
										v:set((s :: any):GetAttribute(n))
									end)
								)
							end,
						}
						l[n] = o
					end
					return o
				end
				return m
			end)()
		end,
		[28] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(28)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h = d(f.Types)
				local function i(j: { h.Child }): h.Child
					return j
				end
				return i
			end)()
		end,
		[29] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(29)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m =
					d(f.Types),
					d(f.External),
					d(f.Graph.Observer),
					d(f.State.peek),
					d(f.State.castToState),
					d(f.Memory.doCleanup)
				type Set<T> = { [T]: unknown }
				local n = false
				return {
					type = "SpecialKey",
					kind = "Children",
					stage = "descendants",
					apply = function(o: h.SpecialKey, p: h.Scope<unknown>, q: unknown, r: Instance)
						local s: Set<Instance>, t: Set<Instance>, v: { [h.StateObject<unknown>]: h.Scope<unknown> }, w: { [h.StateObject<unknown>]: h.Scope<unknown> } =
							{},
							{},
							{},
							{}
						local function x()
							t, s = s, t
							w, v = v, w
							local function y(z: unknown, A: string?)
								local B = typeof(z)
								if B == "Instance" then
									local C = z :: Instance
									s[C] = true
									if t[C] == nil then
										C.Parent = r
									else
										t[C] = nil
									end
									if n and A ~= nil then
										C.Name = A
									end
								elseif l(z) then
									local C = z :: h.StateObject<unknown>
									local D = k(C)
									if D ~= nil then
										y(D, A)
									end
									local E = w[C]
									if E == nil then
										E = {}
										j(E, C):onChange(x)
									else
										w[C] = nil
									end
									v[C] = E
								elseif B == "table" then
									local C = z :: { [unknown]: unknown }
									for D, E in pairs(C) do
										local F, G: string? = (typeof(D))
										if F == "string" then
											local H = D :: string
											G = H
										elseif F == "number" and A ~= nil then
											local H = D :: number
											G = A .. "_" .. H
										end
										y(E, G)
									end
								else
									i.logWarn("unrecognisedChildType", B)
								end
							end
							if q ~= nil then
								y(q)
							end
							for z in pairs(t) do
								z.Parent = nil
							end
							table.clear(t)
							for z, A in pairs(w) do
								m(A)
							end
							table.clear(w)
						end
						table.insert(
							p,
							function()
								q = nil
								x()
							end
						)
						x()
					end,
				} :: h.SpecialKey
			end)()
		end,
		[30] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(30)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i = d(f.Types), d(f.Instances.applyInstanceProps)
				local function j(k: h.Scope<unknown>, l: Instance)
					return function(m: h.PropertyTable): Instance
						table.insert(k, l)
						i(k, m, l)
						return l
					end
				end
				return j
			end)()
		end,
		[31] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(31)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k =
					d(f.Types),
					d(f.External),
					d(f.Instances.defaultProps),
					d(f.Instances.applyInstanceProps)
				type Component = (h.PropertyTable) -> Instance
				local function l(m: h.Scope<unknown>, n: string)
					return function(o: h.PropertyTable): Instance
						local p, q = pcall(Instance.new, n)
						if not p then
							i.logError("cannotCreateClass", nil, n)
						end
						local r = j[n]
						if r ~= nil then
							for s, t in pairs(r) do
								(q :: any)[s] = t
							end
						end
						table.insert(m, q)
						k(m, o, q)
						return q
					end
				end
				return l
			end)()
		end,
		[32] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(32)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j: { [string]: Types.SpecialKey } = d(f.Types), d(f.External), {}
				local function k(l: string): h.SpecialKey
					local m = j[l]
					if m == nil then
						m = {
							type = "SpecialKey",
							kind = "OnChange",
							stage = "observer",
							apply = function(
								n: h.SpecialKey,
								o: h.Scope<unknown>,
								p: unknown,
								q: Instance
							)
								local r, s = pcall(q.GetPropertyChangedSignal, q, l)
								if not r then
									i.logError("cannotConnectChange", nil, q.ClassName, l)
								elseif typeof(p) ~= "function" then
									i.logError("invalidChangeHandler", nil, l)
								else
									local t = p :: (...unknown) -> ...unknown
									table.insert(
										o,
										s:Connect(function()
											t((q :: any)[l])
										end)
									)
								end
							end,
						}
						j[l] = m
					end
					return m
				end
				return k
			end)()
		end,
		[33] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(33)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j: { [string]: Types.SpecialKey } = d(f.Types), d(f.External), {}
				local function k(l: Instance, m: string)
					return (l :: any)[m]
				end
				local function l(m: string): h.SpecialKey
					local n = j[m]
					if n == nil then
						n = {
							type = "SpecialKey",
							kind = "OnEvent",
							stage = "observer",
							apply = function(
								o: h.SpecialKey,
								p: h.Scope<unknown>,
								q: unknown,
								r: Instance
							)
								local s, t = pcall(k, r, m)
								if not s or typeof(t) ~= "RBXScriptSignal" then
									i.logError("cannotConnectEvent", nil, r.ClassName, m)
								elseif typeof(q) ~= "function" then
									i.logError("invalidEventHandler", nil, m)
								else
									table.insert(p, t:Connect(q :: any))
								end
							end,
						}
						j[m] = n
					end
					return n
				end
				return l
			end)()
		end,
		[34] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(34)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l: { [string]: Types.SpecialKey } =
					d(f.Types),
					d(f.External),
					d(f.Memory.checkLifetime),
					d(f.State.castToState),
					{}
				local function m(n: string): h.SpecialKey
					local o = l[n]
					if o == nil then
						o = {
							type = "SpecialKey",
							kind = "Out",
							stage = "observer",
							apply = function(
								p: h.SpecialKey,
								q: h.Scope<unknown>,
								r: unknown,
								s: Instance
							)
								local t, v = pcall(s.GetPropertyChangedSignal, s, n)
								if not t then
									i.logError("invalidOutProperty", nil, s.ClassName, n)
								end
								if not k(r) then
									i.logError("invalidOutType")
								end
								local w = r :: h.StateObject<unknown>
								if w.kind ~= "Value" then
									i.logError("invalidOutType")
								end
								local x = w :: h.Value<unknown>
								j.bOutlivesA(
									q,
									s,
									x.scope,
									x.oldestTask,
									j.formatters.propertyOutputsTo,
									n
								)
								x:set((s :: any)[n])
								table.insert(
									q,
									v:Connect(function()
										x:set((s :: any)[n])
									end)
								)
							end,
						}
						l[n] = o
					end
					return o
				end
				return m
			end)()
		end,
		[35] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(35)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m: { [string]: Types.SpecialKey } =
					d(f.Types),
					d(f.Memory.checkLifetime),
					d(f.Graph.Observer),
					d(f.State.castToState),
					d(f.State.peek),
					{}
				local function n(o: string): h.SpecialKey
					local p = m[o]
					if p == nil then
						p = {
							type = "SpecialKey",
							kind = "Tag",
							stage = "self",
							apply = function(
								q: h.SpecialKey,
								r: h.Scope<unknown>,
								s: unknown,
								t: Instance
							)
								if k(s) then
									local v = s :: h.StateObject<unknown>
									i.bOutlivesA(
										r,
										t,
										v.scope,
										v.oldestTask,
										i.formatters.boundTag,
										o
									)
									j(r, v :: any):onBind(function()
										if l(v) == true then
											t:AddTag(o)
										elseif t:HasTag(o) then
											t:RemoveTag(o)
										end
									end)
								else
									if s == true then
										t:AddTag(o)
									end
								end
							end,
						}
						m[o] = p
					end
					return p
				end
				return n
			end)()
		end,
		[36] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(36)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m, n, o =
					d(f.Types),
					d(f.External),
					d(f.Logging.parseError),
					d(f.Memory.checkLifetime),
					d(f.Graph.Observer),
					d(f.State.castToState),
					d(f.State.peek),
					d(f.Utility.xtypeof)
				local function p(q: Instance, r: string, s: unknown)
					(q :: any)[r] = s
				end
				local function q(r: Instance, s: string)
					(r :: any)[s] = (r :: any)[s]
				end
				local function r(s: Instance, t: string, v: unknown)
					local x, y = xpcall(p :: any, j, s, t, v)
					if not x then
						if not pcall(q, s, t) then
							i.logErrorNonFatal("cannotAssignProperty", nil, s.ClassName, t)
						else
							local z, A = typeof(v), typeof((s :: any)[t])
							if z == A then
								i.logErrorNonFatal("propertySetError", y)
							else
								i.logErrorNonFatal("invalidPropertyType", nil, s.ClassName, t, A, z)
							end
						end
					end
				end
				local function s(t: h.Scope<unknown>, v: Instance, x: string, y: h.UsedAs<unknown>)
					if m(y) then
						local z = y :: h.StateObject<unknown>
						k.bOutlivesA(t, v, z.scope, z.oldestTask, k.formatters.boundProperty, x)
						l(t, z :: any):onBind(function()
							r(v, x, n(z))
						end)
					else
						r(v, x, y)
					end
				end
				local function t(v: h.Scope<unknown>, x: h.PropertyTable, y: Instance)
					local z = {
						self = {} :: { [h.SpecialKey]: unknown },
						descendants = {} :: { [h.SpecialKey]: unknown },
						ancestor = {} :: { [h.SpecialKey]: unknown },
						observer = {} :: { [h.SpecialKey]: unknown },
					}
					for A, B in pairs(x) do
						local C = o(A)
						if C == "string" then
							if A ~= "Parent" then
								s(v, y, A :: string, B)
							end
						elseif C == "SpecialKey" then
							local D = (A :: h.SpecialKey).stage
							local E = z[D]
							if E == nil then
								i.logError("unrecognisedPropertyStage", nil, D)
							else
								E[A] = B
							end
						else
							i.logError("unrecognisedPropertyKey", nil, C)
						end
					end
					for A, B in pairs(z.self) do
						A:apply(v, B, y)
					end
					for A, B in pairs(z.descendants) do
						A:apply(v, B, y)
					end
					if x.Parent ~= nil then
						s(v, y, "Parent", x.Parent)
					end
					for A, B in pairs(z.ancestor) do
						A:apply(v, B, y)
					end
					for A, B in pairs(z.observer) do
						A:apply(v, B, y)
					end
				end
				return t
			end)()
		end,
		[37] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(37)
			local e
			return (function(...)
				local f
				return {
					ScreenGui = {
						ResetOnSpawn = false,
						ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					},
					BillboardGui = {
						ResetOnSpawn = false,
						ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
						Active = true,
					},
					SurfaceGui = {
						ResetOnSpawn = false,
						ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
						SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
						PixelsPerStud = 50,
					},
					Frame = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
					},
					ScrollingFrame = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
						ScrollBarImageColor3 = Color3.new(0, 0, 0),
					},
					TextLabel = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
						Font = Enum.Font.SourceSans,
						Text = "",
						TextColor3 = Color3.new(0, 0, 0),
						TextSize = 14,
					},
					TextButton = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
						AutoButtonColor = false,
						Font = Enum.Font.SourceSans,
						Text = "",
						TextColor3 = Color3.new(0, 0, 0),
						TextSize = 14,
					},
					TextBox = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
						ClearTextOnFocus = false,
						Font = Enum.Font.SourceSans,
						Text = "",
						TextColor3 = Color3.new(0, 0, 0),
						TextSize = 14,
					},
					ImageLabel = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
					},
					ImageButton = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
						AutoButtonColor = false,
					},
					ViewportFrame = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
					},
					VideoFrame = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
					},
					CanvasGroup = {
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
					},
					SpawnLocation = { Duration = 0 },
					BoxHandleAdornment = { ZIndex = 0 },
					ConeHandleAdornment = { ZIndex = 0 },
					CylinderHandleAdornment = { ZIndex = 0 },
					ImageHandleAdornment = { ZIndex = 0 },
					LineHandleAdornment = { ZIndex = 0 },
					SphereHandleAdornment = { ZIndex = 0 },
					WireframeHandleAdornment = { ZIndex = 0 },
					Part = {
						Anchored = true,
						Size = Vector3.one,
						FrontSurface = Enum.SurfaceType.Smooth,
						BackSurface = Enum.SurfaceType.Smooth,
						LeftSurface = Enum.SurfaceType.Smooth,
						RightSurface = Enum.SurfaceType.Smooth,
						TopSurface = Enum.SurfaceType.Smooth,
						BottomSurface = Enum.SurfaceType.Smooth,
					},
					TrussPart = {
						Anchored = true,
						Size = Vector3.one * 2,
						FrontSurface = Enum.SurfaceType.Smooth,
						BackSurface = Enum.SurfaceType.Smooth,
						LeftSurface = Enum.SurfaceType.Smooth,
						RightSurface = Enum.SurfaceType.Smooth,
						TopSurface = Enum.SurfaceType.Smooth,
						BottomSurface = Enum.SurfaceType.Smooth,
					},
					MeshPart = {
						Anchored = true,
						Size = Vector3.one,
						FrontSurface = Enum.SurfaceType.Smooth,
						BackSurface = Enum.SurfaceType.Smooth,
						LeftSurface = Enum.SurfaceType.Smooth,
						RightSurface = Enum.SurfaceType.Smooth,
						TopSurface = Enum.SurfaceType.Smooth,
						BottomSurface = Enum.SurfaceType.Smooth,
					},
					CornerWedgePart = {
						Anchored = true,
						Size = Vector3.one,
						FrontSurface = Enum.SurfaceType.Smooth,
						BackSurface = Enum.SurfaceType.Smooth,
						LeftSurface = Enum.SurfaceType.Smooth,
						RightSurface = Enum.SurfaceType.Smooth,
						TopSurface = Enum.SurfaceType.Smooth,
						BottomSurface = Enum.SurfaceType.Smooth,
					},
					VehicleSeat = {
						Anchored = true,
						Size = Vector3.one,
						FrontSurface = Enum.SurfaceType.Smooth,
						BackSurface = Enum.SurfaceType.Smooth,
						LeftSurface = Enum.SurfaceType.Smooth,
						RightSurface = Enum.SurfaceType.Smooth,
						TopSurface = Enum.SurfaceType.Smooth,
						BottomSurface = Enum.SurfaceType.Smooth,
					},
				}
			end)()
		end,
		[39] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(39)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j =
					d(f.Types),
					d(f.Logging.messages),
					"https://elttob.uk/Fusion/0.3/api-reference/general/errors/#"
				local function k(
					l: h.ExternalProvider?,
					m: string,
					n: h.Error | string | nil,
					...: unknown
				): string
					local o, p: h.Error?, q: string?, r =
						m,
						if typeof(n) == "table" then n else nil,
						if typeof(n) == "table" then n.trace else n,
						i[m]
					if r == nil then
						m = "unknownMessage"
						r = i[m]
					end
					r = r:format(...)
					if p ~= nil then
						r = r:gsub("ERROR_MESSAGE", p.message)
						if p.context ~= nil then
							r ..= ` ({p.context})`
						end
					else
						r = r:gsub("ERROR_MESSAGE", o)
					end
					r = `[Fusion] {r} \nID: {m}`
					if l ~= nil and l.policies.allowWebLinks then
						r ..= `\nLearn more: {j}{m:lower()}`
					end
					if q ~= nil then
						r ..= ` \n---- Stack trace ----\n{q}`
					end
					return r:gsub("\n", "\n    ")
				end
				return k
			end)()
		end,
		[40] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(40)
			local e
			return (function(...)
				local f
				return {
					callbackError = "Error in callback:\nERROR_MESSAGE",
					cannotAssignProperty = "The class type '%s' has no assignable property '%s'.",
					cannotConnectChange = "The %s class doesn't have a property called '%s'.",
					cannotConnectEvent = "The %s class doesn't have an event called '%s'.",
					cannotCreateClass = "Can't create a new instance of class '%s'.",
					cannotDepend = "%s can't depend on %s.",
					destroyedTwice = [[`doCleanup()` was given something that it is already cleaning up. Unclear how to proceed.]],
					forKeyCollision = [[The key '%s' was returned multiple times simultaneously, which is not allowed in `For` objects.]],
					infiniteLoop = [[Detected an infinite loop. Consider adding an explicit breakpoint to your code to prevent a cyclic dependency.]],
					invalidAttributeChangeHandler = [[The change handler for the '%s' attribute must be a function.]],
					invalidAttributeOutType = "[AttributeOut] properties must be given Value objects.",
					invalidChangeHandler = [[The change handler for the '%s' property must be a function.]],
					invalidEventHandler = "The handler for the '%s' event must be a function.",
					invalidOutProperty = "The %s class doesn't have a property called '%s'.",
					invalidOutType = "[Out] properties must be given Value objects.",
					invalidPropertyType = "'%s.%s' expected a '%s' type, but got a '%s' type.",
					invalidSpringDamping = [[The damping ratio for a spring must be >= 0. (damping was %.2f)]],
					invalidSpringSpeed = "The speed of a spring must be >= 0. (speed was %.2f)",
					mergeConflict = "Multiple definitions for '%s' found while merging.",
					mistypedSpringDamping = "The damping ratio for a spring must be a number. (got a %s)",
					mistypedSpringSpeed = "The speed of a spring must be a number. (got a %s)",
					mistypedTweenInfo = "The tween info of a tween must be a TweenInfo. (got a %s)",
					noTaskScheduler = "Fusion is not connected to an external task scheduler.",
					poisonedScope = "Attempted to use a scope after it's been destroyed; %s",
					propertySetError = "Error setting property:\nERROR_MESSAGE",
					springNanGoal = [[A spring was given a NaN goal, so some simulation has been skipped. Ensure no springs have NaN goals.]],
					springNanMotion = [[A spring encountered NaN during motion, so has snapped to the goal position. Ensure no springs have NaN positions or velocities.]],
					springTypeMismatch = "The type '%s' doesn't match the spring's type '%s'.",
					tweenNanGoal = [[A tween was given a NaN goal, so some animation has been skipped. Ensure no tweens have NaN goals.]],
					tweenNanMotion = [[A tween encountered NaN during motion, so has snapped to the goal. Ensure no tweens have NaN in their tween infos.]],
					unknownMessage = "Unknown error:\nERROR_MESSAGE",
					unrecognisedChildType = "'%s' type children aren't accepted by `[Children]`.",
					unrecognisedPropertyKey = "'%s' keys aren't accepted in property tables.",
					unrecognisedPropertyStage = [['%s' isn't a valid stage for a special key to be applied at.]],
					useAfterDestroy = [[%s is no longer valid - it was destroyed before %s. See discussion #292 on GitHub for advice.]],
				}
			end)()
		end,
		[41] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(41)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h = d(f.Types)
				local function i(j: string): h.Error
					return {
						type = "Error",
						raw = j,
						message = j:gsub("^.+:%d+:%s*", ""),
						trace = debug.traceback(nil, 2),
					}
				end
				return i
			end)()
		end,
		[43] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(43)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k = d(f.Types), d(f.External), d(f.Utility.nameOf), {}
				k.formatters = {}
				function k.formatters.useFunction(l: unknown, m: unknown): (string, string)
					local n, o = j(l, "object"), j(m, "object")
					return `The use()-d {o}`, `the {n}`
				end
				function k.formatters.boundProperty(l: Instance, m: unknown, n: string): (string, string)
					local o, p = l.Name, j(m, "value")
					return `The {p} (bound to the {n} property)`, `the {o} instance`
				end
				function k.formatters.boundAttribute(l: Instance, m: unknown, n: string): (string, string)
					local o, p = l.Name, j(m, "value")
					return `The {p} (bound to the {n} attribute)`, `the {o} instance`
				end
				function k.formatters.boundTag(l: Instance, m: unknown, n: string): (string, string)
					local o, p = l.Name, j(m, "value")
					return `The {p} (bound to the {n} CollectionService tag)`, `the {o} instance`
				end
				function k.formatters.propertyOutputsTo(l: Instance, m: unknown, n: string): (string, string)
					local o, p = l.Name, j(m, "object")
					return `The {p} (which the {n} property outputs to)`, `the {o} instance`
				end
				function k.formatters.attributeOutputsTo(l: Instance, m: unknown, n: string): (string, string)
					local o, p = l.Name, j(m, "object")
					return `The {p} (which the {n} attribute outputs to)`, `the {o} instance`
				end
				function k.formatters.refOutputsTo(l: Instance, m: unknown): (string, string)
					local n, o = l.Name, j(m, "object")
					return `The {o} (which the Ref key outputs to)`, `the {n} instance`
				end
				function k.formatters.animationGoal(l: unknown, m: unknown): (string, string)
					local n, o = j(l, "object"), j(m, "object")
					return `The goal {o}`, `the {n} that is following it`
				end
				function k.formatters.parameter(l: unknown, m: unknown, n: string | false): (string, string)
					local o, p = j(l, "object"), j(m, "object")
					if n == false then
						return `The {p} parameter`, `the {o} that it was used for`
					else
						return
							`The {p} representing the {n} parameter`,
							`the {o} that it was used for`
					end
				end
				function k.formatters.observer(l: unknown, m: unknown): (string, string)
					local n, o = j(l, "object"), j(m, "object")
					return `The watched {o}`, `the {n} that's observing it for changes`
				end
				function k.bOutlivesA<A, B, Args...>(
					l: h.Scope<unknown>,
					m: A,
					n: h.Scope<unknown>?,
					o: B,
					p: (a: A, b: B, Args...) -> (string, string),
					...: Args...
				)
					if n == nil then
						i.logError("useAfterDestroy", nil, p(m, o, ...))
					end
				end
				return k
			end)()
		end,
		[44] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(44)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j = d(f.Types), d(f.ExternalDebug), d(f.Memory.deriveScopeImpl)
				local function k(...)
					local l = j(...)
					i.trackScope(l)
					return l
				end
				return k :: h.DeriveScopeConstructor
			end)()
		end,
		[45] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(45)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i = d(f.Types), d(f.Utility.merge)
				local function j<T>(
					k: h.Scope<T>,
					l: { [unknown]: unknown }?,
					...: { [unknown]: unknown }
				): any
					local m = getmetatable(k)
					if l ~= nil then
						m = table.clone(m)
						m.__index = i(true, {}, m.__index, i(false, {}, l, ...))
					end
					return setmetatable({}, m)
				end
				return (j :: any) :: h.DeriveScopeConstructor
			end)()
		end,
		[46] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(46)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k: { [Types.Task]: true } =
					d(f.Types),
					d(f.External),
					d(f.ExternalDebug),
					{}
				local function l(m: h.Task): ()
					if k[m] then
						return i.logError("destroyedTwice")
					end
					k[m] = true
					local success, message = pcall(function()
						if typeof(m) == "Instance" then
							m:Destroy()
						elseif typeof(m) == "RBXScriptConnection" then
							m:Disconnect()
						elseif typeof(m) == "function" then
							m()
						elseif typeof(m) == "table" then
							local n = (m :: any) :: {
								Destroy: (...unknown) -> unknown?,
								destroy: (...unknown) -> unknown?,
							}
							if typeof(n.destroy) == "function" then
								local o = (n :: any) :: { destroy: (...unknown) -> ...unknown }
								o:destroy()
							elseif typeof(n.Destroy) == "function" then
								local o = (n :: any) :: { Destroy: (...unknown) -> ...unknown }
								o:Destroy()
							elseif n[1] ~= nil then
								local o = n :: { h.Task }
								for p = #o, 1, -1 do
									l(o[p])
									o[p] = nil
								end
								j.untrackScope(o)
							end
						end
					end)
					k[m] = nil
					if not success then
						error(message, 0)
					end
				end
				return l
			end)()
		end,
		[47] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(47)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j = d(f.Types), d(f.ExternalDebug), d(f.Memory.deriveScopeImpl)
				local function k<T>(l: h.Scope<T>, ...: { [unknown]: unknown }): any
					local m = j(l, ...)
					table.insert(l, m)
					table.insert(
						m,
						function()
							local n = table.find(l, m)
							if n ~= nil then
								table.remove(l, n)
							end
						end
					)
					i.trackScope(m)
					return m
				end
				return (k :: any) :: h.DeriveScopeConstructor
			end)()
		end,
		[48] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(48)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h = d(f.Types)
				local function i<Tasks...>(j: h.Scope<unknown>, ...: Tasks...): Tasks...
					for k = 1, select("#", ...) do
						table.insert(j, select(k, ...))
					end
					return ...
				end
				return i
			end)()
		end,
		[49] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(49)
			local e
			return (function(...)
				local f
				local function g(h: unknown): boolean
					return typeof(h) == "Instance"
				end
				return g
			end)()
		end,
		[50] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(50)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j = d(f.Types), d(f.ExternalDebug), d(f.Utility.merge)
				local function k(...: { [unknown]: unknown }): any
					local l = { __index = j(false, {}, ...) }
					local m = setmetatable({}, l) :: any
					i.trackScope(m)
					return m
				end
				return (k :: any) :: h.ScopedConstructor
			end)()
		end,
		[51] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(51)
			local e
			return (function(...)
				local f, g, h = services.RunService, services.HttpService, c.Parent
				local i, j = d(h.External), {}
				j.policies = { allowWebLinks = f:IsStudio() }
				function j.doTaskImmediate(k: () -> ())
					task.spawn(k)
				end
				function j.doTaskDeferred(k: () -> ())
					task.defer(k)
				end
				function j.logErrorNonFatal(k: string)
					task.spawn(error, k, 0)
				end
				j.logWarn = warn
				local function k()
					i.performUpdateStep(os.clock())
				end
				local l = nil :: (() -> ())?
				function j.startScheduler()
					if l ~= nil then
						return
					end
					if f:IsClient() then
						local m = "FusionUpdateStep_" .. g:GenerateGUID()
						f:BindToRenderStep(m, Enum.RenderPriority.First.Value, k)
						l = function()
							f:UnbindFromRenderStep(m)
						end
					else
						local m = f.Heartbeat:Connect(k)
						l = function()
							m:Disconnect()
						end
					end
				end
				function j.stopScheduler()
					if l ~= nil then
						l()
						l = nil
					end
				end
				return j
			end)()
		end,
		[53] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(53)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m, n, o, p, q, r =
					d(f.Types),
					d(f.External),
					d(f.Logging.parseError),
					d(f.Utility.isSimilar),
					d(f.Graph.depend),
					d(f.State.castToState),
					d(f.State.peek),
					d(f.Memory.doCleanup),
					d(f.Memory.deriveScope),
					d(f.Memory.checkLifetime),
					d(f.Utility.nicknames)
				type Self<T, S> = h.Computed<T> & {
					_innerScope: h.Scope<S>?,
					_processor: (h.Use, h.Scope<S>) -> T,
				}
				local s = {}
				s.type = "State"
				s.kind = "Computed"
				s.timeliness = "lazy"
				local t = table.freeze({
					__index = s,
				})
				local function v<T, S>(x: S & h.Scope<unknown>, y: (h.Use, S) -> T): h.Computed<T>
					local z = os.clock()
					local A: Self<T, S> = setmetatable(
						{
							createdAt = z,
							dependencySet = {},
							dependentSet = {},
							lastChange = nil,
							scope = x,
							validity = "invalid",
							_EXTREMELY_DANGEROUS_usedAsValue = nil,
							_innerScope = nil,
							_processor = y,
						},
						t
					) :: any
					local B = function()
						A.scope = nil
						for B in pairs(A.dependencySet) do
							B.dependentSet[A] = nil
						end
						if A._innerScope ~= nil then
							o(A._innerScope)
							A._innerScope = nil
						end
					end
					A.oldestTask = B
					r[A.oldestTask] = "Computed"
					table.insert(x, B)
					return A
				end
				function s._evaluate<T, S>(x: Self<T, S>): boolean
					if x.scope == nil then
						return false
					end
					local y = x.scope :: S & h.Scope<unknown>
					local z = p(y)
					local function A<T>(B: h.UsedAs<T>): T
						local C = m(B)
						if C ~= nil then
							q.bOutlivesA(
								y,
								x.oldestTask,
								C.scope,
								C.oldestTask,
								q.formatters.useFunction
							)
							l(x, C)
						end
						return n(B)
					end
					local B, C = xpcall(x._processor, j, A, z)
					if B then
						local D = k(x._EXTREMELY_DANGEROUS_usedAsValue, C)
						if x._innerScope ~= nil then
							o(x._innerScope)
							x._innerScope = nil
						end
						x._innerScope = z
						x._EXTREMELY_DANGEROUS_usedAsValue = C
						return not D
					else
						local D = (C :: any) :: h.Error
						o(z)
						i.logErrorNonFatal("callbackError", D)
						return false
					end
				end
				table.freeze(s)
				return v :: h.ComputedConstructor
			end)()
		end,
		[54] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(54)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m, n =
					d(f.Types),
					d(f.Graph.depend),
					d(f.State.peek),
					d(f.State.castToState),
					d(f.State.For.ForTypes),
					d(f.Utility.nicknames),
					d(f.State.For.Disassembly)
				type Self<S, KI, KO, VI, VO> = h.For<KO, VO> & { _disassembly: l.Disassembly<S, KI, KO, VI, VO> }
				local o = {}
				o.type = "State"
				o.kind = "For"
				o.timeliness = "lazy"
				local p = table.freeze({ __index = o })
				local function q<S, KI, KO, VI, VO>(
					r: h.Scope<S>,
					s: h.UsedAs<{ [KI]: VI }>,
					t: (h.Scope<S>, initialKey: KI, initialValue: VI) -> l.SubObject<S, KI, KO, VI, VO>
				): h.For<KO, VO>
					local v = os.clock()
					local x: Self<S, KI, KO, VI, VO> = setmetatable(
						{
							createdAt = v,
							dependencySet = {},
							dependentSet = {},
							scope = r,
							validity = "invalid",
							_EXTREMELY_DANGEROUS_usedAsValue = {},
							_disassembly = n(r, s, t),
						},
						p
					) :: any
					local y = function()
						x.scope = nil
						for y in pairs(x.dependencySet) do
							y.dependentSet[x] = nil
						end
					end
					x.oldestTask = y
					m[x.oldestTask] = "For"
					table.insert(r, y)
					return x
				end
				function o._evaluate<S, KI, KO, VI, VO>(r: Self<S, KI, KO, VI, VO>): boolean
					if r.scope == nil then
						return false
					end
					local s = r.scope :: S & h.Scope<unknown>
					i(r, r._disassembly)
					table.clear(r._EXTREMELY_DANGEROUS_usedAsValue)
					r._disassembly:populate(
						function<T>(t: h.UsedAs<T>): T
							local v = k(t)
							if v ~= nil then
								i(r, v)
							end
							return j(t)
						end,
						r._EXTREMELY_DANGEROUS_usedAsValue
					)
					return true
				end
				table.freeze(o)
				return q
			end)()
		end,
		[55] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(55)
			local e
			return (function(...)
				local f, g = c.Parent.Parent.Parent
				local h, i, j, k, l, m, n, o, p, q =
					d(f.Types),
					d(f.External),
					d(f.Graph.depend),
					d(f.State.peek),
					d(f.State.castToState),
					d(f.State.For.ForTypes),
					d(f.Memory.doCleanup),
					d(f.Memory.deriveScope),
					d(f.Utility.nameOf),
					d(f.Utility.nicknames)
				type Self<S, KI, KO, VI, VO> = m.Disassembly<S, KI, KO, VI, KO> & {
					scope: (S & h.Scope<unknown>)?,
					_inputTable: h.UsedAs<{ [KI]: VI }>,
					_constructor: (h.Scope<S>, initialKey: KI, initialValue: VI) -> m.SubObject<S, KI, KO, VI, VO>,
					_subObjects: { [m.SubObject<S, KI, KO, VI, VO>]: true },
				}
				local r = {}
				r.type = "Graph"
				r.kind = "For.Disassembly"
				r.timeliness = "lazy"
				local s = table.freeze({ __index = r })
				local function t<S, KI, KO, VI, VO>(
					v: S & h.Scope<unknown>,
					x: h.UsedAs<{ [KI]: VI }>,
					y: (h.Scope<S>, initialKey: KI, initialValue: VI) -> m.SubObject<S, KI, KO, VI, VO>
				): m.Disassembly<S, KI, KO, VI, KO>
					local z = os.clock()
					local A = setmetatable(
						{
							createdAt = z,
							dependencySet = {},
							dependentSet = {},
							scope = v,
							validity = "invalid",
							_inputTable = x,
							_constructor = y,
							_subObjects = {},
						},
						s
					) :: any
					local B = function()
						A.scope = nil
						for B in pairs(A.dependencySet) do
							B.dependentSet[A] = nil
						end
						for B in A._subObjects do
							if B.maybeScope ~= nil then
								n(B.maybeScope)
								B.maybeScope = nil
							end
						end
					end
					A.oldestTask = B
					q[A.oldestTask] = "For (internal disassembler)"
					table.insert(v, B)
					return A
				end
				function r.populate<S, KI, KO, VI, VO>(
					v: Self<S, KI, KO, VI, VO>,
					x: h.Use,
					y: { [KO]: VO }
				): ()
					local z, A, B = math.huge, -math.huge, false
					for C in v._subObjects do
						local D, E = C:useOutputPair(x)
						if D == nil or E == nil then
							B = true
							continue
						elseif y[D] ~= nil then
							i.logErrorNonFatal("forKeyCollision", nil, tostring(D))
							continue
						end
						y[D] = E
						if typeof(D) == "number" then
							z = math.min(z, D)
							A = math.max(A, D)
						end
					end
					if B and A > z then
						local C: { [number]: VO }, D = y :: any, z
						for E = z, A do
							local F = C[E]
							if F == nil then
								continue
							end
							C[E] = nil
							C[D] = F
							D += 1
						end
					end
				end
				function r._evaluate<S, KI, KO, VI, VO>(v: Self<S, KI, KO, VI, VO>): boolean
					local x, y = v.scope :: S & h.Scope<unknown>, l(v._inputTable)
					if y ~= nil then
						if y.scope == nil then
							i.logError(
								"useAfterDestroy",
								nil,
								`The input {p(y, "table")}`,
								`the For object that is watching it`
							)
						end
						j(v, y)
					end
					local z = {} :: { [KI]: VI }
					for A, B in k(v._inputTable) do
						z[A] = B
					end
					local A = {} :: typeof(v._subObjects)
					for B in v._subObjects do
						local C, D, E, F: KI = false, B.inputKey, B.inputValue
						if not B.roamKeys and z[D] ~= nil then
							C = true
							F = D
						else
							for G, H in z do
								C = true
								F = G
								if B.roamValues then
									break
								end
								if H == E then
									break
								end
							end
						end
						if C then
							local G = z[F]
							A[B] = true
							if F ~= D then
								B.inputKey = F
								B:invalidateInputKey()
							end
							if G ~= E then
								B.inputValue = G
								B:invalidateInputValue()
							end
							z[F] = nil
						else
							if B.maybeScope ~= nil then
								n(B.maybeScope)
								B.maybeScope = nil
							end
						end
					end
					for B, C in z do
						local D = v._constructor(o(x), B, C)
						A[D] = true
					end
					v._subObjects = A
					return true
				end
				table.freeze(r)
				return t
			end)()
		end,
		[56] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(56)
			local e
			return (function(...)
				local f, g = c.Parent.Parent.Parent
				local h = d(f.Types)
				export type SubObject<S, KI, KO, VI, VO> = {
					maybeScope: h.Scope<S>?,
					inputKey: KI,
					inputValue: VI,
					roamKeys: boolean,
					roamValues: boolean,
					invalidateInputKey: (SubObject<S, KI, KO, VI, VO>) -> (),
					invalidateInputValue: (SubObject<S, KI, KO, VI, VO>) -> (),
					useOutputPair: (SubObject<S, KI, KO, VI, VO>, h.Use) -> (KO?, VO?),
				}
				export type Disassembly<S, KI, KO, VI, VO> = h.GraphObject & {
					populate: (Disassembly<S, KI, KO, VI, VO>, h.Use, output: { [KO]: VO }) -> (),
				}
				return nil
			end)()
		end,
		[57] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(57)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m, n, o, p =
					d(f.Types),
					d(f.External),
					d(f.Memory.doCleanup),
					d(f.State.For),
					d(f.State.Value),
					d(f.State.Computed),
					d(f.State.For.ForTypes),
					d(f.Logging.parseError),
					{
						__index = {
							roamKeys = false,
							roamValues = true,
							invalidateInputKey = function(h): ()
								h._inputKeyState:set(h.inputKey)
							end,
							invalidateInputValue = function(h): ()
							end,
							useOutputPair = function(h, i)
								return i(h._outputKeyState), h.inputValue
							end,
						},
					}
				local function q<KI, KO, V, S>(
					r: h.Scope<S>,
					s: KI,
					t: V,
					v: (h.Use, h.Scope<S>, KI) -> KO
				): n.SubObject<S, KI, KO, V, V>
					local x = {}
					x.maybeScope = r
					x.inputKey = s
					x.inputValue = t
					x._inputKeyState = l(r, s)
					x._processor = v
					x._outputKeyState = m(
						r,
						function(y, z): KO?
							local A = y(x._inputKeyState)
							local B, C = xpcall(x._processor, o, y, z, A)
							if B then
								return C
							else
								local D: h.Error = C :: any
								D.context = `while processing key {tostring(A)}`
								i.logErrorNonFatal("callbackError", D)
								j(z)
								table.clear(z)
								return nil
							end
						end
					)
					return setmetatable(x, p) :: any
				end
				local function r<KI, KO, V, S>(
					s: h.Scope<S>,
					t: h.UsedAs<{ [KI]: V }>,
					v: (h.Use, h.Scope<S>, KI) -> KO
				): h.For<KO, V>
					return k(
						s,
						t,
						function(x, y, z)
							return q(x, y, z, v)
						end
					)
				end
				return r :: h.ForKeysConstructor
			end)()
		end,
		[58] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(58)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m, n, o, p =
					d(f.Types),
					d(f.External),
					d(f.State.For),
					d(f.State.Value),
					d(f.State.Computed),
					d(f.State.For.ForTypes),
					d(f.Logging.parseError),
					d(f.Memory.doCleanup),
					{
						__index = {
							roamKeys = false,
							roamValues = false,
							invalidateInputKey = function(h): ()
								h._inputKeyState:set(h.inputKey)
							end,
							invalidateInputValue = function(h): ()
								h._inputValueState:set(h.inputValue)
							end,
							useOutputPair = function(h, i)
								local j = i(h._outputPairState)
								return j.key, j.value
							end,
						},
					}
				local function q<KI, KO, VI, VO, S>(
					r: h.Scope<S>,
					s: KI,
					t: VI,
					v: (h.Use, h.Scope<S>, KI, VI) -> (KO, VO)
				): m.SubObject<S, KI, KO, VI, VO>
					local x = {}
					x.maybeScope = r
					x.inputKey = s
					x.inputValue = t
					x._inputKeyState = k(r, s)
					x._inputValueState = k(r, t)
					x._processor = v
					x._outputPairState = l(
						r,
						function(y, z): { key: KO?, value: VO? }
							local A, B = y(x._inputKeyState), y(x._inputValueState)
							local C, D, E = xpcall(x._processor, n, y, z, A, B)
							if C then
								return { key = D, value = E }
							else
								local F: h.Error = D :: any
								F.context = `while processing key {tostring(B)} and value {tostring(B)}`
								i.logErrorNonFatal("callbackError", F)
								o(z)
								table.clear(z)
								return { key = nil, value = nil }
							end
						end
					)
					return setmetatable(x, p) :: any
				end
				local function r<KI, KO, VI, VO, S>(
					s: h.Scope<S>,
					t: h.UsedAs<{ [KI]: VI }>,
					v: (h.Use, h.Scope<S>, KI, VI) -> (KO, VO)
				): h.For<KO, VO>
					return j(
						s,
						t,
						function(x, y, z)
							return q(x, y, z, v)
						end
					)
				end
				return r :: h.ForPairsConstructor
			end)()
		end,
		[59] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(59)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k, l, m, n, o, p =
					d(f.Types),
					d(f.External),
					d(f.State.For),
					d(f.State.Value),
					d(f.State.Computed),
					d(f.State.For.ForTypes),
					d(f.Logging.parseError),
					d(f.Memory.doCleanup),
					{
						__index = {
							roamKeys = true,
							roamValues = false,
							invalidateInputKey = function(h): ()
							end,
							invalidateInputValue = function(h): ()
								h._inputValueState:set(h.inputValue)
							end,
							useOutputPair = function(h, i)
								return h.inputKey, i(h._outputValueState)
							end,
						},
					}
				local function q<K, VI, VO, S>(
					r: h.Scope<S>,
					s: K,
					t: VI,
					v: (h.Use, h.Scope<S>, VI) -> VO
				): m.SubObject<S, K, K, VI, VO>
					local x = {}
					x.maybeScope = r
					x.inputKey = s
					x.inputValue = t
					x._inputValueState = k(r, t)
					x._processor = v
					x._outputValueState = l(
						r,
						function(y, z): VO?
							local A = y(x._inputValueState)
							local B, C = xpcall(x._processor, n, y, z, A)
							if B then
								return C
							else
								local D: h.Error = C :: any
								D.context = `while processing value {tostring(A)}`
								i.logErrorNonFatal("callbackError", D)
								o(z)
								table.clear(z)
								return nil
							end
						end
					)
					return setmetatable(x, p) :: any
				end
				local function r<K, VI, VO, S>(
					s: h.Scope<S>,
					t: h.UsedAs<{ [K]: VI }>,
					v: (h.Use, h.Scope<S>, VI) -> VO
				): h.For<K, VO>
					return j(
						s,
						t,
						function(x, y, z)
							return q(x, y, z, v)
						end
					)
				end
				return r :: h.ForValuesConstructor
			end)()
		end,
		[60] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(60)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j, k =
					d(f.Types),
					d(f.Graph.change),
					d(f.Utility.isSimilar),
					d(f.Utility.nicknames)
				type Self<T, S> = h.Value<T, S>
				local l = {}
				l.type = "State"
				l.kind = "Value"
				l.timeliness = "lazy"
				l.dependencySet = table.freeze({})
				local m = table.freeze({ __index = l })
				local function n<T>(o: h.Scope<unknown>, p: T): h.Value<T, any>
					local q = os.clock()
					local r: Self<T, any> = setmetatable(
						{
							createdAt = q,
							dependentSet = {},
							lastChange = os.clock(),
							scope = o,
							validity = "valid",
							_EXTREMELY_DANGEROUS_usedAsValue = p,
						},
						m
					) :: any
					local s = function()
						r.scope = nil
					end
					r.oldestTask = s
					k[r.oldestTask] = "Value"
					table.insert(o, s)
					return r
				end
				function l.set<T, S>(o: Self<T, S>, p: S): S
					local q = o._EXTREMELY_DANGEROUS_usedAsValue
					if not j(q, p) then
						o._EXTREMELY_DANGEROUS_usedAsValue = p :: any
						i(o)
					end
					return p
				end
				function l._evaluate<T, S>(o: Self<T, S>): boolean
					return true
				end
				table.freeze(l)
				return n :: h.ValueConstructor
			end)()
		end,
		[61] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(61)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h = d(f.Types)
				local function i<T>(j: h.UsedAs<T>): h.StateObject<T>?
					if typeof(j) == "table" and j.type == "State" then
						return j
					else
						return nil
					end
				end
				return i
			end)()
		end,
		[62] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(62)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j = d(f.Types), d(f.State.castToState), d(f.Graph.evaluate)
				local function k<T>(l: h.UsedAs<T>): T
					local m = i(l)
					if m ~= nil then
						j(m, false)
						return m._EXTREMELY_DANGEROUS_usedAsValue :: T
					else
						return l :: T
					end
				end
				return k
			end)()
		end,
		[63] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(63)
			local e
			return (function(...)
				return nil
			end)()
		end,
		[64] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(64)
			local e
			return (function(...)
				local f
				export type Error = {
					type: "Error",
					raw: string,
					message: string,
					trace: string,
					context: string?,
				}
				export type Animatable = number | CFrame | Color3 | ColorSequenceKeypoint | DateTime | NumberRange | NumberSequenceKeypoint | PhysicalProperties | Ray | Rect | Region3 | Region3int16 | UDim | UDim2 | Vector2 | Vector2int16 | Vector3 | Vector3int16
				export type Task = Instance | RBXScriptConnection | (() -> ()) | { destroy: (unknown) -> () } | { Destroy: (unknown) -> () } | { Task }
				export type Scope<Constructors = any> = { Task } & Constructors
				export type ScopedObject = { scope: Scope<unknown>?, oldestTask: unknown }
				export type Version = { major: number, minor: number, isRelease: boolean }
				export type Contextual<T> = {
					type: "Contextual",
					now: (Contextual<T>) -> T,
					is: (Contextual<T>, T) -> ContextualIsMethods,
				}
				type ContextualIsMethods = {
					during: <R, A...>(ContextualIsMethods, (A...) -> R, A...) -> R,
				}
				export type GraphObject = ScopedObject & {
					createdAt: number,
					dependencySet: { [GraphObject]: unknown },
					dependentSet: { [GraphObject]: unknown },
					lastChange: number?,
					timeliness: "lazy" | "eager",
					validity: "valid" | "invalid" | "busy",
					_evaluate: (GraphObject) -> boolean,
				}
				export type StateObject<T> = GraphObject & {
					type: "State",
					kind: string,
					_EXTREMELY_DANGEROUS_usedAsValue: T,
				}
				export type UsedAs<T> = StateObject<T> | T
				export type Use = <T>(target: UsedAs<T>) -> T
				export type Value<T, S = T> = StateObject<T> & {
					kind: "State",
					timeliness: "lazy",
					set: (Value<T, S>, newValue: S, force: boolean?) -> S,
					____phantom_setType: (never) -> S,
				}
				export type ValueConstructor = <T>(scope: Scope<unknown>, initialValue: T) -> Value<T, any>
				export type Computed<T> = StateObject<T> & { kind: "Computed", timeliness: "lazy" }
				export type ComputedConstructor = <T, S>(scope: S & Scope<unknown>, callback: (Use, S) -> T) -> Computed<T>
				export type For<KO, VO> = StateObject<{ [KO]: VO }> & { kind: "For" }
				export type ForPairsConstructor = <KI, KO, VI, VO, S>(scope: S & Scope<unknown>, inputTable: UsedAs<{ [KI]: VI }>, processor: (Use, S, key: KI, value: VI) -> (KO, VO)) -> For<KO, VO>
				export type ForKeysConstructor = <KI, KO, V, S>(scope: S & Scope<unknown>, inputTable: UsedAs<{ [KI]: V }>, processor: (Use, S, key: KI) -> KO) -> For<KO, V>
				export type ForValuesConstructor = <K, VI, VO, S>(scope: S & Scope<unknown>, inputTable: UsedAs<{ [K]: VI }>, processor: (Use, S, value: VI) -> VO) -> For<K, VO>
				export type Observer = GraphObject & {
					type: "Observer",
					timeliness: "eager",
					onChange: (Observer, callback: () -> ()) -> () -> (),
					onBind: (Observer, callback: () -> ()) -> () -> (),
				}
				export type ObserverConstructor = (scope: Scope<unknown>, watching: unknown) -> Observer
				export type Tween<T> = StateObject<T> & { kind: "Tween" }
				export type TweenConstructor = <T>(scope: Scope<unknown>, goalState: UsedAs<T>, tweenInfo: UsedAs<TweenInfo>?) -> Tween<T>
				export type Spring<T> = StateObject<T> & {
					kind: "Spring",
					setPosition: (Spring<T>, newPosition: T) -> (),
					setVelocity: (Spring<T>, newVelocity: T) -> (),
					addVelocity: (Spring<T>, deltaVelocity: T) -> (),
				}
				export type SpringConstructor = <T>(scope: Scope<unknown>, goalState: UsedAs<T>, speed: UsedAs<number>?, damping: UsedAs<number>?) -> Spring<T>
				export type SpecialKey = {
					type: "SpecialKey",
					kind: string,
					stage: "self" | "descendants" | "ancestor" | "observer",
					apply: (self: SpecialKey, scope: Scope<unknown>, value: unknown, applyTo: Instance) -> (),
				}
				export type Child = Instance | StateObject<Child> | { [unknown]: Child }
				export type PropertyTable = { [(string | SpecialKey)]: unknown }
				export type NewConstructor = (scope: Scope<unknown>, className: string) -> (propertyTable: PropertyTable) -> Instance
				export type HydrateConstructor = (scope: Scope<unknown>, target: Instance) -> (propertyTable: PropertyTable) -> Instance
				export type DeriveScopeConstructor = (<S>(Scope<S>) -> Scope<S>) & (<S, A>(Scope<S>, A & {}) -> Scope<S & A>) & (<S, A, B>(Scope<S>, A & {}, B & {}) -> Scope<S & A & B>) & (<S, A, B, C>(Scope<S>, A & {}, B & {}, C & {}) -> Scope<S & A & B & C>) & (<S, A, B, C, D>(Scope<S>, A & {}, B & {}, C & {}, D & {}) -> Scope<S & A & B & C & D>) & (<S, A, B, C, D, E>(Scope<S>, A & {}, B & {}, C & {}, D & {}, E & {}) -> Scope<S & A & B & C & D & E>) & (<S, A, B, C, D, E, F>(Scope<S>, A & {}, B & {}, C & {}, D & {}, E & {}, F & {}) -> Scope<S & A & B & C & D & E & F>) & (<S, A, B, C, D, E, F, G>(Scope<S>, A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}) -> Scope<S & A & B & C & D & E & F & G>) & (<S, A, B, C, D, E, F, G, H>(Scope<S>, A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}) -> Scope<S & A & B & C & D & E & F & G & H>) & (<S, A, B, C, D, E, F, G, H, I>(Scope<S>, A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}) -> Scope<S & A & B & C & D & E & F & G & H & I>) & (<S, A, B, C, D, E, F, G, H, I, J>(Scope<S>, A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}, J & {}) -> Scope<S & A & B & C & D & E & F & G & H & I & J>) & (<S, A, B, C, D, E, F, G, H, I, J, K>(Scope<S>, A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}, J & {}, K & {}) -> Scope<S & A & B & C & D & E & F & G & H & I & J & K>) & (<S, A, B, C, D, E, F, G, H, I, J, K, L>(Scope<S>, A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}, J & {}, K & {}, L & {}) -> Scope<S & A & B & C & D & E & F & G & H & I & J & K & L>)
				export type ScopedConstructor = (() -> Scope<{}>) & (<A>(A & {}) -> Scope<A>) & (<A, B>(A & {}, B & {}) -> Scope<A & B>) & (<A, B, C>(A & {}, B & {}, C & {}) -> Scope<A & B & C>) & (<A, B, C, D>(A & {}, B & {}, C & {}, D & {}) -> Scope<A & B & C & D>) & (<A, B, C, D, E>(A & {}, B & {}, C & {}, D & {}, E & {}) -> Scope<A & B & C & D & E>) & (<A, B, C, D, E, F>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}) -> Scope<A & B & C & D & E & F>) & (<A, B, C, D, E, F, G>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}) -> Scope<A & B & C & D & E & F & G>) & (<A, B, C, D, E, F, G, H>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}) -> Scope<A & B & C & D & E & F & G & H>) & (<A, B, C, D, E, F, G, H, I>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}) -> Scope<A & B & C & D & E & F & G & H & I>) & (<A, B, C, D, E, F, G, H, I, J>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}, J & {}) -> Scope<A & B & C & D & E & F & G & H & I & J>) & (<A, B, C, D, E, F, G, H, I, J, K>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}, J & {}, K & {}) -> Scope<A & B & C & D & E & F & G & H & I & J & K>) & (<A, B, C, D, E, F, G, H, I, J, K, L>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}, J & {}, K & {}, L & {}) -> Scope<A & B & C & D & E & F & G & H & I & J & K & L>)
				export type ContextualConstructor = <T>(defaultValue: T) -> Contextual<T>
				export type Safe = <Success, Fail>(callbacks: { try: () -> Success, fallback: (err: unknown) -> Fail }) -> Success | Fail
				export type Fusion = {
					version: Version,
					cleanup: () -> () -> (),
					Contextual: ContextualConstructor,
					Safe: Safe,
					doCleanup: (Task) -> (),
					scoped: ScopedConstructor,
					deriveScope: DeriveScopeConstructor,
					innerScope: DeriveScopeConstructor,
					insert: <Tasks...>(scope: Scope<unknown>, Tasks...) -> Tasks...,
					peek: Use,
					Value: ValueConstructor,
					Computed: ComputedConstructor,
					ForPairs: ForPairsConstructor,
					ForKeys: ForKeysConstructor,
					ForValues: ForValuesConstructor,
					Observer: ObserverConstructor,
					Tween: TweenConstructor,
					Spring: SpringConstructor,
					New: NewConstructor,
					Hydrate: HydrateConstructor,
					Child: ({ Child }) -> Child,
					Children: SpecialKey,
					Out: (propertyName: string) -> SpecialKey,
					OnEvent: (eventName: string) -> SpecialKey,
					OnChange: (propertyName: string) -> SpecialKey,
					Attribute: (attributeName: string) -> SpecialKey,
					AttributeChange: (attributeName: string) -> SpecialKey,
					AttributeOut: (attributeName: string) -> SpecialKey,
					Tag: (tagName: string) -> SpecialKey,
				}
				export type ExternalProvider = {
					policies: { allowWebLinks: boolean },
					logErrorNonFatal: (errorString: string) -> (),
					logWarn: (errorString: string) -> (),
					doTaskImmediate: (resume: () -> ()) -> (),
					doTaskDeferred: (resume: () -> ()) -> (),
					startScheduler: () -> (),
					stopScheduler: () -> (),
				}
				export type ExternalDebugger = {
					startDebugging: () -> (),
					stopDebugging: () -> (),
					trackScope: (scope: Scope<unknown>) -> (),
					untrackScope: (scope: Scope<unknown>) -> (),
				}
				return nil
			end)()
		end,
		[72] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(72)
			local e
			return (function(...)
				local f
				return setmetatable({}, { __mode = "k" })
			end)()
		end,
		[66] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(66)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h, i, j = d(f.Types), d(f.External), d(f.Logging.parseError)
				export type Self<T> = h.Contextual<T> & { _valuesNow: { [thread]: { value: T } }, _defaultValue: T }
				local k = {}
				k.type = "Contextual"
				local l, m = table.freeze({ __index = k }), table.freeze({ __mode = "k" })
				local function n<T>(o: T): h.Contextual<T>
					local p: Self<T> = setmetatable(
						{ _valuesNow = setmetatable({}, m), _defaultValue = o },
						l
					) :: any
					return p
				end
				function k.now<T>(o: Self<T>): T
					local p = coroutine.running()
					local q = o._valuesNow[p]
					if typeof(q) ~= "table" then
						return o._defaultValue
					else
						return q.value
					end
				end
				function k.is<T>(o: Self<T>, p: T)
					local q = {}
					function q.during<T, A...>(r: any, s: (A...) -> T, ...: A...): T
						local t = coroutine.running()
						local v = o._valuesNow[t]
						o._valuesNow[t] = { value = p }
						local x, y = xpcall(s, j, ...)
						o._valuesNow[t] = v
						if not x then
							i.logError("callbackError", y :: any)
						end
						return y
					end
					return q
				end
				table.freeze(k)
				return n
			end)()
		end,
		[69] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(69)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h = d(f.External)
				local function i(j: boolean, k: { [unknown]: unknown }, ...: { [unknown]: unknown }): { [unknown]: unknown }
					local l = { ... }
					if #l < 1 then
						return k
					else
						for m, n in l do
							for o, p in n do
								if j or k[o] == nil then
									k[o] = p
								elseif not j then
									h.logError("mergeConflict", nil, tostring(o))
								end
							end
						end
						return k
					end
				end
				return i
			end)()
		end,
		[68] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(68)
			local e
			return (function(...)
				local f
				local function g(h: unknown, i: unknown): boolean
					local j = typeof(h)
					local k, l = j == "table", j == "userdata"
					return if not (k or l) then h == i or h ~= h and i ~= i
						elseif j == typeof(i)
							and (l or table.isfrozen(h :: any) or getmetatable(h :: any) ~= nil) then h
							== i
						else false
				end
				return g
			end)()
		end,
		[71] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(71)
			local e
			return (function(...)
				local f
				local function g(): never
					error("This codepath should not be reachable")
				end
				return g
			end)()
		end,
		[73] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(73)
			local e
			return (function(...)
				local f
				local function g(h: unknown): string
					local i = typeof(h)
					if i == "table" then
						local j = h :: { type: unknown? }
						if typeof(j.type) == "string" then
							return j.type
						end
					end
					return i
				end
				return g
			end)()
		end,
		[67] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(67)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local function h<Success, Fail>(
					i: { try: () -> Success, fallback: (err: unknown) -> Fail }
				): Success | Fail
					local j, k = xpcall(i.try, i.fallback)
					return k
				end
				return h
			end)()
		end,
		[70] = function()
			LPH_ATTRIBUTES(VM(NONE), ERROR_HANDLING(false))
			local b, c, d = a(70)
			local e
			return (function(...)
				local f, g = c.Parent.Parent
				local h = d(f.Utility.nicknames)
				local function i(j: unknown, k: string): string
					local l = h[j]
					if typeof(l) == "string" then
						return l
					end
					if typeof(j) == "table" then
						local m = j :: { [any]: any }
						if typeof(m.name) == "string" then
							return m.name
						elseif typeof(m.kind) == "string" then
							return m.kind
						elseif typeof(m.type) == "string" then
							return m.type
						end
					end
					return k
				end
				return i
			end)()
		end,
	},
	{
		{
			1,
			2,
			{ "Fusion" },
			{
				{ 16, 2, { "External" } },
				{ 17, 2, { "ExternalDebug" } },
				{
					65,
					1,
					{ "Utility" },
					{
						{ 73, 2, { "xtypeof" } },
						{ 69, 2, { "merge" } },
						{ 72, 2, { "nicknames" } },
						{ 67, 2, { "Safe" } },
						{ 66, 2, { "Contextual" } },
						{ 71, 2, { "never" } },
						{ 70, 2, { "nameOf" } },
						{ 68, 2, { "isSimilar" } },
					},
				},
				{
					64,
					2,
					{
						"Types",
					},
				},
				{
					42,
					1,
					{ "Memory" },
					{
						{ 46, 2, { "doCleanup" } },
						{ 47, 2, { "innerScope" } },
						{ 50, 2, { "scoped" } },
						{ 45, 2, { "deriveScopeImpl" } },
						{ 43, 2, { "checkLifetime" } },
						{ 48, 2, { "insert" } },
						{ 44, 2, { "deriveScope" } },
						{ 49, 2, { "needsDestruction" } },
					},
				},
				{
					2,
					1,
					{ "Animation" },
					{
						{
							8,
							2,
							{
								"getTweenRatio",
							},
						},
						{ 11, 2, { "springCoefficients" } },
						{ 6, 2, { "Tween" } },
						{ 9, 2, { "lerpType" } },
						{ 7, 2, { "getTweenDuration" } },
						{
							12,
							2,
							{
								"unpackType",
							},
						},
						{ 4, 2, { "Spring" } },
						{ 3, 2, { "ExternalTime" } },
						{ 5, 2, { "Stopwatch" } },
						{ 10, 2, { "packType" } },
					},
				},
				{
					38,
					1,
					{ "Logging" },
					{
						{ 40, 2, { "messages" } },
						{ 39, 2, { "formatError" } },
						{ 41, 2, { "parseError" } },
					},
				},
				{
					18,
					1,
					{ "Graph" },
					{
						{ 23, 2, { "evaluate" } },
						{ 21, 2, { "change" } },
						{
							22,
							2,
							{ "depend" },
						},
						{ 19, 2, { "Observer" } },
						{ 20, 2, { "castToGraph" } },
					},
				},
				{
					52,
					1,
					{ "State" },
					{
						{ 59, 2, { "ForValues" } },
						{ 63, 2, { "updateAll" } },
						{
							54,
							2,
							{ "For" },
							{ { 56, 2, { "ForTypes" } }, { 55, 2, { "Disassembly" } } },
						},
						{ 61, 2, { "castToState" } },
						{ 62, 2, { "peek" } },
						{ 58, 2, { "ForPairs" } },
						{ 60, 2, { "Value" } },
						{ 57, 2, { "ForKeys" } },
						{ 53, 2, { "Computed" } },
					},
				},
				{
					24,
					1,
					{ "Instances" },
					{
						{ 30, 2, { "Hydrate" } },
						{ 27, 2, { "AttributeOut" } },
						{ 37, 2, { "defaultProps" } },
						{ 31, 2, { "New" } },
						{ 33, 2, { "OnEvent" } },
						{ 32, 2, { "OnChange" } },
						{ 29, 2, { "Children" } },
						{ 35, 2, { "Tag" } },
						{ 28, 2, { "Child" } },
						{ 25, 2, { "Attribute" } },
						{ 34, 2, { "Out" } },
						{ 26, 2, { "AttributeChange" } },
						{ 36, 2, { "applyInstanceProps" } },
					},
				},
				{
					51,
					2,
					{
						"RobloxExternal",
					},
				},
				{ 13, 1, { "Colour" }, { { 15, 2, { "sRGB" } }, { 14, 2, { "Oklab" } } } },
			},
		},
	},
	"0.4.2",
	"WaxRuntime",
	string,
	task,
	setmetatable,
	error,
	next,
	table,
	unpack,
	coroutine,
	script,
	type,
	require,
	pcall,
	tostring,
	tonumber,
	_VERSION
local x, y, z, A, B, C, D =
	k.insert,
	k.remove,
	k.freeze
		or function(x)
			return x
		end,
	m.wrap,
	f.sub,
	f.match,
	f.gmatch
if t and B(t, 1, 4) == "Lune" then
	local E, F = q(p, "@lune/task")
	if E and F then
		g = F
	end
end
local E = g and g.defer
local F, G, H, I, J, K, L, M, N =
	E
		or function(F, ...)
			A(F)(...)
		end,
	{
		[1] = "Folder",
		[2] = "ModuleScript",
		[3] = "Script",
		[4] = "LocalScript",
		[5] = "StringValue",
	},
	{},
	{},
	{},
	{},
	{},
	{},
	{}
local O, P =
	{
		GetFullName = {
			{},
			function(O)
				local P, Q = O.Name, O.Parent
				while Q do
					P = Q.Name .. "." .. P
					Q = Q.Parent
				end
				return P
			end,
		},
		GetChildren = {
			{},
			function(O)
				local P = {}
				for Q in j, N[O] do
					x(P, Q)
				end
				return P
			end,
		},
		GetDescendants = {
			{},
			function(O)
				local P = {}
				for Q in j, N[O] do
					x(P, Q)
					for R, S in j, Q:GetDescendants() do
						x(P, S)
					end
				end
				return P
			end,
		},
		FindFirstChild = {
			{ "string", "boolean?" },
			function(O, P, Q)
				local R = N[O]
				for S in j, R do
					if S.Name == P then
						return S
					end
				end
				if Q then
					for S in j, R do
						return S:FindFirstChild(P, true)
					end
				end
			end,
		},
		FindFirstAncestor = {
			{ "string" },
			function(O, P)
				local Q = O.Parent
				while Q do
					if Q.Name == P then
						return Q
					end
					Q = Q.Parent
				end
			end,
		},
		WaitForChild = {
			{ "string", "number?" },
			function(O, P)
				return O:FindFirstChild(P)
			end,
		},
	},
	{}
for Q, R in j, O do
	local S, T, U = R[1], R[2], {}
	for V, W in j, S do
		local X, Y = C(W, "^([^%?]+)(%??)")
		U[V] = { X, Y }
	end
	P[Q] = function(V, ...)
		if not N[V] then
			i("Expected ':' not '.' calling member function " .. Q, 2)
		end
		local W = { ... }
		for X, Y in j, U do
			local Z = W[X]
			local _, aa, ab = o(Z), Y[1], Y[2]
			if Z == nil and not ab then
				i("Argument " .. Z .. " missing or nil", 3)
			end
			if aa ~= "any" and _ ~= aa and not (_ == "nil" and ab) then
				i("Argument " .. X .. ' expects type "' .. aa .. '", got "' .. _ .. '"', 2)
			end
		end
		return T(V, ...)
	end
end
local function aa(ab, Q, R)
	local S, T = (h({}, { __mode = "k" }))
	local function U(V)
		i(V .. " is not a valid (virtual) member of " .. ab .. ' "' .. Q .. '"', 3)
	end
	local function V(W)
		i("Unable to assign (virtual) property " .. W .. ". Property is read only", 3)
	end
	local W, X = {}, {}
	X.__metatable = false
	X.__index = function(Y, Z)
		if Z == "ClassName" then
			return ab
		elseif Z == "Name" then
			return Q
		elseif Z == "Parent" then
			return R
		elseif ab == "StringValue" and Z == "Value" then
			return T
		else
			local _ = P[Z]
			if _ then
				return _
			end
		end
		for _ in j, S do
			if _.Name == Z then
				return _
			end
		end
		U(Z)
	end
	X.__newindex = function(Y, Z, _)
		if Z == "ClassName" then
			V(Z)
		elseif Z == "Name" then
			Q = _
		elseif Z == "Parent" then
			if _ == W then
				return
			end
			if R ~= nil then
				N[R][W] = nil
			end
			R = _
			if _ ~= nil then
				N[_][W] = true
			end
		elseif ab == "StringValue" and Z == "Value" then
			T = _
		else
			U(Z)
		end
	end
	X.__tostring = function()
		return Q
	end
	h(W, X)
	N[W] = S
	if R ~= nil then
		N[R][W] = true
	end
	return W
end
local function ab(Q, R)
	local S, T, U, V = Q[1], Q[2], Q[3], Q[4]
	local W = G[T]
	local X = U and y(U, 1) or W
	local Y = aa(W, X, R)
	H[S] = Y
	if U then
		for Z, _ in j, U do
			Y[Z] = _
		end
	end
	if V then
		for Z, _ in j, V do
			ab(_, Y)
		end
	end
	return Y
end
local Q = aa("Folder", "[" .. e .. "]")
for R, S in j, c do
	ab(S, Q)
end
for R, S in j, b do
	local T = H[R]
	I[T] = S
	J[T] = R
	local U = T.ClassName
	if U == "LocalScript" or U == "Script" then
		x(L, T)
	end
end
local function R(S)
	local T, U = S.ClassName, K[S]
	if U and T == "ModuleScript" then
		return l(U)
	end
	local V = I[S]
	local function W(X)
		X = r(X)
		local Y, Z, _ = S:GetFullName(), C(X, "[^:]+:(%d+): (.+)")
		if not Z or not v then
			return Y .. ":*: " .. (_ or X)
		end
		Z = s(Z)
		local ac = J[S]
		local ad = v[ac]
		local ae = Z - ad + 1
		if ae < 0 then
			ae = "?"
		end
		return Y .. ":" .. ae .. ": " .. _
	end
	if T == "LocalScript" or T == "Script" then
		local ac, ad = q(V)
		if not ac then
			i(W(ad), 0)
		end
	else
		local ac = { q(V) }
		local ad = y(ac, 1)
		if not ad then
			local ae = y(ac, 1)
			i(W(ae), 0)
		end
		K[S] = ac
		return l(ac)
	end
end
function a(ac)
	local ad = H[ac]
	local function ae(S, ...)
		local T = { q(S, ...) }
		local U = y(T, 1)
		if not U then
			i(T[1], 3)
		end
		return l(T)
	end
	local S = z(
		h(
			{},
			{
				__index = M,
				__newindex = function(S, T, U)
					M[T] = U
				end,
				__len = function()
					return #M
				end,
				__iter = function()
					return j, M
				end,
			}
		)
	)
	local T, U = z({ version = d, envname = e, shared = S, script = n, require = p }), ad
	local function V(W, ...)
		local X, Y, Z =
			o(W),
			"Attempted to call require with a non-ModuleScript",
			"Attempted to call require with self"
		if X == "table" and N[W] then
			if W.ClassName ~= "ModuleScript" then
				i(Y, 2)
			elseif W == ad then
				i(Z, 2)
			end
			return R(W)
		elseif X == "string" and B(W, 1, 1) ~= "@" then
			if #W == 0 then
				i("Attempted to call require with empty string", 2)
			end
			local _ = ad
			if B(W, 1, 1) == "/" then
				_ = Q
			elseif B(W, 1, 2) == "./" then
				W = B(W, 3)
			end
			local af
			for ag in D(W, "([^/]*)/?") do
				local ah = ag
				if ag == ".." then
					ah = "Parent"
				end
				if ah ~= "" then
					local ai = _:FindFirstChild(ah)
					if not ai then
						local aj = _.Parent
						if aj then
							ai = aj:FindFirstChild(ah)
						end
					end
					if ai then
						_ = ai
					elseif ag ~= af and ag ~= "init" and ag ~= "init.server" and ag ~= "init.client" then
						i('Virtual script path "' .. W .. '" not found', 2)
					end
				end
				af = ag
			end
			if _.ClassName ~= "ModuleScript" then
				i(Y, 2)
			elseif _ == ad then
				i(Z, 2)
			end
			return R(_)
		end
		return ae(p, W, ...)
	end
	return T, U, V
end
for ac, ad in j, L do
	F(R, ad)
end
return R(Q:GetChildren()[1])
