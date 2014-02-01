module(..., package.seeall)

local string = require("hp/lang/string")
local GAME_WIDTH = Application.viewWidth
local GAME_HEIGHT = Application.viewHeight
local settings_shown = false


function onStartClick()
    buttonSound:play()
    SceneManager:openScene("wait_queue_scene", { animation = "slideToLeft"}  )
end

function onShopBackClick()
    if store_panel then
        buttonSound:play()        
        --view:removeChild(store_panel)
        store_panel:setParent(nil)
        filterMesh:setParent(nil)
        store_panel = nil
        shopDisplayed = false
    end
end

function onLogout()
    print("onLogout()")
    SceneManager:openScene("login_scene", { currentClosing = true })
end

function onMusicToggle(e)
    local enable = not e.target:isSelected()
    SoundManager:enableMusic(enable)
    Settings:set("music", enable)
    Settings:save()
end

function onSoundToggle(e)
    local enable = not e.target:isSelected()
    print("set sound to = ", enable)
    SoundManager:enableSound(enable)
    Settings:set("sound", enable)
    Settings:save()
end

function onHelp()
end

function onPurchased()
    updateBalance()            
end

function onShopClick()
    print("Store clicked")
    if not shopDisplayed then
        buttonSound:play()
        store_panel = StoreManager:getPanel(onShopBackClick, onPurchased)
        filterMesh:setParent(view)
        store_panel:setParent(view)
        store_panel:setCenterPos(GAME_WIDTH/2, GAME_HEIGHT/2)

        Animation({ store_panel }):fadeIn(0.5):play()
        shopDisplayed = true
    end
end

function showSettings()
    if view_settings then
        return
    end

    view_settings = View {
        scene = scene,
        pos = {0, -90}
    }

    filterMesh:setParent(view)

    sprite1 = Sprite {
        texture = "./assets/setting_bg.png", 
        parent = view_settings,
        size = { 320 , 90 } ,
        pos = { 0, 0 }
    } 

    buttons = { 
        { skin = "./assets/help_icon.png", click = onHelp , toggle = false},
        { skin = "./assets/sound_icon.png", click = onSoundToggle  ,toggle = true , state = Settings:get("sound") },
        { skin = "./assets/music_icon.png", click = onMusicToggle , toggle = true  , state = Settings:get("music")},
        { skin = "./assets/logout_icon.png", click = onLogout , toggle = false},
    }
    local button_holder = {}

    for i=1, #buttons do
        local setting_btn = Button {
            name = "setting_button",
            text = "",
            onClick = buttons[i].click,
            size = { GAME_WIDTH / 4 , 90 },
            pos = { (GAME_WIDTH/4) * (i-1) , 0 },
            styles = { ThemeManager:getTheme():buttonStyle(buttons[i].skin) },
            parent = view_settings,
            skinResizable = false,            
            toggle = buttons[i].toggle
        }
        if buttons[i].toggle then
            setting_btn:setOnButtonUp(buttons[i].click)
            setting_btn:setOnButtonDown(buttons[i].click)
            setting_btn:setSelected(not buttons[i].state)
        end

        table.insert(button_holder, setting_btn)
        setting_btn:setVisible(false)
        setting_btn:setCenterPiv()        
    end   

    anim2 = Animation({ view_settings }):seekLoc(0, 0, 0, 0.25, MOAIEaseType.SOFT_SMOOTH)
                                        :wait(0.10)
                                        :parallel(
                                            Animation(button_holder, 1):setVisible(true)
                                            :setScl(0.5, 0.5, 1)
                                            :seekScl(1.08, 1.08, 1.0, 0.25, MOAIEaseType.SOFT_SMOOTH)
                                            :wait(0.10)
                                            :seekScl(1.0, 1.0, 1.0, 0.10, MOAIEaseType.SOFT_SMOOTH)                                            
                                        )
 
    anim2:play()        
end

function hideSetting()
    if view_settings then
        print("hideSettings()")
        anim2 = Animation({ view_settings }):seekLoc(0, -90, 0, 0.25, MOAIEaseType.SOFT_SMOOTH)
                                        :wait(0.10)
        anim2:play({ onComplete = function()
            view_settings:setScene(nil)
            filterMesh:setParent(nil)
            view_settings = nil            
        end
        })
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
        styles = { ThemeManager:getTheme():buttonStyle("./assets/main_btn.png") },
        parent = view,
    }

    playButton:setCenterPos(GAME_WIDTH/2, GAME_HEIGHT/2)

    scoreButton = Button {
        name = "startButton",
        onClick = onShopClick,
        size = { 226/2, 30},
        styles = { ThemeManager:getTheme():buttonStyle("./assets/shop_btn.png") },
        parent = view,
        pos = { GAME_WIDTH - (226/2) - 20, 10 },
        text = "",
        skinResizable = false,
    }

    settingButton = Button {
        name = "settingButton",
        onClick = showSettings,
        size = { 50, 46},
        styles = { ThemeManager:getTheme():buttonStyle("./assets/settings_btn.png") },
        parent = view,
        pos = { 0, 0 },
        text = "",
    }

    balanceLabel = TextLabel {
        text = "",
        size = { 226/2, 53/2},
        parent = view,
        color = string.hexToRGB( "#FFFFFF", true ),
        pos = { GAME_WIDTH - (226/2) - 50, 10 },
        textSize = 13,
        align = {"right", "center"}
    }

    filterMesh = Sprite {
            texture = "./assets/gray_70.png", 
            size = { GAME_WIDTH , GAME_HEIGHT } ,
            pos = { 0, 0 }
    }  

    updateBalance()

    playButton:setCenterPiv()
    anim2 = Animation():loop(0, 
        Animation({ playButton }):seekScl(1.08, 1.08, 1, 1.0, MOAIEaseType.SOFT_SMOOTH):wait(0.10):seekScl(1, 1, 1, 1.0, MOAIEaseType.SOFT_SMOOTH))
    anim2:play()

end

function updateBalance()
    balanceLabel:setText("" .. Settings:get("balance"))
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

function onTouchUp(e)
    --print("touch up()")
    if view_settings then
        local scale = layer:getViewScale()
        e.x = e.x / scale
        e.y = e.y / scale

        if e.y > 100 then
            hideSetting()
        end
    end
end
