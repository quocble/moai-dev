module(..., package.seeall)

local string = require("hp/lang/string")
local GAME_WIDTH = Application.viewWidth
local GAME_HEIGHT = Application.viewHeight
local filterMesh = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, "#000000")
MOAIFacebook = MOAIFacebookAndroid or MOAIFacebookIOS
MOAIFacebook.init ( "468153463310522" )

function loginSuccessCallback ()
    mToken = MOAIFacebook.getToken ()
    eToken = MOAIFacebook.getExpirationDate ()

    print("token " .. mToken)
    GameService:loginWithFacebook(mToken, function(data)
        Settings:set("token", mToken)
        Settings:set("user_id", data["user_id"])
        Settings:set("secret", data["secret"])
        Settings:set("username", data["username"])
        Settings:set("login", true)        
        Settings:save()

        print("user_id : " .. Settings:get("user_id"))
        print("user_name : " .. Settings:get("username"))
        print("secret : " .. Settings:get("secret"))
        print("login successful")

        SceneManager:openScene("menu_scene", { animation = "crossFade"}  )
    end)
end

function onLoginClicked()
    if MOAIFacebook then
        if MOAIFacebook.setListener then
            MOAIFacebook.setListener ( MOAIFacebook.SESSION_DID_LOGIN, loginSuccessCallback )
        end

        if MOAIFacebook.login then
            print ("attempt to login to facebook")
            MOAIFacebook.login ( {'basic_info'} )
        end    
    end
end

function onEmailClicked()
    SceneManager:openScene("create_user", { animation = "popIn"})
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
        pos = {0, 0},
        layout = VBoxLayout {
            align = {"center", "center"},
            padding = {10, 10, 10, 10},
            gap = {10, 20},            
        },
    }

    fbButton = Button {
        name = "startButton",
        text = "",
        onClick = onLoginClicked,
        size = { 433/2, 92/2},
        styles = { ThemeManager:getTheme():buttonStyle("./assets/login_with_fb.png")  },
        parent = view
    }

    emailButton = Button {
        name = "startButton",
        text = "",
        onClick = onEmailClicked,
        size = { 433/2, 92/2},
        styles = { ThemeManager:getTheme():buttonStyle("./assets/login_with_email.png")  },
        parent = view
    }
    fbButton:setCenterPiv()

    anim2 = Animation():loop(0, 
        Animation({ fbButton }):seekScl(1.02, 1.02, 1, 1.0, MOAIEaseType.SOFT_SMOOTH):wait(0.10):seekScl(1, 1, 1, 1.0, MOAIEaseType.SOFT_SMOOTH))
    anim2:play()

end

function onStart()
    print("onStart()")
end

function onResume()

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
