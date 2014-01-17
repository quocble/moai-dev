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

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

-- init random seed
math.randomseed(os.time())

--------------------------------------------------------------------------------
-- Create
--------------------------------------------------------------------------------

function onCreate(params)
    -- makePhysicsWorld()
    
    -- makeGameLayer()
    -- makePlayer()
    -- makeFloors()
    -- makeWalls()
    
    -- makeGuiView()

    makeBoard()
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
    
    -- updatePlayer()
    -- updateFloors()
    -- updateScore()
    -- updateLevel()
end

function onTouchDown(e)
    local scale = guiView:getViewScale()
    e.x = e.x / scale
    e.y = e.y / scale 

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

    guiView = Layer()
    guiView:setScene(scene)

    local floor = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {"#CB44F3", "#8FC7CB", 90})
    floor:setLayer(guiView)

    local bag = buildAndShuffle()
    local total_letters = BOARD_SIZE["width"] * BOARD_SIZE["height"]

    GameBoard = {}
    for i=1,BOARD_SIZE["width"] do
      GameBoard[i] = {}     -- create a new row
      for j=1,BOARD_SIZE["height"] do
        local l = table.remove(bag, 1)
        GameBoard[i][j] = { col = i, row = j, letter = l }
      end
    end

    for c=1, BOARD_SIZE["width"] do
        for r=1, BOARD_SIZE["height"] do
            local p = GameBoard[c][r]    
            makeLetter(p, c, r)
        end
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

        local selected_cell = GameBoard[col][row]
        local sprite = selected_cell["sprite"]
        if not sprite.touching then
            print("e.x= " .. x .. " e.y=" .. y .. " col=" .. col .. " row = " .. row)
            sprite:setTexture("./assets/word_tile_on.png")
            sprite.action = sprite:seekScl(1.2, 1.2, 1.2, 0.25) 
            sprite.touching = true

            resetScale(sprite, false)
        end
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


