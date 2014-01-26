module(..., package.seeall)

table = require "hp/lang/table"
array = require "hp/lang/array"
string = require("hp/lang/string")

selectSound             = SoundManager:getSound("./assets/A_select.ogg", 0.1)
goodSound             = SoundManager:getSound("./assets/A_combo1.caf", 0.5)
failSound             = SoundManager:getSound("./assets/A_falsemove.ogg", 0.5)

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
local LAST_SELECTED_CELL = { }
local WORD_BOX_ANIM = Animation()
local SENT_BAD_WORD = false
local CURRENT_MAX_STREAK = 0
local BLACKED_OUT_TILES = { }
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
--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------
local color = {} 
color.YELLOW = string.hexToRGB("#ffff00", true)
color.GREEN = string.hexToRGB("2ECC40", true)
color.RED = string.hexToRGB( "#FF4136", true)
color.LIME = string.hexToRGB( "#01FF70", true )
color.BLUE = string.hexToRGB("#0074D9", true)
color.BLACK = string.hexToRGB("#111111", true)

--------------------------------------------------------------------------------
-- Network functions
--------------------------------------------------------------------------------


function setupGame(response)
    PLAYER_ID = response["your_index"]
    PLAYER_NAMES = response["players"]
    makeRemoteBoard(response["board"])
    makePlayers(response["players"])
    setGameTimer(response["game_time"])
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
    --print("WebSocket: " .. msg )
    response = MOAIJsonParser.decode ( msg )
    if response["msgtype"] == "score" then
        if PLAYER_ID == response["player_index"] then
            PLAYER_SCORE = response["score"]
            PlayerScore:setText("" .. PLAYER_SCORE)
        end
            PLAYER_LIST[response["player_index"]+1].player_score:setText("" .. response["score"])
            showPointScore(response["player_index"], response["point"])
    elseif response["msgtype"] == "game_over" then
        gameOver(response)
    elseif response["msgtype"] == "power_up" then
        execPowerUp(response)
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
    
    makeDictionary()
    makeBoard()
    makeNavigationBar()
    makeGameTimer()
    makeBackButton()
    setupGame(params.game)  
    --makeLocalBoard()
    makeWordBox()
    makeStreakBox()
    makePlayerScore()
    loadParticles()


    -- makeGameTimer()
    -- makePlayers(4)
    -- setGameTimer(97)
end

function onDestroy()
    print("game_scene:onDestroy()")
    GameService:leaveGameAndQueue()
    GameService:removeListener(self)    
end

--------------------------------------------------------------------------------
-- Event Handler
--------------------------------------------------------------------------------

function onStart()
    print("game_scene:onStart()")
end

function onEnterFrame()
    updateGameTimer()
end

function onTouchDown(e)
    local scale = guiView:getViewScale()
    e.x = e.x / scale
    e.y = e.y / scale
    CurrentWordString = ""
    CurrentWordBox:setColor(unpack(color.YELLOW))
    clearSelectedLetters()
    stopAndResetWordBox()
    LAST_SELECTED_CELL = {math.ceil(e.x / cell_w), math.ceil((e.y - (GAME_HEIGHT - GAME_WIDTH)) / cell_h)}
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
        updateStreak(CURRENT_MAX_STREAK)
        updatePlayerScore()
        playStars()
        showGoodWord()
        goodSound:play()
    else
        showBadWord()
        failSound:play()
        CURRENT_MAX_STREAK = 0
        updateStreak(CURRENT_MAX_STREAK)
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

function loadParticles()
    particle = Particles.fromPex("./assets/star04.pex")
    particle:setLayer(guiView)
    particle.emitter:setLoc(GAME_WIDTH/2, 170)
    particle.emitter:forceUpdate()
    particle:start()
end

function playStars()
    particle.emitter:forceUpdate()
    particle:stopParticle()
    particle:startParticle()
end

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
    -- sprite1:setVisible(false)
    sprite1.touching = false 
    p["sprite"] = sprite1
    p["levelLabel"] = levelLabel

end

function makeBoard()

    print("making board")
    guiView = Layer()
    guiView:setScene(scene)

    local floor = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {"#CB44F3", "#8FC7CB", 90})
    floor:setLayer(guiView)

