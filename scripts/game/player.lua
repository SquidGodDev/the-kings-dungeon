
local pd <const> = playdate
local gfx <const> = playdate.graphics

local util <const> = utilities

class('Player').extends(AnimatedSprite)

function Player:init(x, y, gameManager)
    self.respawnX = x
    self.respawnY = y
    self.gameManager = gameManager

    local playerImageTable = gfx.imagetable.new("images/player/player-table-40-40")
    Player.super.init(self, playerImageTable)

    self:addState("idle", 1, 1)
    self:addState("run", 2, 5, {tickStep = 4})
    self:addState("climb", 6, 7, {tickStep = 6})
    self:addState("jumpAscent", 8, 8)
    self:addState("jumpDescent", 8, 8)
    self:addState("wallClimb", 9, 10, {tickStep = 6})
    self:addState("dash", 5, 5)
    self:addState("smash", 11, 17, {tickStep = 6, nextAnimation = "idle"})
    self.states.smash.onFrameChangedEvent = function(animationSprite)
        if animationSprite._currentFrame == 16 then
            self:performSmash()
        end
    end

    self.xVelocity = 0
    self.yVelocity = 0
    self.gravity = 0.8
    self.fallingGravity = 1.0
    self.maxSpeed = 3
    self.startVelocity = 3
    self.jumpVelocity = -8
    self.doubleJumpAvailable = true

    self.friction = 0.5
    self.drag = 0.1
    self.acceleration = 0.5

    self.touchingGround = true
    self.touchingCeiling = false
    self.touchingWall = false

    -- Climb
    self.climbVelocity = 3
    self.climbMagnetRange = 16
    self.touchingClimableTile = false
    self.standingOnClimableTile = false
    self.climbTileX = self.x

    -- Wall Climb
    self.touchingClimableWall = false
    self.wallClimbVelocity = 3
    self.wallJumpVelocity = 3

    -- Dash
    self.dashAvailable = true
    self.dashSpeed = 15
    self.dashMinimumSpeed = 6
    self.dashDrag = 0.8
    self.dashHeightBoost = -3
    self.dashGravity = 0.5

    self:setDefaultCollisionRect()
    self:setGroups(COLLISION_GROUPS.player)

    self:setZIndex(Z_INDEXES.PLAYER)
    self:setTag(TAGS.Player)

    self:playAnimation()
    self:moveTo(x, y)
end

