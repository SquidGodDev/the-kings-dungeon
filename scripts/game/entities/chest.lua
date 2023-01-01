local pd <const> = playdate
local gfx <const> = playdate.graphics

local chestOpenSound <const> = pd.sound.sampleplayer.new("sound/entities/chestOpen")

class('Chest').extends(gfx.sprite)

function Chest:init(x, y, entity)
    self.chestClosedImage = gfx.image.new("images/entities/chestClosed")
    self.chestOpenImage = gfx.image.new("images/entities/chestOpen")
    self:setZIndex(Z_INDEXES.CHEST)
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

    self.ability = fields.ability

    self:setCollideRect(0, 0, 32, 32)

    self.interactable = not self.open
end

function Chest:interact(player)
    if self.open then
        return
    end

    chestOpenSound:play()
    player.dialog:unlockAbility(self.ability)
    self:setImage(self.chestOpenImage, self.flip)
    self.interactable = false
    self.open = true
    self.entity.fields.open = true
end
