module(..., package.seeall)

local M = {}
M.data = {}

function M:getPath()
	return MOAIEnvironment.documentDirectory .. "/" .. "settings.lua"
end

function M:load()
	if (MOAIFileSystem.checkFileExists(self:getPath()) == false) then
		self.data = {
			balance = 20
		}
		self:save()
		return
	end
	print("Loading settings " .. self:getPath())
	self.data = dofile ( self:getPath() )
	print("username " .. self:get("username"))
end

function M:save()
	local serializer = MOAISerializer.new ()
	serializer:serialize ( self.data )
	serialized_data = serializer:exportToString ()

	file = io.open ( self:getPath() , 'w' )
	file:write ( serialized_data )
	file:close ()
end

function M:set(key, value)
	self.data[key] = value
end

function M:get(key)
	if key == "balance" and self.data[key] == nil then
		return 10
	end
	return self.data[key]
end

return M