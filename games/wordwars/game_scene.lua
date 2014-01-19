module(..., package.seeall)

table = require "hp/lang/table"
array = require "hp/lang/array"
string = require("hp/lang/string")

--------------------------------------------------------------------------------
-- Const
--------------------------------------------------------------------------------

local GAME_WIDTH = Application.viewWidth
local GAME_HEIGHT = Application.viewHeight

local WORD_BAG = { A = 9 , B = 2, C = 2, D = 4, E = 12, F = 2, G = 3,
                    H = 2, I = 9, J = 1, K = 1, L = 4, M = 2, N = 6, 
                    O = 8, P = 2, Q = 1, R = 6, S = 4, T = 6, U = 4,
                    V = 2, W = 2, X = 1, Y = 2, Z = 1 }
local BOARD_SIZE = { width = 4, height = 4 }

local cell_w = GAME_WIDTH / BOARD_SIZE["width"]
local cell_h = GAME_WIDTH / BOARD_SIZE["height"]

local DICTIONARY = { }
local PLAYER_WORDS = { }
local PLAYER_SCORE = 0
local PLAYER_ID = ""
local GAME_TIME_SEC = 0
local PLAYER_LIST = { }

local LAST_TIMESTAMP = 0
local CurrentWord = ""
local PLAYER_NAMES = { }

local SENT_BAD_WORD = false
local CURRENT_MAX_STREAK = 0
local ALL_TIME_MAX_STREAK = 0

local CURRENT_WORD_LENGTH = 0
local ALL_TIME_MAX_WORD_LENGTH = 0

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

math.randomseed(os.time())


--------------------------------------------------------------------------------
-- Network functions
--------------------------------------------------------------------------------


