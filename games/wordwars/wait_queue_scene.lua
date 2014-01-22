module(..., package.seeall)

string = require("hp/lang/string")

local GAME_WIDTH = Application.viewWidth
local GAME_HEIGHT = Application.viewHeight
local LISTENER = {}
local playerViews = {}
local allPlayers = {}
local A_BUTTON_STYLES = {
    normal = {
        skin = "./assets/btn_down.png",
        skinColor = {1, 1, 1, 1.0},
        textSize = 12
    },
    selected = {
        skin = "./assets/btn_down.png",
        skinColor = {0.5, 0.5, 0.5, 0.8},
    },
    over = {
        skin = "./assets/btn_down.png",
        skinColor = {0.5, 0.5, 0.5, 0.8},
    },
    disabled = {
        skin = "./assets/btn_down.png",
    },
}

-----------------------------------------------------------------------------------

function LISTENER.onConnected(msg)
    print("connected to me")
    GameService:queueGame()    
end

function LISTENER.onMessageReceived(msg)
    response = MOAIJsonParser.decode ( msg )
    if response["msgtype"] == 'player_join' then
        updatePlayers(response["player"])
    elseif response["msgtype"] == 'new' then 
        startGame(response)
    end
end

function LISTENER.onClosed(msg)
end

function LISTENER.onFailed(msg)
end

-----------------------------------------------------------------------------------
function onBackClick()
    buttonSound:play()
    SceneManager:closeScene()
end

function onCreate(params)
    layer = Layer {scene = scene}
    local floor = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {"#CB44F3", "#8FC7CB", 90})
    floor:setLayer(layer)
    print ("obj ", self)

    makeNavigationBar()
    makePlaceholders()
    
    GameService:addListener(LISTENER)
    GameService:start()
end

function makeNavigationBar()
    guiView = View {
        scene = scene,
        size = { GAME_WIDTH, 60}
    }

    local floor = Mesh.newRect(0, 0, GAME_WIDTH, 60, "#555C60")
    floor:setLayer(layer)

    backButton = Button {
        text = "Back",
        size = {60, 35},
        pos = { 10, 18 },
        parent = guiView,
        onClick = onBackClick,
        styles = { A_BUTTON_STYLES }
    }    
    titleLabel = TextLabel {
        text = "Finding Players",
        size = {GAME_WIDTH, 40},
        pos = { 0, 15 },
        layer = layer,
        color = string.hexToRGB( "#f7f7f7", true ),
        align = {"center", "center"},
        textSize = 18
    }

end

function makePlaceholders()

    local cell_w, cell_h = GAME_WIDTH / 2 , GAME_WIDTH /2 

    for n=0, 3 do
        c = n % 2
        r = math.floor(n / 2)        
        local player_group = Group { 
            pos = { c * cell_w , 130 + (r * cell_h) },
            size = {cell_w, cell_h},
            align = {"center", "center"},
            layer = layer
        }

        local player_image = MaskSprite {
            size  = { 75, 75 },
            parent = player_group,
            pos = { (cell_w-75)/2 , (cell_w-75)/2},
            mask = "./assets/mask_img.png",
            main = "./assets/mask_img.png",
            border = "./assets/border_img.png"
        }

        local player_name = TextLabel {
            text = "?",
            size = {cell_w, 40},
            parent = player_group,
            color = string.hexToRGB( "#000000", true ),
            pos = {0, player_image:getBottom() + 0 },
            textSize = 13,
            align = {"center", "center"}
        }

        player_group.image = player_image
        player_group.name = player_name
        player_group:setVisible(false)

        table.insert(playerViews, player_group)
    end
end

function updatePlayers(players)
    print("updating players " .. #players)    
    count = #allPlayers
    for i, player in ipairs(players) do
        table.insert(allPlayers, player)

        DownloadManager:request(player.profile_img, function(filePath)
            playerViews[count+i].image:setTexture(filePath, "main")
            playerViews[count+i].name:setText(player.player_name)
            Animation({playerViews[count+i]}):setVisible(true):fadeIn():play()
        end)
    end

end

function startGame(response)
    SceneManager:openScene("game_scene", { game = response , animation = "popIn"})    
end

function onStart()
    print("onStart()")
end

function onResume()
    print("onResume()")
end

function onPause()
    print("onPause()")
end

function onStop()
    print("onStop()")
end

function onDestroy()
    print("onDestroy()")
    GameService:leaveGameAndQueue()
    GameService:removeListener(self)    
end

function onTouchDown(event)
    print("onTouchDown(event)")
end

function onTouchUp(event)
    print("onTouchUp(event)")
end

function onTouchMove(event)
    print("onTouchMove(event)")
end

