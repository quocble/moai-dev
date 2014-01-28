module(..., package.seeall)

local array = require "hp/lang/array"
local table = require("hp/lang/table")
local class = require("hp/lang/class")
local string = require("hp/lang/string")
local buySound = SoundManager:getSound("./assets/A_select.ogg", 0.25)
local addCoin = SoundManager:getSound("./assets/A_addcoin.ogg", 0.25)

ANDROID_PRODUCT_IDS = { "android.test.purchased", "gold001"}
Available_Products = { 
    { pid = "gold001", price = nil, coin = 10 },
    { pid = "gold002", price = nil, coin = 20 },
    { pid = "gold003", price = nil, coin = 50 },
    { pid = "gold004", price = nil, coin = 180 },
    { pid = "gold005", price = nil, coin = 300 },
}

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

---------------------- ANDROID STORE ----------------------------
print("Starting up on:" .. MOAIEnvironment.osBrand  .. " version:" .. MOAIEnvironment.osVersion)

function M:init(params)
    self:registerBilling()
    self.testing = true
end

function M:registerBilling()
    print("Registering billing")
    if MOAIBillingAndroid then
        print("MOAIBilling on android")
        function onBillingSupported ( supported )
            print ( "onBillingSupported: " )
            if ( supported ) then
                print ( "billing is supported" )
                billing_supported = true
-- Billing v3
--                Available_Products = MOAIBilling.requestProductsSync(ANDROID_PRODUCT_IDS, MOAIBilling.BILLINGV3_PRODUCT_INAPP)
            else
                print ( "billing is not supported" )
            end
        end

        function onPurchaseResponseReceived ( code, id )
            print ( "onPurchaseResponseReceived: " .. id )
            if ( code == MOAIBilling.BILLING_RESULT_SUCCESS ) then
                print ( "purchase request received" )
                local balance = Settings:get("balance")
                local new_balance = balance + self.buying_product.coin
                Settings:set("balance", new_balance)
                Settings:save()                
                self.onPurchased()       
                self:animatePurchase(new_balance)         
            elseif ( code == MOAIBilling.BILLING_RESULT_USER_CANCELED ) then
                print ( "user canceled purchase" )
            else
                print ( "purchase failed" )
            end
        end

        function onPurchaseStateChanged ( code, id, order, user, notification, payload )
            print ( "onPurchaseStateChanged: " .. id )
            if ( code == MOAIBilling.BILLING_PURCHASE_STATE_ITEM_PURCHASED ) then
                print ( "item has been purchased" )
            elseif ( code == MOAIBilling.BILLING_PURCHASE_STATE_ITEM_REFUNDED ) then
                print ( "item has been refunded" )
            else
                print ( "purchase was canceled" )
            end
            if ( notification ~= nil ) then
                if MOAIBilling.confirmNotification ( notification ) ~= true then
                    print ( "failed to confirm notification" )
                end
            end
        end

        function onRestoreResponseReceived ( code, more, offset )
            print ( "onRestoreResponseReceived: " )
            if ( code == MOAIBilling.BILLING_RESULT_SUCCESS ) then
                print ( "restore request received" )    
                if ( more ) then
                    MOAIBilling.restoreTransactions ( offset )
                end
            else
                print ( "restore request failed" )
            end
        end

        MOAIBilling.setListener ( MOAIBilling.CHECK_BILLING_SUPPORTED, onBillingSupported )
        MOAIBilling.setListener ( MOAIBilling.PURCHASE_RESPONSE_RECEIVED, onPurchaseResponseReceived )
        MOAIBilling.setListener ( MOAIBilling.PURCHASE_STATE_CHANGED, onPurchaseStateChanged )
        MOAIBilling.setListener ( MOAIBilling.RESTORE_RESPONSE_RECEIVED, onRestoreResponseReceived )

        MOAIBilling.setPublicKey ( "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsiXcz6BfQ+OKev9n+pthQK6gqG+NeE38T/EI3MzHcC64prD+NhjLl+z1fd0y0BbnKAemzGu9JEaCJpX83Me+kbwwGRdy1OxkjtaLcB/d8/GAfftdTrjuZFZlTrw/CU5hB0tvbkjVADrh6iOjBOx+KOEiQz2dV2e1kxUNYzTi1i9aoWt/s5X/j8WuLD1gP8Fe2TEpTHlZMMmT/LjEXeSayv8ckpenkUSpPY7dhRNxXGuz7U97duCw2ujWupNjc6unpeFloVIWs0oG8giXgwsMvOZ19P2iujFTtt4lAEvNNUlTfdNhOpaLJ/JMU8368SoUlW+CPfvH/oFzg8d7yyNk2QIDAQAB" )

        if not MOAIBilling.setBillingProvider ( MOAIBilling.BILLING_PROVIDER_GOOGLE ) then
            print ( "unable to set billing provider" )
        else
            if not MOAIBilling.checkBillingSupported () then
                print ( "check billing supported failed" )
            end
        end
    end
