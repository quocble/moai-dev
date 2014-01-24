module(..., package.seeall)

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

function onStartClick()
    buttonSound:play()
    SceneManager:openScene("wait_queue_scene", { websocket = "X" , animation = "crossFade"}  )
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
        pos = { (GAME_WIDTH - w) / 2 , 50 }
    }    

    playButton = Button {
        name = "startButton",
        text = "Play",
        onClick = onStartClick,
        size = { 155, 45},
        styles = { A_BUTTON_STYLES }
    }

    view = View {
        scene = scene,
        pos = {0, -50},
        layout = {
            VBoxLayout {
                align = {"center", "center"},
                padding = {0, 0, 0, 0},
            }
        },
        children = {{
            playButton,
            -- Button {
            --     name = "backButton",
            --     text = "Invite",
            --     onClick = onBackClick,
            --     size = { 175, 55}
            -- },
            -- Button {
            --     name = "testButton1",
            --     text = "Help",
            --     size = { 175, 55}
            -- },
        }},
    }

    playButton:setCenterPiv()
    anim2 = Animation():loop(0, 
        Animation({ playButton }):seekScl(1.02, 1.02, 1, 1.5, MOAIEaseType.SOFT_SMOOTH):wait(0.25):seekScl(1, 1, 1, 1.5, MOAIEaseType.SOFT_SMOOTH))
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
