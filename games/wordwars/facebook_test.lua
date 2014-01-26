module(..., package.seeall)

appId = '468153463310522'

MOAIFacebookAndroid.init ( appId )

function loginSuccessCallbackAndroid ()
    mToken = MOAIFacebookAndroid.getToken ()
    eToken = MOAIFacebookAndroid.getExpirationDate ()

    MOAIDialog.showDialog ( eToken, mToken, "Yes", "Maybe", "No", true, nil )
end

function onCreate(params)
    layer = Layer {scene = scene}

    particle = Particles.fromPex("./assets/star04.pex")
    particle:setLayer(layer)
end

function onStartClick()
    if MOAIFacebookAndroid then
        if MOAIFacebookAndroid.setListener then
            MOAIFacebookAndroid.setListener ( MOAIFacebookAndroid.SESSION_DID_LOGIN, loginSuccessCallbackAndroid )
        end

        if MOAIFacebookAndroid.login then
            MOAIFacebookAndroid.login ( {'publish_actions'} )
        end
    end
end

function onStart()
    particle.emitter:setLoc(100, 100)
    particle.emitter:forceUpdate()
    particle:start()

    view = View {
        scene = scene,
        pos = {0, 0}
    }
    playButton = Button {
        name = "startButton",
        text = "CONNECT TO FACEBOOK",
        onClick = onStartClick,
        size = { 250, 60},
        parent = view,
    }

end

function onTouchDown(e)
    print("down")
    local wx, wy = layer:wndToWorld(e.x, e.y, 0)
    particle.emitter:setLoc(wx, wy, 0)
    particle.emitter:forceUpdate()
    particle:startParticle()
    particle.emitter:start()        
end

function onTouchMove(e)
    local viewScale = Application:getViewScale()
    particle.emitter:addLoc(e.moveX / viewScale, e.moveY / viewScale, 0)
end

function onTouchUp(e)
    particle:stopParticle()
    particle.emitter:stop()    
    print("up")    
end