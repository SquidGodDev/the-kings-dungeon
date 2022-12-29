local pd <const> = playdate
local gfx <const> = playdate.graphics

local querySpritesInRect <const> = gfx.sprite.querySpritesInRect

class('Gate').extends(gfx.sprite)

function Gate:init(x, y, gateEntity)
    local gateImage = gfx.image.new("images/entities/gate")
    self:setImage(gateImage)
    self:setZIndex(Z_INDEXES.GATE)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setCollideRect(0, 0, self:getSize())

    self.queryX = x - 32
    self.queryY = y
    self.queryWidth = 96
    self.queryHeight = 64

    self.maxHeight = y - 64

    self.ticksPerRevolution = 6
    self.crankMoveAmount = 1

    self.crankIndicator = CrankIndicator()

    self.open = false
    self.gateEntity = gateEntity
    if gateEntity.fields.open then
        self.open = true
        self:moveTo(self.x, self.maxHeight)
    end
end

function Gate:update()
    local overlappingSprites = querySpritesInRect(self.queryX, self.queryY, self.queryWidth, self.queryHeight)
    local playerDetected = false
    local playerSprite
    for i=1, #overlappingSprites do
        local detectedSprite = overlappingSprites[i]
        if detectedSprite:getTag() == TAGS.Player then
            playerDetected = true
            playerSprite = detectedSprite
        end
    end

    if playerDetected then
        local crankTicks = pd.getCrankTicks(self.ticksPerRevolution)
        if crankTicks ~= 0 then
            self:moveBy(0, -self.crankMoveAmount)
            if self.y <= self.maxHeight then
                self:moveTo(self.x, self.maxHeight)
            end
            self.gateEntity.fields.open = true
        end

        if not self.open then
            self.crankIndicator:setActive(true, playerSprite)
        end
    else
        self.crankIndicator:setActive(false)
    end
end