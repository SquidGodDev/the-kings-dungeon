local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Spikeball').extends(gfx.sprite)

function Spikeball:init(x, y, entity)
    local spikeballImage = gfx.image.new("images/entities/spikeball")
    self:setZIndex(Z_INDEXES.HAZARDS)
    self:setImage(spikeballImage)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.Hazard)
    local spikeballWidth, spikeballHeight = self:getSize()
    local buffer = 4
    self:setCollideRect(buffer, buffer, spikeballWidth - buffer * 2, spikeballHeight - buffer * 2)
    self.collisionResponse = gfx.sprite.kCollisionTypeBounce

    local fields = entity.fields
    self.moving = fields.moving
    self.velocity = fields.velocity
    self.movingRight = fields.movingRight
    self.bounceSound = pd.sound.sampleplayer.new("sound/entities/spikeBounce")
end

function Spikeball:update()
    if self.moving then
        local moveX, moveY = 0, 0
        if self.movingRight then
            moveX += self.velocity
        else
            moveY += self.velocity
        end
        local _, _, collisions, length = self:moveWithCollisions(self.x + moveX, self.y + moveY)
        local hitWall = false
        for i=1,length do
            local collision = collisions[i]
            if collision.other:getTag() ~= TAGS.Player then
                hitWall = true
            end
        end
        if hitWall then
            self.bounceSound:play()
            self.velocity *= -1
        end
    end
end