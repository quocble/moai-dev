-- import
local modules = require "modules"
local config = require "config"

function onBackButtonPressed ()
	print ( "onBackButtonPressed: " )
	return false
end

print ("HELLO!!!!!!! ")
MOAIApp.setListener ( MOAIApp.BACK_BUTTON_PRESSED, onBackButtonPressed )


-- start and open
Application:start(config)

Settings:load()
SoundManager:enableSound(Settings:get("sound"))
SoundManager:enableMusic(Settings:get("music"))

if Settings:get("login") and Settings:get("user_id") and Settings:get("secret") then
    print("Previously authenticated")
	SceneManager:openScene("menu_scene")
else 
	SceneManager:openScene(config.mainScene)
end