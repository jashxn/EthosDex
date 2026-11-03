-- Control callbacks run after all config values have been applied. A keyed
-- callback is replaced by its latest notification while a load is active.
local Heartbeat = game:GetService("RunService").Heartbeat

local CallbackBatch = {}
local active = nil
local MAX_PASSES = 64

local function execute(callback, key)
	if type(callback) ~= "function" then
		return true
	end
	local owner = active
	local result = table.pack(
		xpcall(
			callback,
			function(message)
				return debug.traceback(tostring(message), 2)
			end
		)
	)
	if not result[1] then
		local message = (if key then "[" .. key .. "] " else "") .. tostring(result[2])
		if owner and not owner.cancelled then
			table.insert(owner.errors, message)
			owner.failedPriority = math.min(
				owner.failedPriority or math.huge,
				owner.executingPriority or 0
			)
		end
		warn("[Ethos callback] " .. message)
		return false, message
	end
	return table.unpack(result, 1, result.n)
end

function CallbackBatch.current()
	return if active and not active.cancelled then active else nil
end

function CallbackBatch.begin(orderResolver)
	assert(CallbackBatch.current() == nil, "A control callback batch is already active")
	assert(
		orderResolver == nil or type(orderResolver) == "function",
		"Expected a callback order resolver"
	)
	local batch = {
		pending = {},
		nextOrder = 0,
		errors = {},
		orderResolver = orderResolver,
		cancelled = false,
		finishing = false,
	}
	active = batch
	return batch
end

function CallbackBatch.invoke(callback, key)
	if key ~= nil then
		assert(type(key) == "string", "Expected a control callback key")
		if active then
			if active.cancelled then
				return false, "Control callback batch was cancelled"
			end
			local job = active.pending[key]
			if job then
				job.callback = callback
			else
				active.nextOrder += 1
				active.pending[key] = { key = key, callback = callback, order = active.nextOrder }
			end
			return true
		end
	end
	return execute(callback, key)
end

function CallbackBatch.cancel(batch)
	if batch == nil then
		return
	end
	batch.cancelled = true
	table.clear(batch.pending)
	-- Deferred Fusion observers may still publish their last notification. Keep
	-- this cancelled owner for two deferred turns so they cannot run effects.
	if active == batch then
		task.defer(function()
			task.defer(function()
				if active == batch then
					active = nil
				end
			end)
		end)
	end
end

function CallbackBatch.finish(batch)
	if active ~= batch or batch.cancelled then
		return false, "Control callback batch is no longer active"
	end
	if batch.finishing then
		return false, "Control callback batch is already finishing"
	end
	batch.finishing = true
	local idlePasses = 0
	for _ = 1, MAX_PASSES do
		-- Cross an engine frame boundary so deferred state observers can publish
		-- dependent changes before selecting the next callback phase.
		Heartbeat:Wait()
		if active ~= batch or batch.cancelled then
			return false, "Control callback batch was cancelled"
		end
		local jobs = {}
		local nextPriority = math.huge
		for _, job in pairs(batch.pending) do
			local ok, priority = true, 0
			if batch.orderResolver then
				ok, priority = pcall(batch.orderResolver, job.key)
			end
			if not ok
				or type(priority) ~= "number"
				or priority ~= priority
				or math.abs(priority) == math.huge then
				CallbackBatch.cancel(batch)
				return
					false,
					"Invalid callback loading order for " .. job.key .. ": " .. tostring(priority)
			end
			job.priority = priority
			nextPriority = math.min(nextPriority, priority)
			table.insert(jobs, job)
		end
		-- Other callbacks in a failed phase can finish their independent work.
		-- A later activation phase must not run with a failed dependency.
		if batch.failedPriority ~= nil and nextPriority > batch.failedPriority then
			CallbackBatch.cancel(batch)
			return false, table.concat(batch.errors, "\n")
		end
		if #jobs == 0 then
			idlePasses += 1
			if idlePasses == 2 then
				active = nil
				return
					#batch.errors == 0,
					if #batch.errors > 0 then table.concat(batch.errors, "\n") else nil
			end
		else
			idlePasses = 0
			table.sort(
				jobs,
				function(a, b)
					if a.priority == b.priority then
						return a.order < b.order
					end
					return a.priority < b.priority
				end
			)
			batch.executingPriority = nextPriority
			for _, job in ipairs(jobs) do
				if job.priority ~= nextPriority then
					break
				end
				if active ~= batch or batch.cancelled then
					return false, "Control callback batch was cancelled"
				end
				if batch.pending[job.key] == job then
					batch.pending[job.key] = nil
					batch.lastCallbackKey = job.key
					execute(job.callback, job.key)
				end
			end
			batch.executingPriority = nil
		end
	end
	CallbackBatch.cancel(batch)
	return false, "Control callbacks did not settle after config loading"
end

return CallbackBatch
