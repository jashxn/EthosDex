--!nocheck

-- Download and register only the asset requested by the caller. Nothing runs
-- at module load. Tests supply the same filesystem/HTTP boundary as an executor.
local AssetCache = {}

local function callInTask(callback, argument, timeoutSeconds, timeoutMessage)
	LPH_ATTRIBUTES(VM(NONE), PRESET(FAST), ERROR_HANDLING(false))
	-- The executor owns the yielding native call. Do not cancel or resume its
	-- thread: a late native callback must be free to finish without waking us.
	local result: { any }? = nil
	local abandoned = false
	local deadline = os.clock() + timeoutSeconds
	task.defer(function()
		LPH_ATTRIBUTES(VM(NONE), PRESET(FAST), ERROR_HANDLING(false))
		if abandoned or os.clock() >= deadline then
			return
		end
		local response = table.pack(pcall(callback, argument))
		if not abandoned and os.clock() < deadline then
			result = response
		end
	end)
	local heartbeat = game:GetService("RunService").Heartbeat
	while result == nil and os.clock() < deadline do
		heartbeat:Wait()
	end
	if result == nil then
		abandoned = true
		error(timeoutMessage, 0)
	end
	if not result[1] then
		error(result[2], 0)
	end
	return result[2]
end

local function checksum(bytes)
	local a, b = 1, 0
	for index = 1, #bytes do
		a = (a + string.byte(bytes, index)) % 65521
		b = (b + a) % 65521
	end
	return string.format("%08x", b * 65536 + a)
end

local function uint16(bytes, offset)
	local a, b = string.byte(bytes, offset, offset + 1)
	return a * 256 + b
end

local function uint32(bytes, offset)
	local a, b, c, d = string.byte(bytes, offset, offset + 3)
	return ((a * 256 + b) * 256 + c) * 256 + d
end

local function validate(bytes, options)
	if type(bytes) ~= "string" or #bytes == 0 then
		return false, "asset body is empty"
	end
	if options.Kind == "font" then
		local signature = string.sub(bytes, 1, 4)
		if #bytes < 28 or (signature ~= "\0\1\0\0" and signature ~= "OTTO") then
			return false, "expected a TTF or OTF font"
		end
		local count = uint16(bytes, 5)
		if count < 1 or count > 512 or 12 + count * 16 > #bytes then
			return false, "invalid font table directory"
		end
		for index = 0, count - 1 do
			local record = 13 + index * 16
			local offset = uint32(bytes, record + 8)
			local length = uint32(bytes, record + 12)
			if offset > #bytes or length > #bytes - offset then
				return false, "font table is truncated"
			end
		end
		return true
	end
	if options.Extension == "jpg" or options.Extension == "jpeg" then
		return
			string.sub(bytes, 1, 3) == "\255\216\255" and string.sub(bytes, -2) == "\255\217",
			"expected a complete JPEG image"
	end
	if #bytes < 45
		or string.sub(bytes, 1, 8) ~= "\137PNG\13\10\26\10"
		or string.sub(bytes, 13, 16) ~= "IHDR"
		or string.sub(bytes, -12) ~= "\0\0\0\0IEND\174\66\96\130" then
		return false, "expected a complete PNG image"
	end
	local width, height = uint32(bytes, 17), uint32(bytes, 21)
	if width < 1 or height < 1 or width > 8192 or height > 8192 then
		return false, "image dimensions must be between 1 and 8192"
	end
	return true
end

local function normalize(options)
	assert(type(options) == "table", "Asset options must be a table")
	local result = table.clone(options)
	assert(
		type(result.Name) == "string"
			and #result.Name <= 100
			and string.match(result.Name, "^[%w_-][%w_.-]*$") ~= nil,
		"Asset Name must be a safe file name"
	)
	assert(
		type(result.Url) == "string" and string.match(result.Url, "^https://[^%s]+$") ~= nil,
		"Asset Url must use HTTPS"
	)
	assert(
		result.Version == nil or type(result.Version) == "string",
		"Asset Version must be a string"
	)
	result.Kind = result.Kind or "image"
	assert(result.Kind == "image" or result.Kind == "font", "Asset Kind must be image or font")
	local path = string.match(result.Url, "^[^?#]+") or result.Url
	result.Extension = string.lower(result.Extension or string.match(path, "%.([%w]+)$") or "")
	if result.Kind == "font" then
		assert(
			result.Extension == "ttf" or result.Extension == "otf",
			"Font URL must end in .ttf or .otf"
		)
	else
		assert(
			result.Extension == "png" or result.Extension == "jpg" or result.Extension == "jpeg",
			"Image URL must end in .png, .jpg, or .jpeg"
		)
	end
	return result
