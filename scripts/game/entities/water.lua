local pd <const> = playdate
local gfx <const> = playdate.graphics

local splashSound <const> = pd.sound.sampleplayer.new("sound/entities/splash")

class('Water').extends(gfx.sprite)

function Water:init(x, y, entity, waterfallList)
    local waterSize = entity.size
    self.widthBuffer = 0
    self.waterWidth = waterSize.width + self.widthBuffer
    self.waterHeight = waterSize.height
    self.waterfallPos = {}
    if waterfallList then
        for i=1, #waterfallList do
            local waterfall = waterfallList[i]
            local waterfallPos = waterfall.position
            local adjustedX = waterfallPos.x + 8 - x + self.widthBuffer
            if adjustedX >= 0 and adjustedX <= self.waterWidth then
                table.insert(self.waterfallPos, adjustedX)
            end
            Waterfall(waterfallPos.x, waterfallPos.y, waterfall)
        end
    end

    local fluidOptions = {
        tension = 0.08,
        dampening = 0.0025,
        speed = 0.2,
        vertex_count = 20
    }
    self.heightBuffer = 32

    self.fluid = Fluid.new(0, self.heightBuffer, self.waterWidth, self.waterHeight, fluidOptions)

    self:setZIndex(Z_INDEXES.WATER)
    self:setCenter(0, 0)
    self:moveTo(x - self.widthBuffer/2, y - 24)
    self:add()

    local touchVelocity = 4
    for i=1, #self.waterfallPos do
        self.fluid:touch(self.waterfallPos[i], touchVelocity)
    end
    local touchTimer = pd.timer.new(400, function()
        for i=1,#self.waterfallPos do
            local pos = self.waterfallPos[i]
            self.fluid:touch(pos, touchVelocity)
            self.fluid:touch(pos + 2, touchVelocity)
            self.fluid:touch(pos - 2, touchVelocity)
        end
    end)
    touchTimer.repeats = true

    self.playerTouchOnCooldown = false
    self.playerTouchCooldownTime = 500

    self.clipWidth = 1
    self:setClipRect(self.clipWidth + self.x, self.y, self.waterWidth - self.clipWidth*2, self.waterHeight)
end

function Water:update()
    self.fluid:update()
    local fluidImage = gfx.image.new(self.waterWidth, self.waterHeight + self.heightBuffer)
    gfx.pushContext(fluidImage)
        gfx.setLineWidth(2)
        gfx.setColor(gfx.kColorWhite)
        self.fluid:draw()
    gfx.popContext()
    self:setImage(fluidImage)
    if not self.playerTouchOnCooldown then
        local queriedSprites = gfx.sprite.querySpritesInRect(self.x, self.y + self.heightBuffer, self.waterWidth, 8)
        for i=1,#queriedSprites do
            local curSprite = queriedSprites[i]
            if curSprite:getTag() == TAGS.Player then
                if curSprite.yVelocity >= 1 then
                    splashSound:play()
                    self.playerTouchOnCooldown = true
                    self.fluid:touch(curSprite.x - self.x, 16)
                    pd.timer.performAfterDelay(self.playerTouchCooldownTime, function()
                        self.playerTouchOnCooldown = false
                    end)
                end
            end
        end
    end
end
