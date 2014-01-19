module(..., package.seeall)

string = require("hp/lang/string")

local GAME_WIDTH = Application.viewWidth
local GAME_HEIGHT = Application.viewHeight

    -- param ex
        -- { 
        -- players = [ 
        --     { name = "Jon", score = "5000" }
        --     { name = "Bob", score = "4000" }
        --	   { name = "Jan", score = "3000" }
        -- most_words = { name = "Jon", count = 50 },
        -- longest_streak = { name = "Jan", count = 10 }, 
        -- longest_word = { name = "Bob", word = "Longest_Word" } 
        -- }
local PLAYER_LIST = { }
local NUMBER_OF_PLAYERS = 0

function onCreate(params)
	-- params: game end results {"score": [{"score": 50}, {"score": 80}], "msgtype": "game_over"}
    local test_results = {
        msgtype = "game_over",  
        players = { 
            { name = "Jon", score = "51000" },
            { name = "Bob", score = "4000" },
            { name = "Jan", score = "300" },
            { name = "Gregory", score = 0 }
        },
        most_words = { name = "Jon", count = "50" }, 
        longest_streak = { name = "Jan", streak = "7" }, 
        longest_word = { name = "Bob", word = "Longest_Word" }
    }
 	params = test_results
    NUMBER_OF_PLAYERS = table.getn(params.players)
    PLAYER_LIST = params.players

	makeBackground()
	makeTitleBar()
	makePlayerRanks(params)
	makeAchievements(params)
	makeButtons()
	makeRankingPedestal(params)

end

function makeBackground()
    resultsView = Layer()
    resultsView:setScene(scene)

    local floor = Mesh.newRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {"#CB44F3", "#8FC7CB", 90})
    floor:setLayer(resultsView)
end

function makeTitleBar()
    results_title = TextLabel {
		text = "Results",
		size = {GAME_WIDTH, 40},
		layer = resultsView,
        color = string.hexToRGB( "#FFFFFF", true ),		
		pos = {0, 20},
		align = {"center", "top"}
		}
end

function makePlayerRanks(params)
	player_names_list = ""
	scores_list = ""
    for p=0, NUMBER_OF_PLAYERS - 1 do
    	print(PLAYER_LIST[p + 1].name .. PLAYER_LIST[p + 1].score)
    	local name = (p+1) .. ". " .. PLAYER_LIST[p + 1].name .. "\n"
    	local score = PLAYER_LIST[p + 1].score .. "\n"
    	player_names_list = player_names_list .. name
    	scores_list = scores_list .. score
	end

	print(player_names_list)
	print(scores_list)

	player_names_display = TextLabel {
        text = player_names_list,
        pos = {20, 50},
        layer = resultsView,
        color = string.hexToRGB( "#FFFFFF", true ),
        align = {"left", "center"}
	}

	player_scores_display = TextLabel {
		text = scores_list,
		pos = {GAME_WIDTH - 100, 50},
		layer = resultsView,
		color = string.hexToRGB( "#FFFFFF", true ),
		align = {"right", "center"}
	}

	player_names_display:fitSize()
	player_scores_display:fitSize()

end

function makeAchievements(params)

    print("most_words: " .. params["most_words"].name)
    print("longest_streak: " .. params["longest_streak"].name)
    print("longest_word.name: " .. params["longest_word"].name)
    print("longest_word.word: " .. params["longest_word"].word)

    local achievements_text = ""

    achievements_text = "Most Words:  " .. params["most_words"].count .. " (" .. params["most_words"].name .. ")\n"
    achievements_text = achievements_text .. "Longest Word: " .. params["longest_word"].word .. " (" .. params["longest_word"].name .. ")\n"
    achievements_text = achievements_text .. "Longest Streak: " .. params["longest_streak"].streak .. " (" .. params["longest_streak"].name .. ")"

	local achievements_label = TextLabel {
		text = achievements_text,
		textSize = 16,
		pos = {10, GAME_HEIGHT/2 - 90},
		layer = resultsView,
		color = string.hexToRGB("#FFFFFF", true),
		align = {"left", "center"}
	}
	achievements_label:fitSize()
end	

function makeButtons()

	local view = View {
		scene = scene,
		pos = {0, GAME_HEIGHT/2},
		size = { GAME_WIDTH, 55 },
		layout = {
			HBoxLayout {
				align = {"center", "center"},
				padding = {0, 0, 0, 0},
				gap = {20, 10},
			},
		},
		children = {{
			Button {
				name = "replayButton",
				text = "Replay",
				onClick = onReplayClick,
				size = {GAME_WIDTH/2 - 40, 55}
			},

			Button {
				name = "menuButton",
				text = "Menu",
				onClick = onMenuClick,
				size = {GAME_WIDTH/2 - 40, 55},
			},
		}},
	}

end

function makeRankingPedestal(params)

end

function onReplayClick()
    SceneManager:closeScene()
    SceneManager:closeScene()
end

function onMenuClick()
    SceneManager:closeScene()
    SceneManager:closeScene()
    SceneManager:closeScene()
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
