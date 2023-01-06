local pd <const> = playdate
local gfx <const> = playdate.graphics

local util <const> = utilities

class('TitleScene').extends(gfx.sprite)

function TitleScene:init()
    local systemMenu = pd.getSystemMenu()
    systemMenu:removeAllMenuItems()
    -- systemMenu:addCheckmarkMenuItem("Speedrun Mode", SPEED_RUN_MODE, function(flag)
    --     SPEED_RUN_MODE = flag
    -- end)

    TitleMusic:play(0)
	EndMusic:stop()

    local backgroundImage = gfx.image.new("images/title/titleBackground")
    gfx.sprite.setBackgroundDrawingCallback(function()
        backgroundImage:draw(0, 0)
    end)

    local fadedImage = gfx.image.new("images/title/faded")
    local fadedSprite = gfx.sprite.new(fadedImage)
    fadedSprite:moveTo(200, 120)
    fadedSprite:setZIndex(90)
    fadedSprite:add()

    local titleSprite = util.addSpriteFromImage("images/title/title")
    titleSprite:moveTo(200, 90)
    titleSprite:setZIndex(100)
    util.animateInSprite(titleSprite, 1500, false)

    -- local promptSprite = util.addSpriteFromImage("images/title/startPrompt")
    local promptSprite = Menu(200, 188)
    -- promptSprite:moveTo(200, 188)
    promptSprite:setZIndex(150)
    util.animateInSprite(promptSprite, 1500, false, 500)

    local waterEntity = {size = {width = 320, height = 128}}
    local waterfallEntity = {position = {x = 224, y = 0},size = {width = 32, height = 128}}
    Water(32, 96, waterEntity, {waterfallEntity})
    self:add()
end
