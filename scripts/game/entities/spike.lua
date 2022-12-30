local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Spike').extends(gfx.sprite)

function Spike:init(x, y)
    local spikeImage = gfx.image.new("images/entities/spike")
    self:setImage(spikeImage)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.Hazard)
    self:setCollideRect(0, 12, 32, 20)
end