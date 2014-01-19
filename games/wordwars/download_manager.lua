---------------------------------------------------------------------------------------------------
-- This is a class to manage the Downloads.
---------------------------------------------------------------------------------------------------

local Logger = require("hp/util/Logger")

local M = {}
local cache = {}

setmetatable(cache, {__mode = "v"})

function M:request(path)
	
    if cache[path] == nil then
        local file_path = 
        cache[path] = file_path
        
    end
    
    local file_path = cache[path]
    return cache[path]
end

return M
