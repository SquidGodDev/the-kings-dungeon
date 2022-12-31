local pd <const> = playdate
local gfx <const> = playdate.graphics

local fadedRects <const> = {}
for i=0,1,0.01 do
    local fadedImage = gfx.image.new(400, 240)
    gfx.pushContext(fadedImage)
        local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
        filledRect:drawFaded(0, 0, i, gfx.image.kDitherTypeBayer8x8)
    gfx.popContext()
    fadedRects[math.floor(i * 100)] = fadedImage
end
fadedRects[100] = gfx.image.new(400, 240, gfx.kColorBlack)

class('Dialog').extends(gfx.sprite)

function Dialog:init(player)
    self.player = player
    self.active = false
    self.dialogDisplayed = false
    self:setZIndex(Z_INDEXES.DIALOG)

    self.fadedBackgroundSprite = gfx.sprite.new()
    self.fadedBackgroundSprite:moveTo(200, 120)
    self.fadedBackgroundSprite:setZIndex(Z_INDEXES.DIALOG-1)
end

function Dialog:update()
    if self.dialogDisplayed then
        if pd.buttonJustPressed(pd.kButtonA) then
            self.dialogDisplayed = false
            self.fadedBackgroundSprite:setVisible(true)
            local moveTimer = pd.timer.new(1000, self.y, -120, pd.easingFunctions.inOutCubic)
            moveTimer.updateCallback = function(timer)
                self:moveTo(self.x, timer.value)
            end
            local fadeTimer = pd.timer.new(700, 70, 0, pd.easingFunctions.inOutCubic)
            fadeTimer.updateCallback = function(timer)
                local fadedImage = fadedRects[math.floor(timer.value)]
                self.fadedBackgroundSprite:setImage(fadedImage)
            end
            fadeTimer.timerEndedCallback = function()
                self.fadedBackgroundSprite:remove()
                self:remove()
                self.active = false
            end
        end
    end
end

function Dialog:unlockAbility(ability)
    local abilityIcon, abilityName, abilityDescription
    if ability == "crankKey" then
        self.player.crankKeyAbility = true
        abilityName = "Crank Key"
        abilityDescription = "Crank to open gates"
        abilityIcon = gfx.image.new("images/player/abilities/crankKey")
    elseif ability == "smash" then
        self.player.smashAbility = true
        abilityName = "Smash"
        abilityDescription = "Press Down to smash damaged blocks"
        abilityIcon = gfx.image.new("images/player/abilities/smash")
    elseif ability == "wallClimb" then
        self.player.wallClimbAbility = true
        abilityName = "Wall Climb"
        abilityDescription = "Jump at climable walls to climb them"
        abilityIcon = gfx.image.new("images/player/abilities/wallClimb")
    elseif ability == "doubleJump" then
        self.player.doubleJumpAbility = true
        abilityName = "Double Jump"
        abilityDescription = "Press A again in the air to jump again"
        abilityIcon = gfx.image.new("images/player/abilities/doubleJump")
    elseif ability == "dash" then
        self.player.dashAbility = true
        abilityName = "Dash"
        abilityDescription = "Press B to dash forward"
        abilityIcon = gfx.image.new("images/player/abilities/dash")
    else
        return
    end
    self:createDialog(abilityIcon, abilityName, abilityDescription)
end

function Dialog:createDialog(abilityIcon, abilityName, abilityDescription)
    self.active = true
    local dialogBackground = gfx.image.new("images/ui/dialog")
    local dialogWidth = dialogBackground:getSize()
    gfx.pushContext(dialogBackground)
        abilityIcon:draw(86, 49)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        local largeFont= gfx.font.new("images/fonts/m5x7-24")
        largeFont:drawTextAligned(abilityName, dialogWidth/2, 20, kTextAlignment.center)
        gfx.drawTextInRect(abilityDescription, 18, 96, 170, 65, nil, nil, kTextAlignment.center, largeFont)
    gfx.popContext()
    self:setImage(dialogBackground)
    self:moveTo(200, -120)
    self:add()

    self.fadedBackgroundSprite:setVisible(true)
    self.fadedBackgroundSprite:add()
    local fadeTimer = pd.timer.new(500, 0, 70, pd.easingFunctions.inOutCubic)
    fadeTimer.updateCallback = function(timer)
        local fadedImage = fadedRects[math.floor(timer.value)]
        self.fadedBackgroundSprite:setImage(fadedImage)
    end
    fadeTimer.timerEndedCallback = function()
        local moveTimer = pd.timer.new(1000, self.y, 120, pd.easingFunctions.inOutCubic)
        moveTimer.updateCallback = function(timer)
            self:moveTo(self.x, timer.value)
        end
        moveTimer.timerEndedCallback = function()
            self.dialogDisplayed = true
        end
    end
end