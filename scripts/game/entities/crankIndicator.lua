local pd <const> = playdate
local gfx <const> = playdate.graphics

class('CrankIndicator').extends(gfx.sprite)

function CrankIndicator:init()
    local crankIndicatorImageTable = gfx.imagetable.new("images/entities/crank-table-32-52")
    self.animationLoop = gfx.animation.loop.new(100, crankIndicatorImageTable, true)

    self:setZIndex(Z_INDEXES.UI)
    self:setVisible(false)
    self:add()

    self.active = false
end

function CrankIndicator:setActive(flag, player)
    self:setVisible(flag)
    self.active = flag
    self.player = player
end

function CrankIndicator:update()
    if self.active then
        self:moveTo(self.player.x, self.player.y - 32)
        self:setImage(self.animationLoop:image())
    end
end