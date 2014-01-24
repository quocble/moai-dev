module(..., package.seeall)

local string = require("hp/lang/string")
local GAME_WIDTH = Application.viewWidth
local GAME_HEIGHT = Application.viewHeight

local A_BUTTON_STYLES = {
    normal = {
        skin = "./assets/main_btn.png",
        skinColor = {1, 1, 1, 1.0},
    },
    selected = {
        skin = "./assets/main_btn.png",
        skinColor = {0.5, 0.5, 0.5, 0.8},
    },
    over = {
        skin = "./assets/main_btn.png",
        skinColor = {0.5, 0.5, 0.5, 0.8},
    },
    disabled = {
        skin = "./assets/main_btn.png",
    },
}

local SHOP_BUTTON_STYLES = {
    normal = {
        skin = "./assets/shop_btn.png",
        skinColor = {1, 1, 1, 1.0},
        textColor = {1, 1, 1, 1.0},
    },
    selected = {
        skin = "./assets/shop_btn.png",
        skinColor = {0.5, 0.5, 0.5, 0.8},
    },
    over = {
        skin = "./assets/shop_btn.png",
        skinColor = {0.5, 0.5, 0.5, 0.8},
    },
    disabled = {
        skin = "./assets/shop_btn.png",
    },
}

local filterMesh = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, "#000000")

function onStartClick()
    buttonSound:play()
    SceneManager:openScene("wait_queue_scene", { websocket = "X" , animation = "crossFade"}  )
end

function onShopBackClick()
    if store_panel then
        buttonSound:play()        
        view:removeChild(store_panel)
        store_panel = nil
        shopDisplayed = false
        view:removeChild(filterMesh)
    end
end

function onShopClick()
    print("Store clicked")
    if not shopDisplayed then
        buttonSound:play()
        store_panel = StoreManager:getPanel(onShopBackClick)
        filterMesh:setParent(view)
        store_panel:setParent(view)
        store_panel:setCenterPos(GAME_WIDTH/2, GAME_HEIGHT/2)
        filterMesh:setAlpha(0.50)

        Animation({ store_panel }):fadeIn(0.5):play()
        shopDisplayed = true
    end
end

function onCreate(params)
    layer = Layer {scene = scene}
    local floor = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {"#CB44F3", "#8FC7CB", 90})
    floor:setLayer(layer)

    local w, h = 526/2, 146/2

    sprite1 = Sprite {
        texture = "./assets/menu_bg.png", 
        layer = layer,
        size = { GAME_WIDTH , GAME_HEIGHT } ,
        pos = { 0, 0 }
    }    

    sprite1 = Sprite {
        texture = "./assets/game_title.png", 
        layer = layer,
        size = { w , h } ,
        pos = { (GAME_WIDTH - w) / 2 , 70 }
    }    

    view = View {
        scene = scene,
        pos = {0, 0}
    }

    playButton = Button {
        name = "startButton",
        text = "Play",
        onClick = onStartClick,
        size = { 155, 45},
        styles = { A_BUTTON_STYLES },
        parent = view,
    }

    playButton:setCenterPos(GAME_WIDTH/2, GAME_HEIGHT/2)

    scoreButton = Button {
        name = "startButton",
        onClick = onShopClick,
        size = { 226/2, 53/2},
        styles = { SHOP_BUTTON_STYLES },
        parent = view,
        pos = { GAME_WIDTH - (226/2) - 20, 10 },
        text = "",
    }

    balanceLabel = TextLabel {
        text = "100",
        size = { 226/2, 53/2},
        parent = view,
        color = string.hexToRGB( "#FFFFFF", true ),
        pos = { GAME_WIDTH - (226/2) - 50, 10 },
        textSize = 13,
        align = {"right", "center"}
    }


    playButton:setCenterPiv()
    anim2 = Animation():loop(0, 
        Animation({ playButton }):seekScl(1.08, 1.08, 1, 1.0, MOAIEaseType.SOFT_SMOOTH):wait(0.10):seekScl(1, 1, 1, 1.0, MOAIEaseType.SOFT_SMOOTH))
    anim2:play()

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
end
