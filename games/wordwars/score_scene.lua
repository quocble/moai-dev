module(..., package.seeall)

local GAME_WIDTH = Application.viewWidth
local GAME_HEIGHT = Application.viewHeight

function onCreate(params)
    layer = Layer {scene = scene}
    local floor = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {"#CB44F3", "#8FC7CB", 90})
    floor:setLayer(layer)

    local player_results = { }

    local results = param.results
    for p=1, results do
    	player_results[p] = results.score
    end

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
