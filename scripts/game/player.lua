
local pd <const> = playdate
local gfx <const> = playdate.graphics

local util <const> = utilities

local tags <const> = TAGS

class('Player').extends(AnimatedSprite)

function Player:init(x, y, gameManager, abilities)
    self.gameManager = gameManager

    local playerImageTable = gfx.imagetable.new("images/player/player-table-40-40")
    Player.super.init(self, playerImageTable)

    -- SFX
    local sampleplayer <const> = pd.sound.sampleplayer
    local stepSounds = {}
    stepSounds[1] = sampleplayer.new("sound/player/step1")
    stepSounds[2] = sampleplayer.new("sound/player/step2")
    stepSounds[3] = sampleplayer.new("sound/player/step3")
    self.landSound = sampleplayer.new("sound/player/land")
    self.landSoundThreshold = 8

    self.dashSound = sampleplayer.new("sound/player/swoosh")

    self.jumpSound = sampleplayer.new("sound/player/jump")

    self.wallClimbSound = sampleplayer.new("sound/player/wallClimb")

    self.climbSound = sampleplayer.new("sound/player/climb")

    self.chargeUpSound = sampleplayer.new("sound/player/chargeUp")
    self.smashSound = sampleplayer.new("sound/player/smash")

    self.deathSound = sampleplayer.new("sound/player/death")
    self.hurtSound = sampleplayer.new("sound/player/hurt")

    self:addState("idle", 1, 1)
    self:addState("run", 2, 5, {tickStep = 4})
    self.states.run.onFrameChangedEvent = function(animationSprite)
        local curFrame = animationSprite._currentFrame
        if curFrame == 2 then
            stepSounds[math.random(3)]:play()
        end
    end
    self:addState("climb", 6, 7, {tickStep = 6})
    self.states.climb.onFrameChangedEvent = function(animationSprite)
        self.climbSound:play()
    end
    self:addState("jumpAscent", 8, 8)
    self:addState("jumpDescent", 8, 8)
    self:addState("wallClimb", 9, 10, {tickStep = 6})
    self.states.wallClimb.onFrameChangedEvent = function(animationSprite)
        self.wallClimbSound:play()
    end
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
    self.jumpBuffer = table.create(jumpBufferLength, 0)
    self.climbReleased = true

    -- Dash
    self.dashAvailable = true
    self.dashSpeed = 15
    self.dashMinimumSpeed = 6
    self.dashDrag = 0.8
    self.dashHeightBoost = -3
    self.dashGravity = 0.5

    -- Abilities
    self.crankKeyAbility = false
    self.smashAbility = false
    self.wallClimbAbility = false
    self.doubleJumpAbility = false
    self.dashAbility = false

    self:setDefaultCollisionRect()
    self:setGroups(COLLISION_GROUPS.player)

    self:setZIndex(Z_INDEXES.PLAYER)
    self:setTag(TAGS.Player)

    self:playAnimation()
    self:moveTo(x, y)

    self.dead = false

    -- Interactions
    self.dialog = Dialog(self)
    if abilities then
        if abilities.crankKeyAbility then
            self.dialog:unlockAbility("CrankKey", true)
        end
        if abilities.smashAbility then
            self.dialog:unlockAbility("Smash", true)
        end
        if abilities.wallClimbAbility then
            self.dialog:unlockAbility("WallClimb", true)
        end
        if abilities.doubleJumpAbility then
            self.dialog:unlockAbility("DoubleJump", true)
        end
        if abilities.dashAbility then
            self.dialog:unlockAbility("Dash", true)
        end
    end

    local aButtonImage = gfx.image.new("images/entities/aButton")
    self.indicatorSprite = gfx.sprite.new(aButtonImage)
    self.indicatorSprite:setZIndex(Z_INDEXES.UI)

    -- NPC Dialogue
    self.talkingToNpc = false