end
-----------------------------------------------------------------

function M:updateBilling()
    print("update billing")
    for i, product in ipairs(Available_Products) do
        if i <= #self.rows then
            local row = self.rows[i]
            row.visible(true)

            if product["price"] then
                row.price_label:setText("" .. product["price"])
            else
                row.price_label:setText("")
            end
            
            row.coin_label:setText("" .. product["coin"])
            row.buy_button.data = product
        end
    end
end

function M:animatePurchase(new_balance)

    local superParent = self.current_panel:getParent()
    local filterMesh = Sprite {
        texture = "./assets/gray_40.png", 
        size = { superParent:getWidth() , superParent:getHeight() } ,
        pos = { 0, 0 },
        parent = superParent
    }  

    local CurrentWordBox = NinePatch {
        texture = "./assets/btn_down.png", 
        size = { 120, 40},
        align = {"center", "center"},
        parent = superParent
    }

    local CurrentWord = TextLabel {
        text = "" .. new_balance,
        size = {120, 40},
        color = string.hexToRGB( "#0066CC", true ),
        align = {"center", "center"},
        parent = superParent
    }
    CurrentWordBox:setStretchColumns(0.15, 0.70, 0.15)

    local xcenter, ycenter = superParent:getWidth()/2, superParent:getHeight()/2
    CurrentWordBox:setCenterPos(xcenter, ycenter)
    CurrentWord:setCenterPos(xcenter, ycenter)

    textBoxAnim = Animation({CurrentWord})
        :setScl(0 ,1 , 1)
        :fadeIn(0.10)
        :seekScl(1, 1, 0, 1.0)
        :wait(1)
        :fadeOut()

    backgroundAnim = Animation({CurrentWordBox})
        :fadeIn(0.10)
        :wait(2.7)
        :fadeOut()

    anim1 = Animation():parallel(
            textBoxAnim,
            backgroundAnim)       

    addCoin:play()

    function completeHandler()
        superParent:removeChild(CurrentWordBox)
        superParent:removeChild(CurrentWord)
        superParent:removeChild(filterMesh)
    end
    anim1:play({onComplete = completeHandler})
end

function M:getPanel(onBackClick, onPurchased) 

    self.onPurchased = onPurchased

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
    self.rows = {}

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

        local purchase_row = {
            coin_sprite = coin_sprite,
            coin_label = coin_label,
            buy_button = buy_button,
            price_label = price_label,
        }        

        purchase_row.visible = function(visible)
            coin_sprite:setVisible(visible)
            coin_label:setVisible(visible)            
            buy_button:setVisible(visible)
            price_label:setVisible(visible)            
        end

        local function buyButton(e)

            local product_id = e.target.data.pid
            if self.testing then
                product_id = "android.test.purchased"
            end

            print("Buying product " .. product_id)
            self.buying_product = e.target.data
            buySound:play()

            if MOAIBilling.requestPurchase ( product_id, '' ) then
                print ( "purchase successfully requested" )
            else
                print ( "requesting purchase failed" )
            end
        end

        buy_button:setOnClick(buyButton)        
        purchase_row.visible(false)

        table.insert(self.rows, purchase_row)
    end

    self:updateBilling()
    self.current_panel = panel
	return panel
end

return M