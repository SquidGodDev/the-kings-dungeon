local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Chest').extends(gfx.sprite)

function Chest:init(x, y, entity)
    self.chestClosedImage = gfx.image.new("images/entities/chestClosed")
    self.chestOpenImage = gfx.image.new("images/entities/chestOpen")
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.Interactable)

    self.entity = entity
    local fields = entity.fields
    self.flip = gfx.kImageUnflipped
    if fields.facingRight then
        self.flip = gfx.kImageFlippedX
    end
    self.open = fields.open
    if fields.open then
        self:setImage(self.chestOpenImage, self.flip)
    else
        self:setImage(self.chestClosedImage, self.flip)
    end

    self.contents = fields.contents

    self:setCollideRect(0, 0, 32, 32)

    self.interactable = not self.open
end

function Chest:interact(player)
    if self.open then
        return
    end
    player.dialog:unlockAbility(self.contents)
    self:setImage(self.chestOpenImage, self.flip)
    self.interactable = false
    self.open = true
    self.entity.fields.open = true
end