end

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == tags.Climable or tag == tags.Hazard or tag == tags.Interactable or tag == tags.Pickup then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
    if self.dead or self.dialog.active or self.talkingToNpc then
        self.indicatorSprite:remove()
        return
    end

    if self.interactingObject and self.interactingObject.interactable then
        self.indicatorSprite:moveTo(self.x, self.y - 32)
        self.indicatorSprite:add()
    else
        self.indicatorSprite:remove()
    end

    if not self.climbReleased then
        if pd.buttonJustReleased(pd.kButtonUp) then
            self.climbReleased = true
        end
    end

    self:updateAnimation()

    if self.currentState == "idle" then
        if pd.buttonIsPressed(pd.kButtonA) then
            if self.interactingObject and self.interactingObject.interactable then
                self.interactingObject:interact(self)
            else
                self:changeToJumpState()
            end
        elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
            self:changeToDashState()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self:changeToRunState("left")
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self:changeToRunState("right")
        end
        if pd.buttonJustPressed(pd.kButtonDown) and self.touchingGround and self.smashAbility then
            self:changeState("smash")
            self.chargeUpSound:play()
        end
        self:checkIfClimbing()
        self:applyFriction()
        self:applyGravity()
    elseif self.currentState == "run" then
        if pd.buttonIsPressed(pd.kButtonA)then
            if self.interactingObject and self.interactingObject.interactable then
                self.interactingObject:interact(self)
            else
                self:changeToJumpState()
            end
        elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAbility then
            self:changeToDashState()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self:accelerateLeft()
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self:accelerateRight()
        else
            self:changeState("idle")
        end
        if pd.buttonJustPressed(pd.kButtonDown) and self.touchingGround and self.smashAbility then
            self:changeState("smash")
            self.chargeUpSound:play()
        end
        self:checkIfClimbing()
        self:applyGravity()
    elseif self.currentState == "jumpAscent" then
        if pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
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
        if pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
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
        -- self:setClimbCollisionRect()
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
            -- self:setDefaultCollisionRect()
        elseif self.touchingGround or not self.touchingClimableWall then
            self.yVelocity = 0
            self.xVelocity = 0
            self:changeState("idle")
            self:resumeAnimation()
            -- self:setDefaultCollisionRect()
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
        if self.touchingClimableWall and self.wallClimbAbility then
            if self.globalFlip == 1 then
                self.xVelocity = -1
            else
                self.xVelocity = 1
            end
            self.doubleJumpAvailable = false
            self.dashAvailable = false
            self:changeState("wallClimb")
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
    self.touchingCeiling = false
    self.touchingWall = false
    self.touchingClimableWall = false
    self.touchingClimableTile = false
    self.standingOnClimableTile = false
    self.interactingObject = nil

    local touchedGround = false
    local died = false
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
                    touchedGround = true
                    self:moveTo(self.x, originalY)
                end
            elseif collisionTag == TAGS.Interactable then
                self.interactingObject = collision.other
            elseif collisionTag == TAGS.Pickup then
                collision.other:pickUp()
            end
        else
            if collision.normal.y == -1 then
                touchedGround = true
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

        if collision.other:getTag() == TAGS.Hazard then
            died = true
        end
    end

    if not self.touchingGround and touchedGround and self.yVelocity > self.landSoundThreshold then
        self.landSound:play()
    end
    self.touchingGround = touchedGround
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

    if died then
        self:die()
    end
end

function Player:die()
    self.xVelocity = 0
    self.yVelocity = 0
    self.dead = true
    self:setCollisionsEnabled(false)
    self.hurtSound:play()
    pd.timer.performAfterDelay(200, function()
        local deathBurstSprite = util.animatedSprite("images/player/deathBurst-table-105-97", 50, false)
        deathBurstSprite:setZIndex(Z_INDEXES.ABILITY)
        deathBurstSprite:moveTo(self.x, self.y)
        self:setVisible(false)
        self.deathSound:play()
        pd.timer.performAfterDelay(400, function()
            self:setVisible(true)
            self:setCollisionsEnabled(true)
            self.gameManager:resetPlayer()
            self.dead = false
        end)
    end)
end

function Player:checkIfClimbing()
    if self.touchingClimableTile and self.climbReleased then
        local inMagnetRange = math.abs(self.x - self.climbTileX) <= self.climbMagnetRange
        if self.standingOnClimableTile then
            if pd.buttonIsPressed(pd.kButtonDown) and inMagnetRange then
                self:changeToClimbState()
            end
        elseif pd.buttonIsPressed(pd.kButtonUp) and inMagnetRange then
            self.climbReleased = false
            self:changeToClimbState()
        end
    end
end

function Player:changeToClimbState()
    self.xVelocity = 0
    self.yVelocity = 0
    self:changeState("climb")
    self:pauseAnimation()
    self:moveTo(self.climbTileX, self.y + 1)
end

function Player:changeToJumpState()
    self.jumpSound:play()
    self.yVelocity = self.jumpVelocity
    self:changeState("jumpAscent")
end

function Player:changeToDashState()
    self.dashSound:play()
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
    if self.touchingClimableWall and self.wallClimbAbility then
        if self.globalFlip == 1 then
            self.xVelocity = -1
        else
            self.xVelocity = 1
        end
        self.doubleJumpAvailable = false
        self.dashAvailable = false
        self:changeState("wallClimb")
    elseif pd.buttonJustPressed(pd.kButtonA) and self.doubleJumpAvailable and self.doubleJumpAbility then
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
        self.smashSound:play()
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
