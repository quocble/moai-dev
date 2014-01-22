---------------------------------------------------------------------------------------------------
-- This is a class to manage the Downloads.
---------------------------------------------------------------------------------------------------

local Logger = require("hp/util/Logger")

local M = {}
local cache = {}

setmetatable(cache, {__mode = "v"})

function fetch( url , onComplete)
        local result = nil
        local task = MOAIHttpTask.new ()
        task:setVerb ( MOAIHttpTask.HTTP_GET )
        task:setUrl ( url )
        task:setUserAgent ( "Moai" )
        task:setVerbose ( true )
        task:setCallback ( function( task, responseCode )
                print ( responseCode )
                result = task:getString()
                onComplete(result)
        end)
		task:performAsync ()
        return result
end

function M:request(path, onResponse)
	
	--print("request " .. path)
	
    if cache[path] == nil then
    	function onComplete(result) 
	        local file_path = MOAIEnvironment.documentDirectory .. "/" .. MOAIEnvironment.generateGUID ()

	        --print("save to " .. file_path)

			file = io.open ( file_path, 'wb' )
			file:write ( result )
			file:close ()    		

        	cache[path] = file_path    			
	    	onResponse(cache[path])
    	end

    	fetch( path , onComplete )
    else    
    	local file_path = cache[path]
    	onResponse(cache[path])
    end
end

return M
