--------------------------------------------------------------------------------
-- This is a class to draw the texture. <br>
-- Base Classes => DisplayObject, TextureDrawable, Resizable <br>
--------------------------------------------------------------------------------

-- import
local table                     = require "hp/lang/table"
local class                     = require "hp/lang/class"
local DisplayObject             = require "hp/display/DisplayObject"
local TextureDrawable           = require "hp/display/TextureDrawable"
local Resizable                 = require "hp/display/Resizable"

-- class
local M                         = class(DisplayObject, Resizable)
local shader = nil

--------------------------------------------------------------------------------
-- The constructor.
-- @param params (option)Parameter is set to Object.<br>
--------------------------------------------------------------------------------
function M:init(params)
    DisplayObject.init(self)
    
    params = params or {}

    local deck = MOAIGfxQuad2D.new()
    deck:setUVRect(0, 0, 1, 1)
    
    self:setDeck(deck)
    self.deck = deck

	self.multitexture = MOAIMultiTexture.new ()
	self.multitexture:reserve ( 3 )

    if shader == nil then
        print("Loading shaders")
        file = assert ( io.open ( './assets/shader.vsh', mode ))
        vsh = file:read ( '*all' )
        file:close ()

        file = assert ( io.open ( './assets/shader.fsh', mode ))
        fsh = file:read ( '*all' )
        file:close ()

    	shader = MOAIShader.new ()
    	shader:reserveUniforms ( 3 )
    	shader:declareUniformSampler ( 1, 'baseSampler', 1 )
    	shader:declareUniformSampler ( 2, 'maskSampler', 2 )
    	shader:declareUniformSampler ( 3, 'borderSampler', 3 )
    	shader:setVertexAttribute ( 1, 'position' )
    	shader:setVertexAttribute ( 2, 'uv' )
    	shader:setVertexAttribute ( 3, 'color' )
    	shader:load ( vsh, fsh )
    end


    self.deck:setTexture ( self.multitexture )
	self.deck:setShader ( shader )	
    self.texture_list = {}
	-- self:setTexture(mask_img, "mask")
	-- self:setTexture(border_img, "border")
	-- self:setTexture(main_img, "main")

    self:copyParams(params)
end

function M:setMask(mask)
    self:setTexture(mask, "main")
end

function M:setMain(mask)
    self:setTexture(mask, "mask")
end

function M:setBorder(mask)
    self:setTexture(mask, "border")
end

function M:setTexture(texture, texture_type)
    assert(texture, "texture nil value!")
    
    print ("load texture " .. texture)
    if type(texture) == "string" then
        texture = TextureManager:request(texture)
    end

    if self.texture_list[texture_type] == texture then
        return
    end
    
    local left, top = self:getPos()
    local resize = self.texture_list[texture_type] == nil and self.setSize ~= nil
    self.texture_list[texture_type] = texture

    if self.texture == nil then
        self.texture = texture
    end

    if texture_type == "mask" then
        self.multitexture:setTexture ( 2, texture )
	elseif texture_type == "border" then
        self.multitexture:setTexture ( 3, texture )
    elseif texture_type == "main" then
        self.multitexture:setTexture ( 1, texture )
    end

    self:setPos(left, top)
    
    if resize then
        local w, h = texture:getSize()
        self:setSize(w, h)
    end
end

return M