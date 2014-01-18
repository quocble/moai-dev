--------------------------------------------------------------------------------
-- This is a standard GUI theme.
-- Can not dynamically change the theme.
--------------------------------------------------------------------------------

-- import
local Sprite            = require "hp/display/Sprite"
local NinePatch         = require "hp/display/NinePatch"

-- module define
local M                 = {}

M.Button = {
    normal = {
        skin = "./assets/skins/button-normal.png",
        skinClass = NinePatch,
        skinColor = {1, 1, 1, 1},
        font = "VL-PGothic",
        textSize = 24,
        textColor = {0.0, 0.0, 0.0, 1},
        textPadding = {10, 5, 10, 8},
    },
    selected = {
        skin = "./assets/skins/button-selected.png",
    },
    over = {
        skin = "./assets/skins/button-over.png",
    },
    disabled = {
        skin = "./assets/skins/button-disabled.png",
        textColor = {0.5, 0.5, 0.5, 1},
    },
}

M.Joystick = {
    normal = {
        baseSkin = "./assets/skins/joystick_base.png",
        knobSkin = "./assets/skins/joystick_knob.png",
        baseColor = {1, 1, 1, 1},
        knobColor = {1, 1, 1, 1},
    },
    disabled = {
        baseColor = {0.5, 0.5, 0.5, 1},
        knobColor = {0.5, 0.5, 0.5, 1},
    },
}

M.Panel = {
    normal = {
        backgroundSkin = "./assets/skins/panel.png",
        backgroundSkinClass = NinePatch,
        backgroundColor = {1, 1, 1, 1},
    },
    disabled = {
        backgroundColor = {0.5, 0.5, 0.5, 1},
    },
}

M.MessageBox = {
    normal = {
        backgroundSkin = "./assets/skins/panel.png",
        backgroundSkinClass = NinePatch,
        backgroundColor = {1, 1, 1, 1},
        font = "VL-PGothic",
        textPadding = {20, 20, 15, 15},
        textSize = 20,
        textColor = {0, 0, 0, 1},
    },
    disabled = {
        backgroundColor = {0.5, 0.5, 0.5, 1},
        textColor = {0.2, 0.2, 0.2, 1},
    },
}

M.Slider = {
    normal = {
        bg = "./assets/skins/slider_background.png",
        thumb = "./assets/skins/slider_thumb.png",
        progress = "./assets/skins/slider_progress.png",
        color = {1, 1, 1, 1},
    },
    disabled = {
        color = {0.5, 0.5, 0.5, 1},
    },
}

M.DialogBox = {
    normal = {
        backgroundSkin = "./assets/skins/dialog.png",
        backgroundSkinClass = NinePatch,
        backgroundColor = {1, 1, 1, 1},
        font = "VL-PGothic",
        textPadding = {5, 5, 5, 5},
        textSize = 14,
        textColor = {1, 1, 1, 1},
        titleFont = "VL-PGothic",
        titlePadding = {0, 0, 0, 0},
        titleSize = 20,
        titleColor = {1, 1, 0, 1},
        iconPadding = {5, 5, 0, 5},
        iconScaleFactor = 0.5,
        iconInfo = "./assets/skins/info.png",
        iconConfirm = "./assets/skins/okay.png",
        iconWarning = "./assets/skins/warning.png",
        iconError = "./assets/skins/error.png",
        buttonsPadding = {5, 0, 5, 5},
    },
    disabled = {
        backgroundColor = {0.5, 0.5, 0.5, 1},
        textColor = {0.2, 0.2, 0.2, 1},
        titleColor = {0.2, 0.2, 0, 1},
    },
}

return M