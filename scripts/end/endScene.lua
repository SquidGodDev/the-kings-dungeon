local pd <const> = playdate
local gfx <const> = playdate.graphics

local util <const> = utilities

class('EndScene').extends(gfx.sprite)

function EndScene:init()
    pd.setMenuImage(nil)
    EndMusic:play(0)
	GameMusic:stop()
    -- Create end scene
    local blackImage = gfx.image.new(400, 240, gfx.kColorBlack)
    gfx.sprite.setBackgroundDrawingCallback(function()
        blackImage:draw(0, 0)
    end)

    local collectedCheese = CHEESE
    local maxCheese = MAX_CHEESE
    local largeFont = gfx.font.new("images/fonts/m5x7-24")
    self.animationsFinished = false

    local gameEndTextImage = gfx.image.new("images/ui/gameEndText")
    local gameEndTextSprite = gfx.sprite.new(gameEndTextImage)
    gameEndTextSprite:add()
    gameEndTextSprite:moveTo(200, 70)
    util.animateInSprite(gameEndTextSprite, 1500, false, 0)

    local cheeseCollectedTextImage = gfx.image.new("images/ui/cheeseCollectedText")
    local cheeseCollectedTextSprite = gfx.sprite.new(cheeseCollectedTextImage)
    cheeseCollectedTextSprite:add()
    cheeseCollectedTextSprite:moveTo(200, 140)
    util.animateInSprite(cheeseCollectedTextSprite, 1500, false, 1500)

    local cheeseCountSprite = util.centeredTextSpriteFont(tostring(collectedCheese) .. " / " .. tostring(maxCheese), largeFont)
    cheeseCountSprite:add()
    cheeseCountSprite:moveTo(200, 190)
    local moveTimer = util.animateInSprite(cheeseCountSprite, 1500, false, 3000)
    moveTimer.timerEndedCallback = function()
        self.animationsFinished = true
    end

    self:add()
end

function EndScene:update()
    if pd.buttonJustPressed(pd.kButtonA) and self.animationsFinished then
        SCENE_MANAGER:switchScene(TitleScene)
    end
end