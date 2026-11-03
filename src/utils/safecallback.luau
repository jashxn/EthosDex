local CallbackBatch = require(script.Parent.callbackBatch)

return function(callback: () -> ...any, key: string?): (boolean, ...any)
	return CallbackBatch.invoke(callback, key)
end
