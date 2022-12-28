
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

    self.touchedGround = true
    self.touchedCeiling = false
    self.touchedWall = false

    -- Climb
    self.climbVelocity = 3
    self.climbMagnetRange = 8
    self.touchingClimableTile = false
    self.standingOnClimableTile = false
    self.climbTileX = self.x

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
            self:changeToJumpState()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self:changeToRunState("left")
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self:changeToRunState("right")
        end
        self:checkIfClimbing()
        self:applyFriction()
        self:applyGravity()
    elseif self.currentState == "run" then
        if pd.buttonIsPressed(pd.kButtonA) then
            self:changeToJumpState()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self:accelerateLeft()
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self:accelerateRight()
        else
            self:changeState("idle")
        end
        self:checkIfClimbing()
        self:applyGravity()
    elseif self.currentState == "jumpAscent" then
        self:handleJumpPhysics()
        if self.yVelocity >= 0 then
            self:changeState("jumpDescent")
        end
        self:checkIfClimbing()
        self:applyGravity()
    elseif self.currentState == "jumpDescent" then
        self:handleJumpPhysics()
        if math.abs(self.yVelocity) <= 0 then
            if pd.buttonIsPressed(pd.kButtonLeft) then
                self:changeToRunState("left")
            elseif pd.buttonIsPressed(pd.kButtonRight) then
                self:changeToRunState("right")
            else
                self:changeState("idle")
            end
        end
        self:checkIfClimbing()
        self:applyGravity()
    elseif self.currentState == "climb" then
        if pd.buttonIsPressed(pd.kButtonA) or not self.touchingClimableTile then
            self.yVelocity = 0
            self:changeState("idle")
            self._enabled = true
        elseif pd.buttonIsPressed(pd.kButtonUp) then
            self.yVelocity = -self.climbVelocity
            self._enabled = true
        elseif pd.buttonIsPressed(pd.kButtonDown) then
            self.yVelocity = self.climbVelocity
            self._enabled = true
        elseif self.touchedGround  then
            self.yVelocity = 0
            self:changeState("idle")
            self._enabled = true
        else
            self.yVelocity = 0
            self:pauseAnimation()
        end
    end

    self:handleMovementAndCollisions()

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

function Player:handleMovementAndCollisions()
    local originalY = self.y
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)
    self.touchedGround = false
    self.touchedCeiling = false
    self.touchedWall = false
    self.touchingClimableTile = false
    self.standingOnClimableTile = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        if collisionType == gfx.sprite.kCollisionTypeOverlap then
            local collisionTag = collision.other:getTag()
            if collisionTag == TAGS.CLIMABLE then
                self.touchingClimableTile = true
                self.climbTileX = collision.other.x
                if collision.normal.y == -1 and not collision.overlaps then
                    self.standingOnClimableTile = true
                    self.touchedGround = true
                    self:moveTo(self.x, originalY)
                end
            end
        else
            if collision.normal.y == -1 then
                self.touchedGround = true
            elseif collision.normal.y == 1 then
                self.touchedCeiling = true
            end
            if collision.normal.x == -1 or collision.normal.x == 1 then
                self.touchedWall = true
            end
        end
    end

    if self.touchedGround or self.touchedCeiling then
        self.yVelocity = 0
    end

    if self.touchedWall then
        self.xVelocity = 0
    end
end

function Player:resetPlayer()
    self:moveTo(self.respawnX, self.respawnY)
    self.xVelocity = 0
    self.yVelocity = 0
end

function Player:checkIfClimbing()
    if self.touchingClimableTile then
        if self.standingOnClimableTile then
            if pd.buttonIsPressed(pd.kButtonDown) then
                self:changeToClimbState()
            end
        elseif pd.buttonIsPressed(pd.kButtonUp) then
            self:changeToClimbState()
        end
    end
end

function Player:changeToClimbState()
    if math.abs(self.x - self.climbTileX) > self.climbMagnetRange then
        return
    end
    self.xVelocity = 0
    self.yVelocity = 0
    self:changeState("climb")
    self:pauseAnimation()
    self:moveTo(self.climbTileX, self.y + 1)
end

function Player:changeToJumpState()
    self.yVelocity = self.jumpVelocity
    self:changeState("jumpAscent")
end

function Player:changeToRunState(direction)
    if direction == "left" then
        self.xVelocity = -self.startVelocity
            self.globalFlip = 1
    elseif direction == "right" then
        self.xVelocity = self.startVelocity
        self.globalFlip = 0
    end
    self:changeState("run")
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
    if self.standingOnClimableTile then
        self.yVelocity = 0
    elseif self.yVelocity < 0 then
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