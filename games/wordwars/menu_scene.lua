module(..., package.seeall)

local GAME_WIDTH = Application.viewWidth
local GAME_HEIGHT = Application.viewHeight

websocket = "WWWWWW"

function onStartClick()
    SceneManager:openScene("game_scene", { websocket = "X"})
end

function onCreate(params)
    layer = Layer {scene = scene}
    local floor = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {"#CB44F3", "#8FC7CB", 90})
    floor:setLayer(layer)

    local w, h = 526/2, 146/2

    sprite1 = Sprite {
        texture = "./assets/game_title.png", 
        layer = layer,
        size = { w , h } ,
        pos = { (GAME_WIDTH - w) / 2 , 80 }
    }    

    -- anim2 = Animation():loop(0, 
    --     Animation({sprite1}, 0.80, MOAIEaseType.SMOOTH):moveLoc(10, 0, 0):moveLoc(-10, 0, 0))
    -- anim2:play()

    view = View {
        scene = scene,
        pos = {0, 50},
        layout = {
            VBoxLayout {
                align = {"center", "center"},
                padding = {10, 10, 10, 30},
            }
        },
        children = {{
            Button {
                name = "startButton",
                text = "Play",
                onClick = onStartClick,
                size = { 175, 55}
            },
            Button {
                name = "backButton",
                text = "Invite",
                onClick = onBackClick,
                size = { 175, 55}
            },
            Button {
                name = "testButton1",
                text = "Help",
                size = { 175, 55}
            },
        }},
    }

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

function onTouchDown(event)
    print("onTouchDown(event)")
end

function onTouchUp(event)
    print("onTouchUp(event)")
end

function onTouchMove(event)
    print("onTouchMove(event)")
end
