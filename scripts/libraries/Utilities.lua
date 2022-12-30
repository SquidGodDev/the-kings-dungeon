local pd <const> = playdate
local gfx <const> = playdate.graphics

utilities = {}

function utilities.centeredTextSprite(text)
    local descriptionImage = gfx.image.new(gfx.getTextSize(text))
    gfx.pushContext(descriptionImage)
        gfx.drawText(text, 0, 0)
    gfx.popContext()
    return gfx.sprite.new(descriptionImage)
end

function utilities.centeredTextImage(text)
    local descriptionImage = gfx.image.new(gfx.getTextSize(text))
    gfx.pushContext(descriptionImage)
        gfx.drawText(text, 0, 0)
    gfx.popContext()
    return descriptionImage
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
