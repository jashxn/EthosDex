-- keybindDispatcher.luau: the single owner of keybind input dispatch.
--
-- Previously this lived inside packages/states/init.lua, which made the shared
-- reactive store also a UserInputService listener and forced the server's
-- require graph to touch a client-only service. This module owns:
--   * the key-match rules (isKeyMatch / normalizeInputToKey) -- one copy,
--   * the batched UserInputService listener that dispatches to registered
--     handlers, and
--   * the keybind CRUD (addKeybind / removeKeybind / updateKeybind).
-- The reactive Keybinds / ActiveKeybinds Values stay in States; the dispatcher
-- mutates them. Only client-side modules require this dispatcher.

local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local States = require(Root.packages.states)

local services = require(Root.packages.services)
local safeCallback = require(Root.utils.safecallback)
local UserInputService = services.UserInputService

local peek = Fusion.peek

local Dispatcher = {}

-- < Key-match rules (single canonical copy) >

function Dispatcher.isKeyMatch(input: InputObject, key: string)
	LPH_ATTRIBUTES(VM(NONE), PRESET(FAST), ERROR_HANDLING(false))
	if key == "None" then
		return false
	end
	if key == "MouseLeft" then
		return input.UserInputType == Enum.UserInputType.MouseButton1
	end
	if key == "MouseRight" then
		return input.UserInputType == Enum.UserInputType.MouseButton2
	end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return input.KeyCode.Name == key
	end
	return false
end

function Dispatcher.normalizeInputToKey(input: InputObject): string?
	LPH_ATTRIBUTES(VM(NONE), PRESET(FAST), ERROR_HANDLING(false))
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return input.KeyCode.Name
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		return "MouseLeft"
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		return "MouseRight"
	end
	return nil
end

-- < Batched keybind listener system >
-- Instead of each keybind creating its own InputBegan connection, a single
-- global listener dispatches to registered handlers.

local _keybindHandlers = {}
local _listenerActive = false
local _inputBeganConnection = nil
local _inputEndedConnection = nil
local _focusReleasedConnection = nil
local _textBoxFocusedConnection = nil
local _capture = nil
local _activeInputs = {}
local _capturedInputs = setmetatable({}, { __mode = "k" })

local function releaseActiveInputs()
	local activeInputs = _activeInputs
	_activeInputs = {}
	for id, input in pairs(activeInputs) do
		local handler = _keybindHandlers[id]
		if handler and handler.onInputEnded then
			safeCallback(function()
				handler.onInputEnded(input)
			end)
		end
	end
end

local function disconnectListeners()
	if _inputBeganConnection then
		_inputBeganConnection:Disconnect()
		_inputBeganConnection = nil
	end
	if _inputEndedConnection then
		_inputEndedConnection:Disconnect()
		_inputEndedConnection = nil
	end
	if _focusReleasedConnection then
		_focusReleasedConnection:Disconnect()
		_focusReleasedConnection = nil
	end
	if _textBoxFocusedConnection then
		_textBoxFocusedConnection:Disconnect()
		_textBoxFocusedConnection = nil
	end
	_listenerActive = false
end

local function handleInputBegan(input, gameProcessed)
	LPH_ATTRIBUTES(VM(NONE), PRESET(FAST), ERROR_HANDLING(false))
	if _capture then
		_capturedInputs[input] = true
		return
	end
	if gameProcessed then
		return
	end

	-- Skip if user is typing in a text box
	if UserInputService:GetFocusedTextBox() then
		return
	end

	for id, handler in pairs(_keybindHandlers) do
		if _capture then
			_capturedInputs[input] = true
			return
		end
		local keybindData = peek(States.Keybinds)[id]
		if keybindData and Dispatcher.isKeyMatch(input, keybindData.key) then
			_activeInputs[id] = input
			if handler.onInputBegan then
				safeCallback(function()
					handler.onInputBegan(input)
				end)
			end
		end
	end
end

