MOAISim.setStep ( 1 / 60 )
MOAISim.clearLoopFlags ()
MOAISim.setLoopFlags ( MOAISim.SIM_LOOP_ALLOW_BOOST )
MOAISim.setLoopFlags ( MOAISim.SIM_LOOP_LONG_DELAY )
MOAISim.setBoostThreshold ( 0 )

-- Screen size setting
local screenWidth = MOAIEnvironment.horizontalResolution or 320
local screenHeight = MOAIEnvironment.verticalResolution or 480
local viewScale = (screenWidth/320)

-- Application config
local config = {
    title = "Hanappe samples",
    screenWidth = screenWidth,
    screenHeight = screenHeight,
    viewScale = viewScale,
    mainScene = "menu_scene",
}

return config