function Player:collisionResponse(other)
    local climableTag = TAGS.Climable
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
        elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable then
            self:changeToDashState()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self:changeToRunState("left")
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self:changeToRunState("right")
        end
        if pd.buttonJustPressed(pd.kButtonDown) and self.touchingGround then
            self:changeState("smash")
        end
        self:checkIfClimbing()
        self:applyFriction()
        self:applyGravity()
    elseif self.currentState == "run" then
        if pd.buttonIsPressed(pd.kButtonA) then
            self:changeToJumpState()
        elseif pd.buttonJustPressed(pd.kButtonB) then
            self:changeToDashState()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self:accelerateLeft()
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self:accelerateRight()
        else
            self:changeState("idle")
        end
        if pd.buttonJustPressed(pd.kButtonDown) and self.touchingGround then
            self:changeState("smash")
        end
        self:checkIfClimbing()
        self:applyGravity()
    elseif self.currentState == "jumpAscent" then
        if pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable then
            self:changeToDashState()
        else
            self:handleJumpPhysics()
            if self.yVelocity >= 0 then
                self:changeState("jumpDescent")
            end
            self:checkIfClimbing()
            self:applyGravity()
        end
    elseif self.currentState == "jumpDescent" then
        if pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable then
            self:changeToDashState()
        else
            self:handleJumpPhysics()
            if self.yVelocity == 0 then
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
        end
    elseif self.currentState == "climb" then
        if pd.buttonIsPressed(pd.kButtonA) or not self.touchingClimableTile then
            self.yVelocity = 0
            self:changeState("idle")
            self:resumeAnimation()
        elseif pd.buttonIsPressed(pd.kButtonUp) then
            self.yVelocity = -self.climbVelocity
            self:resumeAnimation()
        elseif pd.buttonIsPressed(pd.kButtonDown) then
            self.yVelocity = self.climbVelocity
            self:resumeAnimation()
        elseif self.touchingGround then
            self.yVelocity = 0
            self:changeState("idle")
            self:resumeAnimation()
        else
            self.yVelocity = 0
            self:pauseAnimation()
        end
    elseif self.currentState == "wallClimb" then
        self:setClimbCollisionRect()
        if self.globalFlip == 1 then
            self.xVelocity = -1
        else
            self.xVelocity = 1
        end
        if pd.buttonJustPressed(pd.kButtonA) then
            self.yVelocity = 0
            if self.globalFlip == 1 then
                self.xVelocity = self.wallJumpVelocity
            else
                self.xVelocity = -self.wallJumpVelocity
            end
            self:changeToJumpState()
            self:resumeAnimation()
            self:setDefaultCollisionRect()
        elseif self.touchingGround or not self.touchingClimableWall then
            self.yVelocity = 0
            self:changeState("idle")
            self:resumeAnimation()
            self:setDefaultCollisionRect()
        elseif pd.buttonIsPressed(pd.kButtonUp) then
            self.yVelocity = -self.wallClimbVelocity
            self:resumeAnimation()
        elseif pd.buttonIsPressed(pd.kButtonDown) then
            self.yVelocity = self.wallClimbVelocity
            self:resumeAnimation()
        else
            self.yVelocity = 0
            self:pauseAnimation()
        end
    elseif self.currentState == "dash" then
        if self.xVelocity > 0 then
            self.xVelocity -= self.dashDrag
        elseif self.xVelocity < 0 then
            self.xVelocity += self.dashDrag
        end

        if self.standingOnClimableTile then
            self.yVelocity = 0
        else
            self.yVelocity += self.dashGravity
        end

        if math.abs(self.xVelocity) <= self.dashMinimumSpeed then
            self:changeState("jumpDescent")
        end
    elseif self.currentState == "smash" then
        self.xVelocity = 0
        self.yVelocity = 0
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
    self.touchingGround = false
    self.touchingCeiling = false
    self.touchingWall = false
    self.touchingClimableWall = false
    self.touchingClimableTile = false
    self.standingOnClimableTile = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        if collisionType == gfx.sprite.kCollisionTypeOverlap then
            local collisionTag = collision.other:getTag()
            if collisionTag == TAGS.Climable then
                self.touchingClimableTile = true
                self.climbTileX = collision.other.x
                if collision.normal.y == -1 and not collision.overlaps then
                    self.standingOnClimableTile = true
                    self.touchingGround = true
                    self:moveTo(self.x, originalY)
                end
            end
        else
            if collision.normal.y == -1 then
                self.touchingGround = true
            elseif collision.normal.y == 1 then
                self.touchingCeiling = true
            end
            if collision.normal.x == -1 or collision.normal.x == 1 then
                local collisionTag = collision.other:getTag()
                if collisionTag == TAGS.WallClimable then
                    self.touchingClimableWall = true
                end
                self.touchingWall = true
            end
        end
    end

    if self.touchingGround then
        self.yVelocity = 0
        self.doubleJumpAvailable = true
        self.dashAvailable = true
    end

    if self.touchingCeiling then
        self.yVelocity = 0
    end

    if self.touchingWall then
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
        elseif pd.buttonJustPressed(pd.kButtonUp) then
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

function Player:changeToDashState()
    self.dashAvailable = false
    self.yVelocity = self.dashHeightBoost
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.dashSpeed
        self.globalFlip = 1
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.dashSpeed
        self.globalFlip = 0
    else
        if self.globalFlip == 1 then
            self.xVelocity = -self.dashSpeed
        else
            self.xVelocity = self.dashSpeed
        end
    end
    self:changeState("dash")
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
    if pd.buttonIsPressed(pd.kButtonA) and self.touchingClimableWall then
        if self.globalFlip == 1 then
            self.xVelocity = -1
        else
            self.xVelocity = 1
        end
        self.doubleJumpAvailable = false
        self.dashAvailable = false
        self:changeState("wallClimb")
    elseif pd.buttonJustPressed(pd.kButtonA) and self.doubleJumpAvailable then
        self.doubleJumpAvailable = false
        self:changeToJumpState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
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

function Player:setDefaultCollisionRect()
    self:setCollideRect(8, 10, 24, 30)
end

function Player:setClimbCollisionRect()
    self:setCollideRect(8, 8, 24, 24)
end

function Player:performSmash()
    pd.timer.performAfterDelay(50, function()
        local smokeBurstSprite = util.animatedSprite("images/player/smokeBurst-table-113-97", 15, false)
        smokeBurstSprite:setZIndex(Z_INDEXES.ABILITY)
        smokeBurstSprite:moveTo(self.x, self.y)
    end)
    pd.timer.performAfterDelay(100, function()
        local smashWidth, smashHeight = 96, 96
        local queriedSprites = gfx.sprite.querySpritesInRect(self.x - smashWidth/2, self.y - smashHeight/2, smashWidth, smashHeight)
        for i=1, #queriedSprites do
            local queriedSprite = queriedSprites[i]
            if queriedSprite:getTag() == TAGS.Destructable then
                queriedSprite:destroy()
            end
        end
    end)
end