end

function makeNavigationBar()
    navView = Layer()
    navView:setScene(scene)
    --left, top, width, height, col
    local floor = Mesh.newRect(0, 0, GAME_WIDTH, 44, "#555C60")
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
        pos = {10, 5},
        size = {60, 35},
        styles = { A_BUTTON_STYLES }
    }
end

function makeGameTimer()
    GameTimer = TextLabel {
        text = "0:00",
        size = {GAME_WIDTH, 20},
        pos = {-10,  5},
        font = "arial-rounded",
        layer = navView,
        color = string.hexToRGB( "#FFFFFF", true ),
        align = {"right", "center"}
        }
    GameTimer:setTextSize(15)
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
    -- local tile_to_blackout = { row = 1, col = 1}
    -- blackOutTile(tile_to_blackout)
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
        size = {GAME_WIDTH, 44},
        pos = {0,  0},
        layer = navView,
        color = string.hexToRGB( "#01FF70", true ),
        align = {"center", "center"}
    }
end

function makePlayers(players)
    num_of_players = #players
    local margin = (GAME_WIDTH - (num_of_players * cell_w)) / 2

    for c=0, num_of_players - 1 do
        local player_group = Group { 
                    size = {cell_w, cell_h},
                    align = {"center", "center"},
                    layer = guiView
                }

        --print("cell_w " .. cell_w .. " cell_height " .. cell_h)
        local player_image = MaskSprite {
                    size  = { cell_w, cell_h },
                    parent = player_group,
                    pos = {0, 0},
                    mask = "./assets/mask_img.png",
                    main = "./assets/standard_profile.jpg",
                    border = "./assets/border_img.png"
                }

        local player_score = TextLabel {
                    text = "0",
                    size = {cell_w, 40},
                    parent = player_group,
                    color = color.RED,
                    pos = {0, cell_h - 8},
                    align = {"center", "center"}
                }

        local player_floating_score = TextLabel { 
            text = "",
            size = {cell_w, 40},
            parent = player_group,
            pos = { 0, 0 },
            font = "arial-rounded",
            align = {"center", "center"}
            }

        if PLAYER_ID == c then
            player_score:setColor(unpack(color.LIME))
        end  

        player_group.player_floating_score = player_floating_score
        player_group.player_image = player_image
        player_group.player_score = player_score
        player_group:setPos(margin + (c * 80), 65)

        DownloadManager:request(players[c + 1].profile_img, function(filePath)
            player_image:setTexture(filePath, "main")
        end)

        table.insert(PLAYER_LIST, player_group)
    end
end

function makeDictionary()
    local read_file = "./assets/dictionary_en.txt"

    for line in io.lines(read_file) do
        DICTIONARY[line] = true
    end
end

function makeStreakBox()
    STREAK_BOX = TextLabel {
        text = "",
        size = {GAME_WIDTH, 40},
        layer = guiView,
        color = YELLOW,
        pos = { 0, GAME_HEIGHT/2 - 65},
        font = "arial-rounded",
        align = {"left", "center"}
    }
    STREAK_BOX:setTextSize(15)
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
    
    local isInSmallerRect = false
    if x >= smaller_rect['x'] and y >= smaller_rect['y']
        and x <= smaller_rect['x'] + smaller_rect['width']
        and y <= smaller_rect['y'] + smaller_rect['height'] then
        isInSmallerRect = true
    end

    local tile_loc = { r = row, c = col }
    local isNotInBlackedOutTile = true
    -- if tile_loc in BLACKED_OUT_TILES then
