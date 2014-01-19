local array = require "hp/lang/array"
local table = require("hp/lang/table")
local class = require("hp/lang/class")

local M = class()
local listeners = {}
local ws = nil
local Listener = {}

function Listener.onConnected(msg)
	print("Websocket connected.")
	for i,obj in ipairs(listeners) do
		obj.onConnected()
	end
end

function Listener.onMessageReceived(msg)
	if msg ~= nil then
		print("Websocket received. " .. msg)
	end
	for i,obj in ipairs(listeners) do
		obj.onMessageReceived(msg)
	end	
end

function Listener.onClosed(msg)
	print("Websocket closed.")
	for i,obj in ipairs(listeners) do
		obj.onClosed()
	end	
end

function Listener.onFailed(msg)
	print("Websocket failed.")
	for i,obj in ipairs(listeners) do
		obj.onFailed()
	end	
end

function M:start()
	if ws == nil then
	    ws = MOAIWebSocket.new()
    	ws:setListener ( MOAIWebSocket.ON_MESSAGE, Listener.onMessageReceived )
    	ws:setListener ( MOAIWebSocket.ON_CONNECT, Listener.onConnected )
    	ws:setListener ( MOAIWebSocket.ON_CLOSE, Listener.onClosed )
    	ws:setListener ( MOAIWebSocket.ON_FAIL, Listener.onFailed )
	    ws:start("ws://10.0.0.10:8888/ws")
	    print("Opening web socket")
    end
end

function M:addListener(obj)
	table.insertElement(listeners, obj)
end

function M:removeListener(obj)
	table.removeElement(listeners, obj)	
end

function M:queueGame()
	print("Queue game")
    local send_word_to_server = { msgtype = "queue" }
    msg = MOAIJsonParser.encode ( send_word_to_server )
    ws:write(msg)
end


return M