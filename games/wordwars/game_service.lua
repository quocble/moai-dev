local array = require "hp/lang/array"
local table = require("hp/lang/table")
local class = require("hp/lang/class")

local M = class()
local listeners = {}
local ws = nil
local Listener = {}
local isConnected = false

SERVER = "192.168.1.115:8888"

function Listener.onConnected(msg)
	print("Websocket connected.")
	isConnected = true;
	M:auth()
	for i,obj in ipairs(listeners) do
		obj.onConnected()
	end
end

function Listener.onMessageReceived(msg)
	if msg ~= nil then
		-- print("Websocket received. " .. msg)
	end
	for i,obj in ipairs(listeners) do
		obj.onMessageReceived(msg)
	end	
end

function Listener.onClosed(msg)
	print("Websocket closed.")
	isConnected = false;

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
	    ws:start("ws://" .. SERVER .. "/ws")
	    print("Opening web socket")
    end
end

function M:isConnected()
	return isConnected
end

function M:write(msg)
	ws:write(msg)
end

function M:addListener(obj)
	table.insertElement(listeners, obj)
end

function M:removeListener(obj)
	table.removeElement(listeners, obj)	
end

function M:auth()
	print("Auth game")
    local send_word_to_server = { msgtype = "auth", user_id = Settings:get("user_id"), secret = Settings:get("secret")}
    msg = MOAIJsonParser.encode ( send_word_to_server )
    ws:write(msg)
end

function M:queueGame()
	print("Queue game")
    local send_word_to_server = { msgtype = "queue" }
    msg = MOAIJsonParser.encode ( send_word_to_server )
    ws:write(msg)
end

function M:leaveGameAndQueue()
	print("Leave game and queue")
    local send_word_to_server = { msgtype = "leave" }
    msg = MOAIJsonParser.encode ( send_word_to_server )
    ws:write(msg)
end

function M:loginWithFacebook(token, callback)

	local function onLoginFinish ( task, responseCode )
	    print ( "login finished " .. responseCode )

	    if ( task:getSize ()) then
	        print ( task:getString ())
	        local data = MOAIJsonParser.decode ( task:getString ())
	        callback(data)
	    else
	        print ( "nothing" )
	    end
	end

	local auth_url = "http://" .. SERVER .. "/login/fb"
	task = MOAIHttpTask.new ()
	task:setVerb ( MOAIHttpTask.HTTP_POST )
	task:setUrl ( auth_url )
	task:setBody ( MOAIJsonParser.encode ( { access_token = token } ) )
	task:setCallback ( onLoginFinish )
	task:setUserAgent ( "Moai" )
	task:performAsync ()
end

function M:loginWithUsername(user, pass, callback)

	local function onLoginFinish ( task, responseCode )
	    print ( "login finished " .. responseCode )

	    if ( task:getSize ()) then
	        print ( task:getString ())
	        local data = MOAIJsonParser.decode ( task:getString ())
	        callback(data)
	    else
	        print ( "nothing" )
	    end
	end

	local auth_url = "http://" .. SERVER .. "/login/user"
	task = MOAIHttpTask.new ()
	task:setVerb ( MOAIHttpTask.HTTP_POST )
	task:setUrl ( auth_url )
	task:setBody ( MOAIJsonParser.encode ( { user = user, pass = pass } ) )
	task:setCallback ( onLoginFinish )
	task:setUserAgent ( "Moai" )
	task:performAsync ()
end

return M