end

local function encodeIdentity(fields)
	-- Length prefixes keep fields distinct even if a field contains separators.
	for index, value in ipairs(fields) do
		fields[index] = tostring(#value) .. ":" .. value
	end
	return table.concat(fields)
end

local function requestIdentity(options)
	return encodeIdentity({
		options.Name,
		options.Url,
		options.Version or "",
		options.Kind,
		options.Extension,
	})
end

local function fontStyle(weight, style)
	weight = weight or 400
	style = style or "normal"
	if typeof(weight) == "EnumItem" and weight.EnumType == Enum.FontWeight then
		weight = weight.Value
	end
	if typeof(style) == "EnumItem" and style.EnumType == Enum.FontStyle then
		style = string.lower(style.Name)
	end
	assert(
		type(weight) == "number" and weight >= 100 and weight <= 900 and weight % 100 == 0,
		"Font Weight must be an Enum.FontWeight or 100 through 900"
	)
	assert(style == "normal" or style == "italic", "Font Style must be normal or italic")
	return weight, style
end

local function normalizeFont(rawOptions)
	assert(type(rawOptions) == "table", "Font options must be a table")
	local name = rawOptions.Name
	assert(
		type(name) == "string" and #name <= 100 and name:match("^[%w_-][%w_.-]*$") ~= nil,
		"Font Name must be a safe file name"
	)
	local weight, style = fontStyle(rawOptions.Weight, rawOptions.Style)
	local sources = rawOptions.Faces or { rawOptions }
	assert(
		type(sources) == "table" and #sources > 0 and #sources <= 18,
		"Font Faces must contain 1 through 18 faces"
	)
	local faces, seen = {}, {}
	local sourceCount = 0
	for index in pairs(sources) do
		assert(
			type(index) == "number" and index % 1 == 0 and index >= 1 and index <= #sources,
			"Font Faces must be an array"
		)
		sourceCount += 1
	end
	assert(sourceCount == #sources, "Font Faces must be a complete array")
	for index, source in ipairs(sources) do
		assert(type(source) == "table", "Each font face must be a table")
		local face = table.clone(source)
		face.Weight, face.Style = fontStyle(face.Weight, face.Style)
		local faceKey = tostring(face.Weight) .. ":" .. face.Style
		assert(not seen[faceKey], "Font faces must have distinct weights and styles")
		seen[faceKey] = true
		face.Name = face.Name
			or name:sub(1, 80) .. "-" .. tostring(face.Weight) .. "-" .. face.Style
		face.Version = face.Version or rawOptions.Version
		face.Kind = "font"
		faces[index] = normalize(face)
	end
	table.sort(
		faces,
		function(a, b)
			return if a.Weight == b.Weight then a.Style == "normal" and b.Style ~= "normal"
				else a.Weight < b.Weight
		end
	)
	local fields = { "font-family-v1", name, tostring(weight), style }
	for _, face in ipairs(faces) do
		table.insert(fields, requestIdentity(face))
		table.insert(fields, tostring(face.Weight))
		table.insert(fields, face.Style)
	end
	return {
		Name = name,
		Faces = faces,
		Weight = weight,
		Style = style,
		Identity = encodeIdentity(fields),
	}
end

function AssetCache.new(environment)
	local cache = {}
	local handles, fonts, pending, pendingFonts = {}, {}, {}, {}
	local needsDownload = {}
	local paths, claims = {}, {}
	local base = environment.Directory or "Ethos Suite/assets-v2"
	local foldersReady = false
	local stats = { downloads = 0, registrations = 0, cacheHits = 0 }

	local function readyFolders()
		if foldersReady and environment.isfolder(base) then
			return
		end
		local current = ""
		for part in string.gmatch(base, "[^/]+") do
			current = if current == "" then part else current .. "/" .. part
			if not environment.isfolder(current) then
				environment.makefolder(current)
			end
		end
		foldersReady = true
	end

	local function selectPath(identity, options)
		if paths[identity] ~= nil then
			return paths[identity]
		end
		local prefix = base .. "/" .. options.Name .. "-" .. checksum(identity)
		-- The short checksum groups files; it does not establish identity. A full
		-- identity sidecar and separate collision slots prevent native-path reuse.
		for slot = 0, 127 do
			local suffix = if slot == 0 then "" else "-" .. tostring(slot)
			local path = prefix .. suffix .. "." .. options.Extension
			if claims[path] == nil then
				local metadataPath = path .. ".meta"
				local hasMetadata = environment.isfile(metadataPath)
				local matches = false
				if hasMetadata then
					local ok, savedIdentity = pcall(environment.readfile, metadataPath)
					matches = ok and savedIdentity == identity
				end
				if matches or (not hasMetadata and not environment.isfile(path)) then
					claims[path] = identity
					paths[identity] = path
					return path
				end
			end
		end
		error("asset cache identity slots are exhausted")
	end

	function cache:IsSupported()
		return type(environment.isfile) == "function"
			and type(environment.readfile) == "function"
			and type(environment.writefile) == "function"
			and type(environment.isfolder) == "function"
			and type(environment.makefolder) == "function"
			and type(environment.getcustomasset) == "function"
	end

	function cache:Fetch(rawOptions)
		local validOptions, options = pcall(normalize, rawOptions)
		if not validOptions then
			return nil, tostring(options)
		end
		if not self:IsSupported() then
			return nil, "custom assets are unavailable in this environment"
		end
		local identity = requestIdentity(options)
		if handles[identity] then
			stats.cacheHits += 1
			return handles[identity], nil, paths[identity]
		end
		local active = pending[identity]
		if active and coroutine.status(active.thread) == "dead" then
			pending[identity] = nil
			active = nil
		end
		if active then
			local deadline = os.clock() + 30
			local heartbeat = game:GetService("RunService").Heartbeat
			while not active.complete
				and os.clock() < deadline
				and coroutine.status(active.thread) ~= "dead" do
				heartbeat:Wait()
			end
			if not active.complete and coroutine.status(active.thread) == "dead" then
				return self:Fetch(rawOptions)
			end
			if not active.complete then
				return nil, "asset download is still in progress"
			end
			return active.handle, active.error, active.path
		end
		active = { complete = false, thread = coroutine.running() }
		pending[identity] = active
		local ok, value = pcall(
			function()
				readyFolders()
				local path = selectPath(identity, options)
				active.path = path
				local metadataPath = path .. ".meta"
				local metadataReadOk, savedIdentity = pcall(environment.readfile, metadataPath)
				if not metadataReadOk or savedIdentity ~= identity then
					environment.writefile(metadataPath, identity)
				end
				assert(
					environment.readfile(metadataPath) == identity,
					"asset identity cache write was incomplete"
				)
				local cached = false
				if not needsDownload[identity] and environment.isfile(path) then
					local readOk, bytes = pcall(environment.readfile, path)
					cached = readOk and validate(bytes, options)
				end
				local function download()
					-- A failed write must not become an accepted cache hit on retry.
					needsDownload[identity] = true
					local bytes: string
					if type(environment.request) == "function" then
						local response = callInTask(
							environment.request,
							{
								Url = options.Url,
								Method = "GET",
								Timeout = environment.RequestTimeoutSeconds or 20,
							},
							environment.RequestTimeoutSeconds or 20,
							"asset HTTP request timed out"
						)
						assert(type(response) == "table", "HTTP request returned no response")
						local status = response.StatusCode or response.Status
						assert(
							type(status) == "number" and status >= 200 and status < 300,
							"asset HTTP request failed: " .. tostring(status)
						)
						bytes = response.Body
					else
						assert(
							type(environment.httpGet) == "function",
							"HTTP requests are unavailable"
						)
						bytes = callInTask(
							environment.httpGet,
							options.Url,
							environment.RequestTimeoutSeconds or 20,
							"asset HTTP request timed out"
						)
					end
					local accepted, message = validate(bytes, options)
					assert(accepted, "asset download " .. options.Name .. ": " .. tostring(message))
					environment.writefile(path, bytes)
					-- A partial or changed file can still pass the format checks.
					local written = environment.readfile(path)
					assert(
						written == bytes,
						"asset cache write " .. options.Name .. ": bytes do not match download"
					)
					stats.downloads += 1
					needsDownload[identity] = nil
				end
				local function register()
					local handle = callInTask(
						environment.getcustomasset,
						path,
						environment.RegistrationTimeoutSeconds or 20,
						"asset registration timed out"
					)
					assert(
						type(handle) == "string" and handle ~= "",
						"getcustomasset returned no content URI"
					)
					return handle
				end
				if not cached then
					download()
				end
				local registered, handle = pcall(register)
				if not registered and cached then
					-- Readable bytes are not proof that the executor can load this file.
					-- Replace only this asset, then make one more registration attempt.
					local firstError = tostring(handle)
					registered, handle = pcall(function()
						download()
						return register()
					end)
					if not registered then
						error(
							"asset registration failed: "
								.. firstError
								.. "; repair failed: "
								.. tostring(handle),
							0
						)
					end
				end
				assert(registered, handle)
				stats.registrations += 1
				return handle
			end
		)
		if ok then
			handles[identity] = value
			active.handle = value
		else
			active.error = tostring(value)
		end
		active.complete = true
		pending[identity] = nil
		return active.handle, active.error, active.path
	end

	function cache:CreateFont(rawOptions)
		local valid, options = pcall(normalizeFont, rawOptions)
		if not valid then
			return nil, tostring(options)
		end
		local key = options.Identity
		if fonts[key] then
			return fonts[key]
		end
		local active = pendingFonts[key]
		if active and coroutine.status(active.thread) == "dead" then
			pendingFonts[key] = nil
			active = nil
		end
		if active then
			local deadline = os.clock() + 30
			local heartbeat = game:GetService("RunService").Heartbeat
			while not active.complete
				and os.clock() < deadline
				and coroutine.status(active.thread) ~= "dead" do
				heartbeat:Wait()
			end
			if not active.complete and coroutine.status(active.thread) == "dead" then
				return self:CreateFont(rawOptions)
			end
			if not active.complete then
				return nil, "font family download is still in progress"
			end
			return active.font, active.error
		end
		active = { complete = false, thread = coroutine.running() }
		pendingFonts[key] = active
		local registrationStarted = false
		local function buildFamily()
			registrationStarted = false
			local faces = {}
			for index, face in ipairs(options.Faces) do
				local handle, message = self:Fetch(face)
				assert(handle, message)
				faces[index] = {
					name = face.Name,
					weight = face.Weight,
					style = face.Style,
					assetId = handle,
				}
			end
			local data = environment.jsonEncode({
				name = options.Name,
				loadStrategy = "sameFamilyOnly",
				faces = faces,
			})
			local familyPath = selectPath(key, { Name = options.Name, Extension = "json" })
			local metadataPath = familyPath .. ".meta"
			local metadataOk, metadata = pcall(environment.readfile, metadataPath)
			if not metadataOk or metadata ~= key then
				environment.writefile(metadataPath, key)
			end
			assert(
				environment.readfile(metadataPath) == key,
				"font family identity write was incomplete"
			)
			-- Registration URIs can change between executor sessions. Build this
			-- family from the current TTF handle, even when the TTF was cached.
			local familyReadOk, existingFamily = pcall(environment.readfile, familyPath)
			if not familyReadOk or existingFamily ~= data then
				environment.writefile(familyPath, data)
			end
			assert(
				environment.readfile(familyPath) == data,
				"font family cache write was incomplete"
			)
			registrationStarted = true
			local family = callInTask(
				environment.getcustomasset,
				familyPath,
				environment.RegistrationTimeoutSeconds or 20,
				"font family registration timed out"
			)
			assert(type(family) == "string" and family ~= "", "font family registration failed")
			local fontWeight = Enum.FontWeight.Regular
			for _, item in ipairs(Enum.FontWeight:GetEnumItems()) do
				if item.Value == options.Weight then
					fontWeight = item
					break
				end
			end
			stats.registrations += 1
			return Font.new(
				family,
				fontWeight,
				if options.Style == "italic" then Enum.FontStyle.Italic else Enum.FontStyle.Normal
			)
		end
		local success, result = pcall(buildFamily)
		if not success and registrationStarted then
			local firstError = tostring(result)
			-- Family registration or Font.new can reject a previously accepted face.
			-- Refresh every face once and rebuild JSON with the new session handles.
			for _, face in ipairs(options.Faces) do
				local identity = requestIdentity(face)
				handles[identity] = nil
				needsDownload[identity] = true
			end
			success, result = pcall(buildFamily)
			if not success then
				result = "font family registration failed: "
					.. firstError
					.. "; repair failed: "
					.. tostring(result)
			end
		end
		if success then
			fonts[key] = result
			active.font = result
		else
			active.error = tostring(result)
		end
		active.complete = true
		pendingFonts[key] = nil
		return active.font, active.error
	end

	function cache:GetStats()
		return table.clone(stats)
	end

	return cache
end

return table.freeze(AssetCache)
