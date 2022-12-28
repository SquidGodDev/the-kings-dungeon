
local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Player').extends(AnimatedSprite)

function Player:init(x, y, gameManager)
    self.respawnX = x
    self.respawnY = y
    self.gameManager = gameManager

    local playerImageTable = gfx.imagetable.new("images/player/player-table-36-36")
    Player.super.init(self, playerImageTable)

    self:addState("idle", 1, 1)
    self:addState("run", 2, 5, {tickStep = 4})
    self:addState("climb", 6, 7, {tickStep = 6})
    self:addState("jumpAscent", 8, 8)
    self:addState("jumpDescent", 8, 8)

    self.xVelocity = 0
    self.yVelocity = 0
    self.gravity = 0.8
    self.fallingGravity = 1.0
    self.maxSpeed = 3
    self.startVelocity = 3
    self.jumpVelocity = -8

    self.friction = 0.5
    self.drag = 0.1
    self.acceleration = 0.5

    -- Climb
    self.climbVelocity = 3
    self.climbMagnetRange = 8


    self:setCollideRect(8, 4, 18, 32)
    self:setGroups(COLLISION_GROUPS.player)

    self:setZIndex(Z_INDEXES.PLAYER)

    self:playAnimation()
    self:moveTo(x, y)
end

function Player:collisionResponse(other)
    local climableTag = TAGS.CLIMABLE
    local collisionTag = other:getTag()
    if collisionTag == climableTag then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
    self:updateAnimation()

    if self.currentState == "idle" then
        if pd.buttonIsPressed(pd.kButtonA)then
            self.yVelocity = self.jumpVelocity
            self:changeState("jumpAscent")
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self.xVelocity = -self.startVelocity
            self.globalFlip = 1
            self:changeState("run")
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self.xVelocity = self.startVelocity
            self.globalFlip = 0
            self:changeState("run")
        end
        self:applyFriction()
    elseif self.currentState == "run" then
        if pd.buttonIsPressed(pd.kButtonA) then
            self.yVelocity = self.jumpVelocity
            self:changeState("jumpAscent")
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self:accelerateLeft()
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self:accelerateRight()
        else
            self:changeState("idle")
        end
    elseif self.currentState == "jumpAscent" then
        self:handleJumpPhysics()
        if self.yVelocity >= 0 then
            self:changeState("jumpDescent")
        end
    elseif self.currentState == "jumpDescent" then
        self:handleJumpPhysics()
        if math.abs(self.yVelocity) < 0.5 then
            if pd.buttonIsPressed(pd.kButtonLeft) then
                self.xVelocity = -self.startVelocity
                self.globalFlip = 1
                self:changeState("run")
            elseif pd.buttonIsPressed(pd.kButtonRight) then
                self.xVelocity = self.startVelocity
                self.globalFlip = 0
                self:changeState("run")
            else
                self:changeState("idle")
            end
        end
    elseif self.currentState == "climb" then
        if pd.buttonIsPressed(pd.kButtonLeft) or pd.buttonIsPressed(pd.kButtonRight) then
            self.yVelocity = 0
            self:changeState("idle")
            self._enabled = true
        elseif pd.buttonIsPressed(pd.kButtonUp) then
            self.yVelocity = -self.climbVelocity
            self._enabled = true
        elseif pd.buttonIsPressed(pd.kButtonDown) then
            self.yVelocity = self.climbVelocity
            self._enabled = true
        else
            self.yVelocity = 0
            self:pauseAnimation()
        end
    end

    local originalY = self.y
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)
    local touchedGround = false
    local touchedClimableTile = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        if collisionType == gfx.sprite.kCollisionTypeOverlap then
            local collisionTag = collision.other:getTag()
            if collisionTag == TAGS.CLIMABLE then
                touchedClimableTile = true
                if self.currentState ~= "climb" then
                    if collision.normal.y == -1 and not collision.overlaps then
                        if pd.buttonIsPressed(pd.kButtonDown) then
                            self:changeToClimbState(collision)
                        else
                            self.yVelocity = 0
                            touchedGround = true
                            self:moveTo(self.x, originalY)
                        end
                    elseif pd.buttonIsPressed(pd.kButtonUp) then
                        self:changeToClimbState(collision)
                    end
                end
            end
        else
            if collision.normal.y == -1 then
                touchedGround = true
            elseif collision.normal.y == 1 then
                self.yVelocity = 0
            end
            if collision.normal.x == -1 or collision.normal.x == 1 then
                self.xVelocity = 0
            end
        end
    end
    if touchedGround then
        self.yVelocity = 0
    else
        self:applyGravity()
    end
    if not touchedClimableTile and self.currentState == "climb" then
        self:changeState("idle")
        self.yVelocity = 0
    end

    if self.xVelocity < 0 then
        self.globalFlip = 1
    elseif self.xVelocity > 0 then
        self.globalFlip = 0
    end

	if self.x < 0 then
		self.gameManager:enterRoom(DIRECTIONS.west)
    elseif self.x > 400  then
        self.gameManager:enterRoom(DIRECTIONS.east)
    elseif self.y < 0 then
        self.gameManager:enterRoom(DIRECTIONS.north)
    elseif self.y > 240 then
        self.gameManager:enterRoom(DIRECTIONS.south)
	end
end

function Player:resetPlayer()
    self:moveTo(self.respawnX, self.respawnY)
    self.xVelocity = 0
    self.yVelocity = 0
end

function Player:changeToClimbState(collision)
    local climableTileX = collision.other.x
    if math.abs(self.x - climableTileX) > self.climbMagnetRange then
        return
    end
    self.xVelocity = 0
    self.yVelocity = 0
    self:changeState("climb")
    self:pauseAnimation()
    self:moveTo(climableTileX, self.y)
end

function Player:handleJumpPhysics()
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self:accelerateLeft()
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:accelerateRight()
    else
        self:applyDrag()
    end
end

function Player:accelerateLeft()
    if self.xVelocity > 0 then
        self.xVelocity = 0
    end
    self.xVelocity -= self.acceleration
    if self.xVelocity <= -self.maxSpeed then
        self.xVelocity = -self.maxSpeed
    end
end

function Player:accelerateRight()
    if self.xVelocity < 0 then
        self.xVelocity = 0
    end
    self.xVelocity += self.acceleration
    if self.xVelocity >= self.maxSpeed then
        self.xVelocity = self.maxSpeed
    end
end

function Player:applyGravity()
    if self.yVelocity < 0 then
        self.yVelocity += self.gravity
    else
        self.yVelocity += self.fallingGravity
    end
end

function Player:applyDrag()
    if self.xVelocity > 0 then
        self.xVelocity -= self.drag
    elseif self.xVelocity < 0 then
        self.xVelocity += self.drag
    end

    if math.abs(self.xVelocity) < 0.5 then
        self.xVelocity = 0
    end
end

function Player:applyFriction()
    if self.xVelocity > 0 then
        self.xVelocity -= self.friction
    elseif self.xVelocity < 0 then
        self.xVelocity += self.friction
    end

    if math.abs(self.xVelocity) < 0.5 then
        self.xVelocity = 0
    end
end