function setupGame(response)
    PLAYER_ID = response["your_index"]
    makeRemoteBoard(response["board"])
    makePlayers(#response["players"])
    setGameTimer(response["game_time"])
    PLAYER_NAMES = response["players"]
end

function makeWebSocket()
    ws = MOAIWebSocket.new()
    ws:setListener ( MOAIWebSocket.ON_MESSAGE, onMessageReceived )
    ws:setListener ( MOAIWebSocket.ON_CONNECT, onConnected )
    ws:setListener ( MOAIWebSocket.ON_CLOSE, onClosed )
    ws:setListener ( MOAIWebSocket.ON_FAIL, onFailed )

    -- ws:start("ws://192.168.1.115:8888/ws")
    ws:start("ws://10.0.0.10:8888/ws")

end

local WS_LISTENER = {}

function WS_LISTENER.onMessageReceived( msg ) 
    print("WebSocket: " .. msg )
    response = MOAIJsonParser.decode ( msg )
    if response["msgtype"] == "score" then
        if PLAYER_ID == response["player_index"] then
            PLAYER_SCORE = response["score"]
            PlayerScore:setText("" .. PLAYER_SCORE)
        end
            PLAYER_LIST[response["player_index"]+1].player_score:setText("" .. response["score"])
            showPointScore(response["player_index"]+1, response["point"])
    elseif response["msgtype"] == "game_over" then
        gameOver(response) 
    end
end

function WS_LISTENER.onConnected( msg ) 
    print("WebSocket: " .. msg )
    local queue_msg = { msgtype = "queue" }
    local write_msg = MOAIJsonParser.encode(queue_msg)
    GameService:write(write_msg)
end

function WS_LISTENER.onClosed( msg ) 
    print("WebSocket: " .. msg )
end

function WS_LISTENER.onFailed( msg ) 
    print("WebSocket: " .. msg )
end

function onCreate(params)

    GameService:addListener(WS_LISTENER)

    print(websocket)
    print(params.websocket)
    
    makeDictionary()
    makeBoard()
    makeNavigationBar()
    makeGameTimer()
    makeBackButton()
    setupGame(params.game)  
    --makeLocalBoard()
    makeWordBox()
    makePlayerScore()
    -- makeGameTimer()
    -- makePlayers(4)
    -- setGameTimer(97)
end

function onDestroy()
    print("onDestroy()")
    GameService:leaveGameAndQueue()
    GameService:removeListener(self)    
end

--------------------------------------------------------------------------------
-- Event Handler
--------------------------------------------------------------------------------

function onStart()
end

function onEnterFrame()
    updateGameTimer()
end

function onTouchDown(e)
    local scale = guiView:getViewScale()
    e.x = e.x / scale
    e.y = e.y / scale
    CurrentWordString = ""
    clearSelectedLetters()
    updateTouchData(e.x, e.y)
end

function onTouchMove(e)
    local scale = guiView:getViewScale()
    e.x = e.x / scale
    e.y = e.y / scale
    updateTouchData(e.x, e.y)
end

function onTouchUp(e)
    resetScale(nil, true)
    if checkWord() then
        CURRENT_MAX_STREAK = CURRENT_MAX_STREAK + 1
        CURRENT_WORD_LENGTH = #CurrentWordString
        updatePlayerScore()
    else
        CURRENT_MAX_STREAK = 0
    end
end

function onBackClick()
    SceneManager:closeScene()
    SceneManager:closeScene()
end

function resetScale(skip_sprite, change_color)
    for c=1, BOARD_SIZE["width"] do
        for r=1, BOARD_SIZE["height"] do
            local sprite = GameBoard[c][r]["sprite"]
            if sprite.touching and skip_sprite ~= sprite then
                sprite.touching = false
                sprite.action:stop()
                sprite:seekScl(1.0, 1.0, 1.0, 0.25)   
            end

            if change_color and skip_sprite ~= sprite then 
                sprite:setTexture("./assets/word_tile_default.png")
            end

        end
    end

end

--------------------------------------------------------------------------------
-- Make Functions
--------------------------------------------------------------------------------

function buildAndShuffle()
    local bag = {}

    for k, v in pairs(WORD_BAG) do
        for i=1,v do
            table.insert(bag, k)
        end
    end

    --print(table.concat( bag, ", " ))
    array.shuffle(bag)
    --print(table.concat( bag, ", " ))
    return bag
end

function makeLetter(p, c, r)
    
    local left, top = (c-1) * cell_w , (r-1) * cell_h 
    local margin = 2
    local top = top + (GAME_HEIGHT - GAME_WIDTH)

    sprite1 = Sprite {
                texture = "./assets/word_tile_default.png", 
                layer = guiView, 
                left = left + margin, 
                top = top + margin,
                width = cell_w - (margin * 2),
                height = cell_h - (margin * 2)
            }

    levelLabel = TextLabel {
        text = p["letter"],
        size = {cell_w, cell_h},
        pos = { left,  top },
        layer = guiView,
        color = string.hexToRGB( "#4C5659", true ),
        align = {"center", "center"}
    }

    sprite1.touching = false 
    p["sprite"] = sprite1

end

function makeBoard()

    print("making board")
    guiView = Layer()
    guiView:setScene(scene)

    local floor = Mesh.newRect(0, 55, GAME_WIDTH, GAME_HEIGHT-55, {"#CB44F3", "#8FC7CB", 90})
    floor:setLayer(guiView)

end

function makeNavigationBar()
    navView = Layer()
    navView:setScene(scene)
    --left, top, width, height, col
    local floor = Mesh.newRect(0, 0, GAME_WIDTH, 55, "#555C60")
    floor:setLayer(navView)
end

function makeBackButton()
    local view = View {
        scene = scene,
        pos = {0, 0},
        size = {GAME_WIDTH, 55},
    }

    backButton = Button {
        name = "backButton",
        text = "Back",
        parent = view,
        onClick = onBackClick,
        pos = {10, 18},
        size = {60, 35},
        styles = { A_BUTTON_STYLES }
    }
end

function makeGameTimer()
    GameTimer = TextLabel {
        text = "0:00",
        size = {40, 20},
        pos = {250,  13},
        layer = navView,
        color = string.hexToRGB( "#FFFFFF", true ),
        align = {"center", "center"}
        }
    GameTimer:setTextSize(15)
    GameTimer:fitSize()
end

function makeLocalBoard()
    local bag = buildAndShuffle()
    local total_letters = BOARD_SIZE["width"] * BOARD_SIZE["height"]

    GameBoard = {}
    for r=1,BOARD_SIZE["width"] do
      GameBoard[r] = {}     -- create a new row
      for c=1,BOARD_SIZE["height"] do
        local l = table.remove(bag, 1)
        GameBoard[r][c] = { col = c, row = r, letter = l }
      end
    end

    for c=1, BOARD_SIZE["width"] do
        for r=1, BOARD_SIZE["height"] do
            local p = GameBoard[r][c]    
            makeLetter(p, c, r)
        end
    end
end    

function makeRemoteBoard(data)
    local total_letters = BOARD_SIZE["width"] * BOARD_SIZE["height"]
    local index = 1
    GameBoard = {}
    for r=1,BOARD_SIZE["width"] do
      GameBoard[r] = {}     -- create a new row
      for c=1,BOARD_SIZE["height"] do
        -- local l = table.remove(bag, 1)
        local l = data[index]
        index = index + 1
        GameBoard[r][c] = { col = c, row = r, letter = l }
      end
    end

    for c=1, BOARD_SIZE["width"] do
        for r=1, BOARD_SIZE["height"] do
            local p = GameBoard[r][c]    
            makeLetter(p, c, r)
        end
    end
end

function makeWordBox()
    CurrentWordString = ""
    letter_length = 0

    CurrentWordBox = NinePatch {
        texture = "./assets/word_tile_on.png", 
        layer = guiView,
        pos = {GAME_WIDTH,  GAME_HEIGHT - GAME_WIDTH - 40}, 
        align = {"center", "center"}
    }

    CurrentWord = TextLabel {
        text = "",
        size = {GAME_WIDTH, 40},
        pos = {0,  GAME_HEIGHT - GAME_WIDTH - 60},
        layer = guiView,
        color = string.hexToRGB( "#0066CC", true ),
        align = {"center", "center"}
    }

end

function makePlayerScore()
    PlayerScore = TextLabel {
        text = "0",
        size = {GAME_WIDTH, 40},
        pos = {0,  15},
        layer = navView,
        color = string.hexToRGB( "#01FF70", true ),
        align = {"center", "center"}
    }
end

function makePlayers(num_of_players)
    local margin = (GAME_WIDTH - (num_of_players * cell_w)) / 2
    for c=0, num_of_players - 1 do
        local player_group = Group { 
                    size = {cell_w, cell_h},
                    align = {"center", "center"},
                    layer = guiView
                }

        --print("cell_w " .. cell_w .. " cell_height " .. cell_h)
        local player_image = Sprite {
                    texture = "./assets/word_tile_default.png", 
                    size  = { cell_w, cell_h },
                    parent = player_group,
                    pos = {0, 0},
                }

        local player_score = TextLabel {
                    text = "0",
                    size = {cell_w, 40},
                    parent = player_group,
                    color = string.hexToRGB( "#000000", true ),
                    pos = {0, cell_h - 8},
                    align = {"center", "center"}
                }

        player_group.player_image = player_image
        player_group.player_score = player_score

        player_group:setPos(margin + (c * 80), 65)
        table.insert(PLAYER_LIST, player_group)
    end
end

function makeDictionary()
    local read_file = "./assets/dictionary_en.txt"

    for line in io.lines(read_file) do
        DICTIONARY[line] = true
    end
end

--------------------------------------------------------------------------------
-- Update logic
--------------------------------------------------------------------------------

function updateTouchData(x, y)
    
    col = math.ceil(x / cell_w) 
    row = math.ceil((y - (GAME_HEIGHT - GAME_WIDTH)) / cell_h)

    ideal_x = (col  - 1) * cell_w
    ideal_y = ((row - 1) * cell_h) + (GAME_HEIGHT - GAME_WIDTH)
    margin = 10

    smaller_rect = { x = ideal_x+margin, y = ideal_y + margin, width = cell_w - (2*margin), height = cell_h - (2*margin) }
    --print("x: " .. x .. "y: " .. y)
    --print("xbox " .. smaller_rect['x'] .. " ybox " .. smaller_rect['y'] .. " width " .. smaller_rect['width'] .. " height " .. smaller_rect['height'])
    local isInSmallerRect = false
    if x >= smaller_rect['x'] and y >= smaller_rect['y']
        and x <= smaller_rect['x'] + smaller_rect['width']
        and y <= smaller_rect['y'] + smaller_rect['height'] then
        isInSmallerRect = true
    end

    if col >= 1 and col <= BOARD_SIZE["width"] and
        row >= 1 and row <= BOARD_SIZE["height"] and isInSmallerRect then

        local selected_cell = GameBoard[row][col]
        local sprite = selected_cell["sprite"]
        if not sprite.touching then
            --print("e.x= " .. x .. " e.y=" .. y .. " col=" .. col .. " row = " .. row)
            if not selected_cell.used_letter then
                CurrentWordString = CurrentWordString .. selected_cell.letter
                selected_cell.used_letter = true
            end
            CurrentWord:setText(CurrentWordString)
            updateWordBox()
            sprite:setTexture("./assets/word_tile_on.png")
            sprite.action = sprite:seekScl(1.2, 1.2, 1.2, 0.25) 
            sprite.touching = true

            resetScale(sprite, false)
        end
    end
end

function updateWordBox()
    letter_length = string.len(CurrentWordString)
    --print(letter_length)
    CurrentWordBox:setSize(letter_length*19, 60)
    CurrentWordBox:setCenterPos(GAME_WIDTH/2, GAME_HEIGHT - GAME_WIDTH - 40)
end

function clearSelectedLetters()
    for c=1, BOARD_SIZE["width"] do
        for r=1, BOARD_SIZE["height"] do
            GameBoard[c][r].used_letter = false
        end
    end
end

function checkWord()
    if DICTIONARY[CurrentWordString] ~= nil then
        print(CurrentWordString)
        return true
    end
    return false
end

function updatePlayerScore()
    if PLAYER_WORDS[CurrentWordString] == nil then
        PLAYER_WORDS[CurrentWordString] = true
        --PLAYER_SCORE = PLAYER_SCORE + letter_length ^ 2 -- word score = word length^2
        --PlayerScore:setText("SCORE: " .. PLAYER_SCORE)
        local send_word_to_server = { msgtype = "play", word = CurrentWordString }
        local msg = MOAIJsonParser.encode ( send_word_to_server )
        print(msg)
        GameService:write(msg)
    end
    if ALL_TIME_MAX_STREAK < CURRENT_MAX_STREAK then
        ALL_TIME_MAX_STREAK = CURRENT_MAX_STREAK
        local send_max_to_server = { msgtype = "word_streak", count = ALL_TIME_MAX_STREAK }
        local msg = MOAIJsonParser.encode(send_max_to_server)
        print(msg)
        GameService:write(msg)
    end
    if ALL_TIME_MAX_WORD_LENGTH < CURRENT_WORD_LENGTH then
        ALL_TIME_MAX_WORD_LENGTH = CURRENT_WORD_LENGTH
        local send_max_word_length_to_server = { msgtype = "max_word_length", word = CurrentWordString, count = ALL_TIME_MAX_WORD_LENGTH}
        local msg = MOAIJsonParser.encode(send_max_word_length_to_server)
        print(msg)
        GameService:write(msg)
    end
end

function updateGameTimer()
    local step = 0
    if LAST_TIMESTAMP ~= 0 then
        step = MOAISim.getDeviceTime() - LAST_TIMESTAMP
    end
    if GAME_TIME_SEC >= 0 then
        local min = math.floor(GAME_TIME_SEC / 60)
        local sec = math.floor(GAME_TIME_SEC % 60)
        if (math.floor(GAME_TIME_SEC) - math.floor(GAME_TIME_SEC - step)) >= 1 then
            if sec < 10 then 
                sec = "0" .. sec
            end
            GameTimer:setText(min .. ":" .. sec)
        end

        GAME_TIME_SEC = GAME_TIME_SEC - step
    end
    LAST_TIMESTAMP = MOAISim.getDeviceTime()
end


--------------------------------------------------------------------------------
-- GameOver logic
--------------------------------------------------------------------------------

function isGameOver()

end

function gameOver(game_over_results)
    print("GAME OVER")
    print("PLAYER_NAMES: ")
    print(PLAYER_NAMES)
    print("game_over_results: ")
    print(game_over_results)
    --SceneManager:openScene(game_over_results)
    --SceneManager:openScene(test_results)
    SceneManager:openScene("score_scene", game_over_results)

end

--------------------------------------------------------------------------------
-- Common logic
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Scoring / Time functions
--------------------------------------------------------------------------------

function showPointScore(player_index, amount)
    local left, top = PLAYER_LIST[player_index]:getPos()

    local score_text 
    if PLAYER_ID == player_index - 1 then
        score_text = TextLabel { 
        text = "+" .. amount,
        size = {cell_w, 40},
        pos = { left, cell_h },
        layer = navView,
        color = string.hexToRGB( "#01FF70", true ),
        align = {"center", "center"}
        }
    else
        score_text = TextLabel { 
        text = "+" .. amount,
        size = {cell_w, 40},
        pos = { left, cell_h },
        layer = navView,
        color = string.hexToRGB( "#FF4136", true ),
        align = {"center", "center"}
        }
    end

    local anim1 = Animation({score_text})
        :moveLoc(0, -75, 0, 1, MOAIEaseType.EASE_IN)
        :moveColor(0, 0, 0, -1)
    anim1:play( { onComplete = removeScoreText(score_text) } )

end

function removeScoreText(score_text)
    local x, y = score_text:getLoc()
    if y < 0 then
        guiView:removeProp(score_text)
        score_text = nil
    end
end 

function setGameTimer(time_in_sec)
    print(time_in_sec)
    GAME_TIME_SEC = time_in_sec
end



