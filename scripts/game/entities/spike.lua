local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Spike').extends(gfx.sprite)

function Spike:init(x, y)
    local spikeImage = gfx.image.new("images/entities/spike")
    self:setZIndex(Z_INDEXES.HAZARDS)
    self:setImage(spikeImage)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.Hazard)
    self:setCollideRect(4, 16, 24, 12)
end