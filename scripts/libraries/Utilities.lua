local pd <const> = playdate
local gfx <const> = playdate.graphics

utilities = {}

function utilities.centeredTextSprite(text, drawMode)
    local _drawMode = drawMode or gfx.kDrawModeFillWhite
    local descriptionImage = gfx.image.new(gfx.getTextSize(text))
    gfx.pushContext(descriptionImage)
        gfx.setImageDrawMode(_drawMode)
        gfx.drawText(text, 0, 0)
    gfx.popContext()
    return gfx.sprite.new(descriptionImage)
end

function utilities.centeredTextImage(text, drawMode)
    local _drawMode = drawMode or gfx.kDrawModeFillWhite
    local descriptionImage = gfx.image.new(gfx.getTextSize(text))
    gfx.pushContext(descriptionImage)
        gfx.setImageDrawMode(_drawMode)
        gfx.drawText(text, 0, 0)
    gfx.popContext()
    return descriptionImage
end

function utilities.addSpriteFromImage(imagePath)
    local spriteImage = gfx.image.new(imagePath)
    local sprite = gfx.sprite.new(spriteImage)
    sprite:add()
    return sprite
end

function utilities.centeredTextSpriteFont(text, font, drawMode)
    local _drawMode = drawMode or gfx.kDrawModeFillWhite
    local descriptionImage = gfx.image.new(font:getTextWidth(text), font:getHeight())
    gfx.pushContext(descriptionImage)
        gfx.setImageDrawMode(_drawMode)
        font:drawText(text, 0, 0)
    gfx.popContext()
    return gfx.sprite.new(descriptionImage)
end

function utilities.animateInSprite(sprite, moveTime, movingDown, delay, easingFunction)
    local _easingFunction = easingFunction or pd.easingFunctions.inOutCubic
    local _delay = delay or 0
    local endValue = sprite.y
    local startValue = endValue - 240
    if not movingDown then
        startValue = endValue + 240
    end
    sprite:moveTo(sprite.x, startValue)
    local moveTimer = pd.timer.new(moveTime, sprite.y, endValue, _easingFunction)
    moveTimer:pause()
    pd.timer.performAfterDelay(_delay, function()
        moveTimer:start()
        moveTimer.updateCallback = function(timer)
            sprite:moveTo(sprite.x, timer.value)
        end
    end)
    return moveTimer
end

function utilities.animatedSprite(imageTablePath, delay, shouldLoop)
    local imageTable = gfx.imagetable.new(imageTablePath)
    local animationLoop = gfx.animation.loop.new(delay, imageTable, shouldLoop)
    local animatedSprite = gfx.sprite.new(animationLoop:image())
    animatedSprite.animationLoop = animationLoop
    animatedSprite:add()
    function animatedSprite:update()
        self:setImage(self.animationLoop:image())
        if not self.animationLoop:isValid() and not self.shouldLoop then
            self:remove()
        end
    end
    return animatedSprite
end
