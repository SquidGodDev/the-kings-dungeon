local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Water').extends(gfx.sprite)

function Water:init(x, y, entity, waterfallList)
    local waterSize = entity.size
    self.widthBuffer = 16
    self.waterWidth = waterSize.width + self.widthBuffer
    self.waterHeight = waterSize.height
    self.waterfallPos = {}
    if waterfallList then
        for i=1, #waterfallList do
            local waterfall = waterfallList[i]
            local waterfallPos = waterfall.position
            table.insert(self.waterfallPos, waterfallPos.x + 8 - x + self.widthBuffer)
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
            self.fluid:touch(self.waterfallPos[i], touchVelocity)
            self.fluid:touch(self.waterfallPos[i] + 2, touchVelocity)
            self.fluid:touch(self.waterfallPos[i] - 2, touchVelocity)
        end
    end)
    touchTimer.repeats = true

    self.playerTouchOnCooldown = false
    self.playerTouchCooldownTime = 500
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
        local queriedSprites = gfx.sprite.querySpritesInRect(self.x, self.y + 12, self.waterWidth, 8)
        for i=1,#queriedSprites do
            local curSprite = queriedSprites[i]
            if curSprite:getTag() == TAGS.Player then
                self.playerTouchOnCooldown = true
                self.fluid:touch(curSprite.x - self.x, 16)
                pd.timer.performAfterDelay(self.playerTouchCooldownTime, function()
                    self.playerTouchOnCooldown = false
                end)
            end
        end
    end
end