--    printTable(BLACKED_OUT_TILES)
    for i=1, #BLACKED_OUT_TILES do
        -- print("index: " .. i)
        -- print("row: " .. tile_loc['r'] .. " col: " .. tile_loc['c'])
        -- print("rowCheck: " .. BLACKED_OUT_TILES[i]['row'] .. " colCheck: " .. BLACKED_OUT_TILES[i]['col'])
        if tile_loc['r'] == BLACKED_OUT_TILES[i]['row'] and 
            tile_loc['c'] == BLACKED_OUT_TILES[i]['col'] then
            isNotInBlackedOutTile = false
        end
    end

    if col >= 1 and col <= BOARD_SIZE["width"] and isNotInBlackedOutTile and 
        row >= 1 and row <= BOARD_SIZE["height"] and isInSmallerRect then

        local selected_cell = GameBoard[row][col]
        local sprite = selected_cell["sprite"]
        local cell_dist_x = math.abs(row - LAST_SELECTED_CELL[2])
        local cell_dist_y = math.abs(col - LAST_SELECTED_CELL[1])
        if not sprite.touching and cell_dist_x <= 1 and cell_dist_y <= 1 then
            --print("e.x= " .. x .. " e.y=" .. y .. " col=" .. col .. " row = " .. row)
            if not selected_cell.used_letter then
                CurrentWordString = CurrentWordString .. selected_cell.letter
                selected_cell.used_letter = true
                LAST_SELECTED_CELL = {col, row} -- flipped values 
                selectSound:play()                
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
    if #CurrentWordString <= 1 then
        return false
    end
    if DICTIONARY[CurrentWordString] ~= nil then
        print(CurrentWordString)
        return true
    end
    return false
end

function updatePlayerScore()
    if PLAYER_WORDS[CurrentWordString] == nil then
        PLAYER_WORDS[CurrentWordString] = true

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
            if GAME_TIME_SEC < 5 and GAME_TIME_SEC > 4 then
                GameTimer:setColor(unpack(color.RED))
            end
            GameTimer:setText(min .. ":" .. sec)
        end

        GAME_TIME_SEC = GAME_TIME_SEC - step
    end
    LAST_TIMESTAMP = MOAISim.getDeviceTime()
end

function updateStreak(streak_amount)
    STREAK_BOX:setText("Streak: " .. streak_amount)
end

--------------------------------------------------------------------------------
-- GameOver logic
--------------------------------------------------------------------------------

function isGameOver()

end

function gameOver(game_over_results)
    SceneManager:openScene("score_scene", game_over_results)

end

--------------------------------------------------------------------------------
-- POWER UPS
--------------------------------------------------------------------------------

function execPowerUp(response)
    local power_up = { }
    power_up.type = response['power_up_type']
    power_up.player = response['player_index']
    print(power_up.type .. " " .. power_up.player)
    if power_up_type == 'blackout' then
        power_up.tile = response['tile']
        blackOutTile(power_up.tile.row, power_up_tile.col)

    elseif power_up_type == 'double_point' then
        power_up.letter = response['letter']
        -- TODO
        -- Change letter display value
    elseif power_up_type == 'shuffle' then
        power_up.new_game_board = response['new_game_board']
        -- TODO
        -- Destroy old board
        -- Recreate new board
    elseif power_up_type == 'swap' then
        power_up.tiles = response['tiles']

    elseif power_up_type == 'timer_boost' then
        power_up.new_time = response['new_time']
        -- TODO
        -- Update game timer
    end
end

function blackOutTile(tile_loc)
    local tile = { row = tile_loc['row'], col = tile_loc['col'] }
    table.insert(BLACKED_OUT_TILES, tile)
    GameBoard[tile['row']][tile['col']]["sprite"]:setColor(unpack(color.BLACK))
end

function swapTiles(tile_1, tile_2)
    local tile_1_pos_x, tile_1_pos_y = GameBoard[tile_1['row']][tile_1['col']]['levelLabel']:getPos()
    local tile_2_pos_x, tile_2_pos_y = GameBoard[tile_2['row']][tile_2['col']]['levelLabel']:getPos()
    GameBoard[tile_1['row']][tile_1['col']]['levelLabel']:setPos(tile_2_pos_x, tile_2_pos_y)
    GameBoard[tile_2['row']][tile_2['col']]['levelLabel']:setPos(tile_1_pos_x, tile_1_pos_y)
    print(tile_1_pos_x .. tile_1_pos_y)
    print(tile_2_pos_x .. tile_2_pos_y)

    local tile_1_pos_x, tile_1_pos_y = GameBoard[tile_1['row']][tile_1['col']]['sprite']:getPos()
    local tile_2_pos_x, tile_2_pos_y = GameBoard[tile_2['row']][tile_2['col']]['sprite']:getPos()
    GameBoard[tile_1['row']][tile_1['col']]['sprite']:setPos(tile_2_pos_x, tile_2_pos_y)
    GameBoard[tile_2['row']][tile_2['col']]['sprite']:setPos(tile_1_pos_x, tile_1_pos_y)    


    GameBoard[tile_1['row']][tile_1['col']], GameBoard[tile_2['row']][tile_2['col']] = 
        GameBoard[tile_2['row']][tile_2['col']], GameBoard[tile_1['row']][tile_1['col']]
