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

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
-- letter distribution: aaaaaaaaabbccddddeeeeeeeeeeeeffggghhiiiiiiiiijkllllmmnnnnnnooooooooppqrrrrrrssssttttttuuuuvvwwxyyz
-- init random seed
math.randomseed(os.time())

CurrentWord = ""

--------------------------------------------------------------------------------
-- Create
--------------------------------------------------------------------------------

function onCreate(params)
    makeWebSocket()
    -- makePhysicsWorld()
    
    -- makeGameLayer()
    -- makePlayer()
    -- makeFloors()
    -- makeWalls()
    
    -- makeGuiView()
    makeDictionary()
    makeBoard()
    --makeLocalBoard()
    makeWordBox()
    makePlayerScore()

end

--------------------------------------------------------------------------------
-- Event Handler
--------------------------------------------------------------------------------

function onStart()

end

function onEnterFrame()
    -- if isGameOver() then
    --     return
    -- end
    updatePointScore()
    -- updatePlayer()
    -- updateFloors()
    -- updateScore()
    -- updateLevel()
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
        updatePlayerScore()
    end
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

    print(table.concat( bag, ", " ))
    array.shuffle(bag)
    print(table.concat( bag, ", " ))
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

    local floor = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {"#CB44F3", "#8FC7CB", 90})
    floor:setLayer(guiView)

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
        pos = {GAME_WIDTH,  75}, 
        align = {"center", "center"}
    }

--    CurrentWordBox:setStretchRows(.25, 5, .25)

    CurrentWord = TextLabel {
        text = "START",
        size = {GAME_WIDTH, 100},
        pos = {0,  80},
        layer = guiView,
        color = string.hexToRGB( "#000000", true ),
        align = {"center", "center"}
    }

    print("making word box")
end

function makePlayerScore()
    PlayerScore = TextLabel {
        text = "SCORE",
        size = {GAME_WIDTH, 40},
        pos = {0,  60},
        layer = guiView,
        color = string.hexToRGB( "#000000", true ),
        align = {"center", "center"}
    }
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

    if col >= 1 and col <= BOARD_SIZE["width"] and
        row >= 1 and row <= BOARD_SIZE["height"] then

        local selected_cell = GameBoard[row][col]
        local sprite = selected_cell["sprite"]
        if not sprite.touching then
            print("e.x= " .. x .. " e.y=" .. y .. " col=" .. col .. " row = " .. row)
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
    print(letter_length)
    CurrentWordBox:setSize(letter_length*18, 60)
    CurrentWordBox:setCenterPos(GAME_WIDTH/2, 130)
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
end

function updatePlayerScore()
    if PLAYER_WORDS[CurrentWordString] == nil then
        PLAYER_WORDS[CurrentWordString] = true
        --PLAYER_SCORE = PLAYER_SCORE + letter_length ^ 2 -- word score = word length^2
        --PlayerScore:setText("SCORE: " .. PLAYER_SCORE)
        local send_word_to_server = { msgtype = "play", word = CurrentWordString }
        msg = MOAIJsonParser.encode ( send_word_to_server )
        print(msg)
        ws:write(msg)
    end
end

--------------------------------------------------------------------------------
-- GameOver logic
--------------------------------------------------------------------------------

function isGameOver()

end

function gameOver()

end

--------------------------------------------------------------------------------
-- Common logic
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Network functions
--------------------------------------------------------------------------------

function makeWebSocket()
    ws = MOAIWebSocket.new()
    ws:setListener ( MOAIWebSocket.ON_MESSAGE, onMessageReceived )
    ws:setListener ( MOAIWebSocket.ON_CONNECT, onConnected )
    ws:setListener ( MOAIWebSocket.ON_CLOSE, onClosed )
    ws:setListener ( MOAIWebSocket.ON_FAIL, onFailed )

    ws:start("ws://192.168.1.115:8888/ws")

end

function onMessageReceived( msg ) 
    print("WebSocket: " .. msg )
    response = MOAIJsonParser.decode ( msg )
    if response["msgtype"] == "new" then
        PLAYER_ID = response["your_index"]
        makeRemoteBoard(response["board"])
    elseif response["msgtype"] == "score" then
        if PLAYER_ID == response["player_index"] then
            PLAYER_SCORE = response["score"]
            PlayerScore:setText("SCORE: " .. PLAYER_SCORE)
        end

    end
end

function onConnected( msg ) 
    print("WebSocket: " .. msg )
    --ws:write("Hello")
    --ws:write("help")
end

function onClosed( msg ) 
    print("WebSocket: " .. msg )
end

function onFailed( msg ) 
    print("WebSocket: " .. msg )
end

--------------------------------------------------------------------------------
-- Scoring functions
--------------------------------------------------------------------------------

function showPointScore(player_index, word, amount)
    local score_text = TextLabel {
        text = "+10",
        size = {GAME_WIDTH, 40},
        pos = {0,  60},
        layer = guiView,
        color = string.hexToRGB( "#000000", true ),
        align = {"center", "center"}
    }

    local anim1 = Animation({score_text}, 1)
        :moveLoc(50, 50, 0)
        :moveRot(0, 0, 180)
        :moveScl(1, 1, 0)
        :wait(3)
        :sequence(
            Animation(sprite1, 1):moveScl(-1, -1, 0):moveRot(0, 0, -180):moveLoc(-50, -50, 0),
            Animation(sprite2, 1):moveScl(-1, -1, 0):moveRot(0, 0, -180):moveLoc(-50, -50, 0))
        :wait(3)
        :parallel(
            Animation(sprite1, 1):setLeft(10):setTop(10),
            Animation(sprite2, 1):setLeft(10):setTop(sprite1:getHeight() + 10))

end




