local pd <const> = playdate
local gfx <const> = playdate.graphics

local headTable <const> = gfx.imagetable.new("images/entities/waterfall/waterfallHead-table-32-32")
local bodyTable <const> = gfx.imagetable.new("images/entities/waterfall/waterfallBody-table-32-32")
local tailTable <const> = gfx.imagetable.new("images/entities/waterfall/waterfallTail-table-32-32")

class('Waterfall').extends(gfx.sprite)

function Waterfall:init(x, y, entity)
    local height = entity.size.height
    self.waterfallFrame1 = self:drawWaterfall(32, height, 1)
    self.waterfallFrame2 = self:drawWaterfall(32, height, 2)

    self:setImage(self.waterfallFrame1)
    self:setZIndex(Z_INDEXES.WATERFALL)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    local frame1 = true
    local drawTimer = pd.timer.new(200, function()
        if frame1 then
            self:setImage(self.waterfallFrame1)
        else
            self:setImage(self.waterfallFrame2)
        end
        frame1 = not frame1
    end)
    drawTimer.repeats = true
end

function Waterfall:drawWaterfall(width, height, frame)
    local waterfallLength = height / 32
    local waterfallImage = gfx.image.new(width, height)
    gfx.pushContext(waterfallImage)
        headTable[frame]:draw(0, 0)
        for i=1,waterfallLength-2 do
            bodyTable[frame]:draw(0, i*32)
        end
        tailTable[frame]:draw(0, height - 32)
    gfx.popContext()
    return waterfallImage
end