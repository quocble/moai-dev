module(..., package.seeall)
local string = require("hp/lang/string")
local focused = nil

MOAIKeyboard = MOAIKeyboardIOS or MOAIKeyboardAndroid

local PANEL_STYLE = {
    normal = {
        backgroundSkin = "./assets/panel_nolines.png",
        backgroundSkinClass = NinePatch,
        backgroundColor = {1, 1, 1, 1.0},
    },
    disabled = {
        backgroundColor = {0.5, 0.5, 0.5, 1},
    },
}

function onBackClick()
    SceneManager:closeScene({animation = "popOut"})    
end

function onRegisterClick()
    -- local previousScene = SceneManager:findSceneByName("login_scene")
    -- previousScene.proceed_with_login = true

    GameService:loginWithUsername(username_field:getText(), password_field:getText(), function(data) 
        if data["error"] then
            print("Some error " .. data["error"])
        else
            Settings:set("user_id", data["user_id"])
            Settings:set("secret", data["secret"])
            Settings:set("username", data["username"])
            Settings:set("login", true)        
            Settings:save()

            print("user_id : " .. Settings:get("user_id"))
            print("user_name : " .. Settings:get("username"))
            print("secret : " .. Settings:get("secret"))
            print("login successful")

            SceneManager:closeScene({animation = "popOut" , onComplete = function()
                print("pop out completed")
               SceneManager:openScene("menu_scene", { animation = "crossFade"}  )        
            end})
        end
    end)
end

function bindKeyboard()
    --MOAIKeyboardIOS.showKeyboard()
    MOAIKeyboard.setListener(MOAIKeyboard.EVENT_INPUT,function(start,length,textVal)
        if focused then
            print("typed ", textVal , "  ", focused, "backspace=", string.byte(textVal) == 8 , start, " ", len)
            if textVal == "" then
                if string.len(focused:getText()) then
                    focused:setText( string.sub(focused:getText(), 1 , string.len(focused:getText()) - 1 ))                
                end
            else 
                focused:setText(focused:getText() .. textVal);
            end
        end
    end)
end

function onCreate(params)
    
    bindKeyboard()

    view = View {
        scene = scene,
    }

    panel = Panel {
        name = "panel",
        size = { 320, 370},
        pos = { (Application.viewWidth-320)/2 , (Application.viewHeight-370) / 2 },
        styles = { PANEL_STYLE },
        parent = view
    }

    local panel_title = TextLabel {
        text = "Create Username",
        size = {320, 45},
        parent = panel,
        color = string.hexToRGB( "#FFFFFF", true ),
        pos = {0, 0 },
        textSize = 16,
        align = {"center", "center"}
    }

    local backButton = Button {
        name = "startButton",
        onClick = onBackClick,
        size = { 96/2, 96/2 },
        parent = panel,
        pos = { 0, 0 },
        text = "",
        styles = { ThemeManager:getTheme():buttonStyle("./assets/panel_back_btn.png")  },
    }

    username_label = TextLabel {
        text = "username",
        size = { 226/2, 53/2},
        parent = panel,
        color = string.hexToRGB( "#FFFFFF", true ),
        pos = { 10, 70 },
        textSize = 16,
        align = {"right", "center"}
    }

   password_label = TextLabel {
        text = "password",
        size = { 226/2, 53/2},
        parent = panel,
        color = string.hexToRGB( "#FFFFFF", true ),
        pos = { 10, 70 + 70 },
        textSize = 16,
        align = {"right", "center"}
    }

    username_bg = NinePatch {
        texture = "./assets/editbox.png", 
        parent = panel,
        pos = { 150, 70 }, 
        size = { 113, 27} ,
        align = {"center", "center"}
    }

    username_field = TextLabel {
        text = "",
        size = { 226/2, 53/2},
        parent = panel,
        color = string.hexToRGB( "#000000", true ),
        pos = { 140, 70 },
        textSize = 12,
        align = {"right", "center"}
    }


    password_bg = NinePatch {
        texture = "./assets/editbox.png", 
        parent = panel,
        pos = { 150, 140  }, 
        size = { 113, 27} ,
        align = {"center", "center"}
    }

   password_field = TextLabel {
        text = "",
        size = { 226/2, 53/2},
        parent = panel,
        color = string.hexToRGB( "#000000", true ),
        pos = { 140, 140 },
        textSize = 12,
        align = {"right", "center"}
    }

    login_btn = Button {
        name = "startButton",
        onClick = onRegisterClick,
        size = { 100, 45 },
        parent = panel,
        pos = { (320-100)/2, 200 },
        text = "Register",
        styles = { ThemeManager:getTheme():buttonStyle("./assets/btn_up.png")  },
    }    

    cursor = Sprite {
        texture = "./assets/cursor.png", 
        parent = panel,
        size = { 2 , 16 } ,
    }   
    cursor:setVisible(false)

    cursor.startAnimation = function() 
        if not cursor.animation then
            cursor.animation = Animation():loop(0, 
                Animation({ cursor }):fadeIn(0.30):wait(0.15):fadeOut(0.30))
        end

        cursor:setVisible(true)
        cursor.animation:play()
    end

    cursor.stopAnimation = function()
        if cursor.animation then
            cursor:setVisible(false)
            cursor.animation:stop()
        end
    end

end

function onDestroy()
    print("onDestroy() createuser")
end

function onTouchUp(e)
    if username_field:hitTestScreen(e.x, e.y) then
        print("Hit test")
        focused = username_field
        MOAIKeyboard.showKeyboard()        
        cursor:startAnimation(username_field)
        cursor:setPos(username_field:getRight(), username_field:getTop() + 5)        
    elseif password_field:hitTestScreen(e.x, e.y) then
        print("Hit test")
        focused = password_field
        MOAIKeyboard.showKeyboard()        
        cursor:startAnimation(password_field)
        cursor:setPos(password_field:getRight(), password_field:getTop() + 5)        
    else 
        focused = nil
        MOAIKeyboard.hideKeyboard()        
        cursor:stopAnimation()        
    end
end