local function handleInputEnded(input, _gameProcessed)
	LPH_ATTRIBUTES(VM(NONE), PRESET(FAST), ERROR_HANDLING(false))
	if _capture or _capturedInputs[input] then
		-- Keep the release marked until all listeners have seen it. A picker can
		-- finish before the window's separate minimize listener runs.
		local capturedInputs = _capturedInputs
		capturedInputs[input] = true
		task.defer(function()
			capturedInputs[input] = nil
		end)
		return
	end

	-- A processed release must still end a hold that began in this dispatcher.
	local releasedKey = Dispatcher.normalizeInputToKey(input)
	for id, startedInput in pairs(_activeInputs) do
		if releasedKey and Dispatcher.isKeyMatch(startedInput, releasedKey) then
			_activeInputs[id] = nil
			local handler = _keybindHandlers[id]
			if handler and handler.onInputEnded then
				safeCallback(function()
					handler.onInputEnded(input)
				end)
			end
		end
	end
end

local function ensureListenerActive()
	if _listenerActive then
		return
	end

	_listenerActive = true
	_inputBeganConnection = UserInputService.InputBegan:Connect(handleInputBegan)
	_inputEndedConnection = UserInputService.InputEnded:Connect(handleInputEnded)
	_focusReleasedConnection = UserInputService.WindowFocusReleased:Connect(function()
		Dispatcher.cancelCapture("focus lost")
		releaseActiveInputs()
	end)
	_textBoxFocusedConnection = UserInputService.TextBoxFocused:Connect(function()
		Dispatcher.cancelCapture("text input focused")
		releaseActiveInputs()
	end)
end

-- A capture owns input until its UI releases it. Only one picker can own it.
function Dispatcher.beginCapture(owner, onCancel)
	assert(owner ~= nil, "keybind capture needs an owner")
	assert(type(onCancel) == "function", "keybind capture needs a cancel callback")
	if _capture then
		return false
	end
	_capture = { owner = owner, onCancel = onCancel }
	ensureListenerActive()
	releaseActiveInputs()
	return true
end

function Dispatcher.endCapture(owner)
	if not _capture or _capture.owner ~= owner then
		return false
	end
	_capture = nil
	if next(_keybindHandlers) == nil then
		disconnectListeners()
	end
	return true
end

function Dispatcher.cancelCapture(reason)
	local capture = _capture
	if not capture then
		return false
	end
	_capture = nil
	safeCallback(function()
		capture.onCancel(reason)
	end)
	if not _capture and next(_keybindHandlers) == nil then
		disconnectListeners()
	end
	return true
end

function Dispatcher.isCapturing()
	return _capture ~= nil
end

function Dispatcher.isInputCaptured(input)
	return _capture ~= nil or _capturedInputs[input] == true
end

-- < Keybind CRUD >

function Dispatcher.addKeybind(id, key, feature)
	local currentKeybinds = peek(States.Keybinds)
	local newKeybinds = table.clone(currentKeybinds)
	newKeybinds[id] = {
		key = key,
		feature = feature,
	}
	States.Keybinds:set(newKeybinds)
end

function Dispatcher.removeKeybind(id)
	_activeInputs[id] = nil
	local currentKeybinds = peek(States.Keybinds)
	local newKeybinds = table.clone(currentKeybinds)
	newKeybinds[id] = nil
	States.Keybinds:set(newKeybinds)
end

function Dispatcher.updateKeybind(id, key, feature)
	if key == nil and feature == nil then
		Dispatcher.removeKeybind(id)
	else
		local currentKeybinds = peek(States.Keybinds)
		local newKeybinds = table.clone(currentKeybinds)
		if newKeybinds[id] then
			newKeybinds[id].key = key or newKeybinds[id].key
			newKeybinds[id].feature = feature or newKeybinds[id].feature
		else
			newKeybinds[id] = {
				key = key or "None",
				feature = feature or "Unknown",
			}
		end
		States.Keybinds:set(newKeybinds)
	end
end

function Dispatcher.registerKeybindHandler(id, handlers)
	-- handlers = { onInputBegan = fn, onInputEnded = fn }
	_keybindHandlers[id] = handlers
	ensureListenerActive()
end

function Dispatcher.unregisterKeybindHandler(id)
	_activeInputs[id] = nil
	_keybindHandlers[id] = nil

	-- If no more handlers, disconnect the global listener to save resources
	if not _capture and next(_keybindHandlers) == nil then
		disconnectListeners()
	end
end

function Dispatcher.cleanup()
	Dispatcher.cancelCapture("dispatcher cleanup")
	releaseActiveInputs()
	disconnectListeners()
	_keybindHandlers = {}
	_capturedInputs = setmetatable({}, { __mode = "k" })
	States.Keybinds:set({})
	States.ActiveKeybinds:set({})
end

return Dispatcher
