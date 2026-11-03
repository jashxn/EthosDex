local service = setmetatable(
	{},
	{
		__index = function(self, serviceName)
			local o, s = pcall(Instance.new, serviceName)
			local Service = o and s
				or game:GetService(serviceName)
				or settings():GetService(serviceName)
				or UserSettings():GetService(serviceName)

			if cloneref then
				Service = cloneref(Service)
			end
			if Service then
				self[serviceName] = Service
			end
			return Service
		end,
	}
)
return service
