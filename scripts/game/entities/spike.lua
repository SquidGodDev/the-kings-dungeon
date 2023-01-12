local pd <const> = playdate
local gfx <const> = playdate.graphics

local spikeImage <const> = gfx.image.new("images/entities/spike")

class('Spike').extends(gfx.sprite)

function Spike:init(x, y)
    self:setZIndex(Z_INDEXES.HAZARDS)
    self:setImage(spikeImage)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.Hazard)
    self:setCollideRect(4, 16, 24, 12)
end