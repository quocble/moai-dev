----------------------------------------------------------------
-- This is a class to manage the MOAIUntzSound.
----------------------------------------------------------------

local ResourceManager = require("hp/manager/ResourceManager")

local M = {}
local cache = {}

M.initialized = false

function M:initialize()
    if not self.initialized then
        MOAIUntzSystem.initialize()
        self.initialized = true
        self.enable_sound = true
        self.enable_music = true
    end
end

function M:enableSound(enable)
    print("set sound to = ", enable)
    self.enable_sound = enable
end

function M:enableMusic(enable) 
    self.enable_music = enable
end

function M:isSoundEnabled()
    return self.enable_sound
end

function M:isMusicEnabled() 
    return self.enable_music
end

function M:play(sound)
    print("play sound ", self.enable_sound)    
    if self.enable_sound then
        sound:play()
    end
end

----------------------------------------------------------------
-- Returns the untz sound. <br>
-- @param path path
-- @param volume volume
-- @param looping looping
-- @return MOAIUntzSound instance.
----------------------------------------------------------------
function M:getSound(path, volume, looping)
    if not self.initialized then
        self:initialize()
    end
    
    path = ResourceManager:getFilePath(path)

    if cache[path] == nil then
        local sound = MOAIUntzSound.new()
        sound:load(path)
        sound:setVolume(1)
        sound:setLooping(false)
        cache[path] = sound
    end
    
    local sound = cache[path]
    if volume then
        sound:setVolume(volume)
    end
    if looping then
        sound:setLooping(looping)
    end
    return sound
end

return M