module(..., package.seeall)

local array = require "hp/lang/array"
local table = require("hp/lang/table")
local class = require("hp/lang/class")
local string = require("hp/lang/string")

local M = class()

local PANEL_STYLE = {
    normal = {
        backgroundSkin = "./assets/panel_store.png",
        backgroundSkinClass = NinePatch,
        backgroundColor = {1, 1, 1, 1.0},
    },
    disabled = {
        backgroundColor = {0.5, 0.5, 0.5, 1},
    },
}

local BACK_BUTTON_STYLE = {
    normal = {
        skin = "./assets/panel_back_btn.png",
        skinColor = {1, 1, 1, 1.0},
    },
    selected = {
        skin = "./assets/panel_back_btn.png",
        skinColor = {0.5, 0.5, 0.5, 1.0},
    },
    over = {
        skin = "./assets/panel_back_btn.png",
        skinColor = {0.5, 0.5, 0.5, 0.8},
    },
    disabled = {
        skin = "./assets/panel_back_btn.png",
    },
}

local BUY_BUTTON_STYLE = {
    normal = {
        skin = "./assets/buy_btn.png",
        skinColor = {1, 1, 1, 1.0},
    },
    selected = {
        skin = "./assets/buy_btn.png",
        skinColor = {0.5, 0.5, 0.5, 1.0},
    },
    over = {
        skin = "./assets/buy_btn.png",
        skinColor = {0.5, 0.5, 0.5, 0.8},
    },
    disabled = {
        skin = "./assets/buy_btn.png",
    },
}
function M:getPanel(onBackClick) 
	local panel = Panel {
	    name = "panel",
	    size = { 320, 370},
        styles = { PANEL_STYLE },
	}

    local panel_title = TextLabel {
        text = "Purchase Gold",
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
        styles = { BACK_BUTTON_STYLE },
    }

    local ROW_HEIGHT = 61
    local TOP_MARGIN = 50 
    for i=0, 4 do

    	local top = TOP_MARGIN + (i* ROW_HEIGHT) + (ROW_HEIGHT/2)

		local coin_sprite = Sprite {
	    	texture = "./assets/coin.png", 
	    	parent = panel,
	    	size = { 52/2, 52/2 }, 
	    	pos = { 45 ,  top - (26/2)}
		}

	    local coin_label = TextLabel {
	        text = "x20",
	        size = {320, 45},
	        parent = panel,
	        color = string.hexToRGB( "#FFFFFF", true ),
	        pos = {85, top - (45/2) },
	        textSize = 16,
	        align = {"left", "center"}
	    }

	    local buy_button = Button {
	        name = "startButton",
	        onClick = onBuyButton,
	        size = { 118, 31 },
	        parent = panel,
	        pos = { 160, top - (31/2)},
	        text = "",
	        styles = { BUY_BUTTON_STYLE },
	    }

	    local price_label = TextLabel {
	        text = "$0.99",
	        size = {62, 45},
	        parent = panel,
	        color = string.hexToRGB( "#FFFFFF", true ),
	        pos = {160, top - (45/2) },
	        textSize = 12,
	        align = {"right", "center"}
	    }
    end

	return panel
end

return M