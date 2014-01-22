Application             = require "hp/core/Application"
Layer                   = require "hp/display/Layer"
Sprite                  = require "hp/display/Sprite"
SpriteSheet             = require "hp/display/SpriteSheet"
MapSprite               = require "hp/display/MapSprite"
BackgroundSprite        = require "hp/display/BackgroundSprite"
Graphics                = require "hp/display/Graphics"
Group                   = require "hp/display/Group"
TextLabel               = require "hp/display/TextLabel"
NinePatch               = require "hp/display/NinePatch"
Mesh                    = require "hp/display/Mesh"
Animation               = require "hp/display/Animation"
Particles               = require "hp/display/Particles"
View                    = require "hp/gui/View"
Button                  = require "hp/gui/Button"
Joystick                = require "hp/gui/Joystick"
Panel                   = require "hp/gui/Panel"
MessageBox              = require "hp/gui/MessageBox"
DialogBox               = require "hp/gui/DialogBox"
Scroller                = require "hp/gui/Scroller"
Slider                  = require "hp/gui/Slider"
BoxLayout               = require "hp/layout/BoxLayout"
VBoxLayout              = require "hp/layout/VBoxLayout"
HBoxLayout              = require "hp/layout/HBoxLayout"
SceneManager            = require "hp/manager/SceneManager"
InputManager            = require "hp/manager/InputManager"
ResourceManager         = require "hp/manager/ResourceManager"
TextureManager          = require "hp/manager/TextureManager"
FontManager             = require "hp/manager/FontManager"
ShaderManager           = require "hp/manager/ShaderManager"
SoundManager            = require "hp/manager/SoundManager"
PhysicsWorld            = require "hp/physics/PhysicsWorld"
PhysicsBody             = require "hp/physics/PhysicsBody"
PhysicsFixture          = require "hp/physics/PhysicsFixture"
TMXLayer                = require "hp/tmx/TMXLayer"
TMXMap                  = require "hp/tmx/TMXMap"
TMXMapLoader            = require "hp/tmx/TMXMapLoader"
TMXMapView              = require "hp/tmx/TMXMapView"
TMXObject               = require "hp/tmx/TMXObject"
TMXObjectGroup          = require "hp/tmx/TMXObjectGroup"
TMXTileset              = require "hp/tmx/TMXTileset"
GameService				= require "game_service"
DownloadManager			= require "download_manager"
MaskSprite				= require "widgets/MaskSprite"

return _G -- Dummy module