end

--------------------------------------------------------------------------------
-- Common logic
--------------------------------------------------------------------------------

function showGoodWord()
    CurrentWordBox:setColor(unpack(color.LIME))
end

function showBadWord()
    print("showBadWord()")
    CurrentWordBox:setColor(unpack(color.RED))
    WORD_BOX_ANIM = Animation ({CurrentWordBox, CurrentWord}, 0.1, MOAIEaseType.SOFT_EASE_OUT)
        :moveLoc(10, 0, 0)
        :moveLoc(-20, 0, 0)
        :moveLoc(20, 0, 0)
        :moveLoc(-10, 0, 0)
    if WORD_BOX_ANIM:isRunning() == false then
        WORD_BOX_ANIM:play()
    end

end

function stopAndResetWordBox()
    if WORD_BOX_ANIM:isRunning() then
        print("stopAndResetWordBox()")
        WORD_BOX_ANIM:stop()
        CurrentWordBox:setCenterPos(GAME_WIDTH/2,  GAME_HEIGHT - GAME_WIDTH - 40)
        CurrentWord:setPos(0,  GAME_HEIGHT - GAME_WIDTH - 60)
    end

end
--------------------------------------------------------------------------------
-- Scoring / Time functions
--------------------------------------------------------------------------------

function showPointScore(player_index, amount)
    player_index = player_index + 1
    local left, top = PLAYER_LIST[player_index]:getPos()
    local score_color
    PLAYER_LIST[player_index].player_floating_score:setText("+" .. amount)

    if PLAYER_ID == player_index - 1 then
        PLAYER_LIST[player_index].player_floating_score:setColor(unpack(color.LIME))
    else
        PLAYER_LIST[player_index].player_floating_score:setColor(unpack(color.RED))
    end

    local anim1 = Animation({PLAYER_LIST[player_index].player_floating_score})
        :setVisible(true)
        :seekScl(1.2, 1.2, 1.2, 0.3, MOAIEaseType.SMOOTH)
        :seekScl(1.0, 1.0, 1.0, 0.3, MOAIEaseType.SMOOTH)
        :wait(1)
        :setVisible(false)
    anim1:play( { } )

end

function fadeOutScoreText(score_text)
    score_text:fadeOut()
end

function setGameTimer(time_in_sec)
    print(time_in_sec)
    GAME_TIME_SEC = time_in_sec
end

function printTable ( t, tableName, indentationLevel )
        
    if type ( t ) ~= "table" then
        print ( "WARNING: printTable received \"" .. type ( t ) .. "\" instead of table. Skipping." )
        return
    end
    
    local topLevel = false
    
    if ( not tableName ) and ( not indentationLevel ) then
        
        topLevel = true
        indentationLevel = 1
        
        print ( "\n----------------------------------------------------------------" )
        print ( tostring ( t ) .. "\n" )
    else
        print ( "\n" .. string.rep ( "\t", indentationLevel - 1 ) .. tableName .. " = {" )
    end
    
    if t then
        for k,v in pairs ( t ) do
            
            if ( type ( v ) == "table" ) then 
                
                printTable ( v, tostring ( k ), indentationLevel + 1 )
                
            elseif ( type ( v ) == "string" ) then
                
                print ( string.rep ( "\t", indentationLevel ) .. tostring ( k ) .. " = \"" .. tostring ( v ) .. "\"," )
            else
            
                print ( string.rep ( "\t", indentationLevel ) .. tostring ( k ) .. " = " .. tostring ( v ) .. "," )
            end
        end
    end
    
    if topLevel then
        print ( "\n----------------------------------------------------------------\n" )
    else
        print ( string.rep ( "\t", indentationLevel - 1 ) .. "},\n" )
    end
end





