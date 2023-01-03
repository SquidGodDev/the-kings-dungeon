local pd <const> = playdate
local gfx <const> = playdate.graphics
local util <const> = utilities

local cheeseImage <const> = gfx.image.new("images/entities/cheese")

class('Cheese').extends(gfx.sprite)

function Cheese:init(x, y, entity)
    if entity.fields.pickedUp then
        return
    end
    self.bobOffset = 4
    self.baseY = y - self.bobOffset - 4

    self.entity = entity
    self:setImage(cheeseImage)
    self:setCenter(0, 0)
    self:moveTo(x - 4, self.baseY)
    local collideRectBuffer = 4
    self:setCollideRect(collideRectBuffer, collideRectBuffer, 32, 32)
    self:setTag(TAGS.Pickup)
    self:setZIndex(Z_INDEXES.PICKUP)
    self:add()

    self.bobTimer = pd.timer.new(3000, 0, 2*3.14)
    self.bobTimer.updateCallback = function(timer)
        self:moveTo(self.x, self.baseY + self.bobOffset * math.sin(timer.value))
    end
    self.bobTimer.repeats = true

    self.pickupSound = pd.sound.sampleplayer.new("sound/entities/pickup")
end

function Cheese:pickUp()
    self.pickupSound:play()
    self.entity.fields.pickedUp = true
    self.bobTimer:remove()
    self:remove()
    local smokeSprite = util.animatedSprite("images/entities/smallSmokeBurst-table-85-89", 20, false)
    smokeSprite:moveTo(self.x + 20, self.y + 20)
    smokeSprite:setZIndex(Z_INDEXES.PICKUP)
    CHEESE += 1
end