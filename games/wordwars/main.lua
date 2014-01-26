-- import
local modules = require "modules"
local config = require "config"

-- start and open
Application:start(config)

if Settings:get("user_id") and Settings:get("secret") then
    print("Previously authenticated")
	SceneManager:openScene("menu_scene")
else 
	SceneManager:openScene(config.mainScene)
end