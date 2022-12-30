
local pd <const> = playdate
local gfx <const> = playdate.graphics

local util <const> = utilities

class('DestructableBlock').extends(gfx.sprite)

function DestructableBlock:init(x, y, entity)
    if entity.fields.destroyed then
        return
    end
    self.entity = entity
    local blockImage = gfx.image.new("images/entities/destructableBlock")
    self:setImage(blockImage)
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.Destructable)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()
end

function DestructableBlock:destroy()
    self.entity.fields.destroyed = true
    self:remove()
    local smokeSprite = util.animatedSprite("images/entities/smallSmokeBurst-table-85-89", 20, false)
    smokeSprite:moveTo(self.x + 16, self.y + 16)
end
