local pd <const> = playdate
local gfx <const> = playdate.graphics

-- == Generate dithered image beforehand into files ==
-- == Using 100 drawFaded calls was killing the startup performance ==
-- local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
-- for i=1,100 do
--     local fadedImage = gfx.image.new(400, 240)
--     gfx.pushContext(fadedImage)
--         filledRect:drawFaded(0, 0, (i-1)/100, gfx.image.kDitherTypeBayer8x8)
--     gfx.popContext()
--     local fadeIndex = i
--     playdate.simulator.writeToFile(fadedImage, "faded/faded-table-"..fadeIndex..".png")
-- end
local fadedImageTable <const> = gfx.imagetable.new("images/ui/faded/faded")

local whooshSound <const> = pd.sound.sampleplayer.new("sound/entities/whoosh")
local abilityUnlockSound <const> = pd.sound.sampleplayer.new("sound/entities/abilityUnlock")

class('Dialog').extends(gfx.sprite)

function Dialog:init(player)
    self.player = player
    self.active = false
    self.dialogDisplayed = false
    self:setZIndex(Z_INDEXES.DIALOG)

    self.fadedBackgroundSprite = gfx.sprite.new()
    self.fadedBackgroundSprite:moveTo(200, 120)
    self.fadedBackgroundSprite:setZIndex(Z_INDEXES.DIALOG-1)

    self.menuImage = gfx.image.new("images/ui/pauseMenu")
    pd.setMenuImage(self.menuImage)
end

function Dialog:update()
    if self.dialogDisplayed then
        if pd.buttonJustPressed(pd.kButtonA) then
            whooshSound:play()
            self.dialogDisplayed = false
            self.fadedBackgroundSprite:setVisible(true)
            local moveTimer = pd.timer.new(1000, self.y, -120, pd.easingFunctions.inOutCubic)
            moveTimer.updateCallback = function(timer)
                self:moveTo(self.x, timer.value)
            end
            local fadeTimer = pd.timer.new(700, 70, 1, pd.easingFunctions.inOutCubic)
            fadeTimer.updateCallback = function(timer)
                local fadedImage = fadedImageTable:getImage(math.floor(timer.value))
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
    if ability == "CrankKey" then
        self.player.crankKeyAbility = true
        abilityName = "Crank Key"
        abilityDescription = "Crank to open gates"
        abilityIcon = gfx.image.new("images/player/abilities/crankKey")
        self:updatePauseMenu(120, 12, abilityIcon)
    elseif ability == "Smash" then
        self.player.smashAbility = true
        abilityName = "Smash"
        abilityDescription = "Press Down to smash damaged blocks"
        abilityIcon = gfx.image.new("images/player/abilities/smash")
        self:updatePauseMenu(16, 52, abilityIcon)
    elseif ability == "WallClimb" then
        self.player.wallClimbAbility = true
        abilityName = "Wall Climb"
        abilityDescription = "Jump at climable walls to climb them"
        abilityIcon = gfx.image.new("images/player/abilities/wallClimb")
        self:updatePauseMenu(148, 104, abilityIcon)
    elseif ability == "DoubleJump" then
        self.player.doubleJumpAbility = true
        abilityName = "Double Jump"
        abilityDescription = "Press A again in the air to jump again"
        abilityIcon = gfx.image.new("images/player/abilities/doubleJump")
        self:updatePauseMenu(144, 192, abilityIcon)
    elseif ability == "Dash" then
        self.player.dashAbility = true
        abilityName = "Dash"
        abilityDescription = "Press B to dash forward"
        abilityIcon = gfx.image.new("images/player/abilities/dash")
        self:updatePauseMenu(32, 172, abilityIcon)
    else
        return
    end
    abilityUnlockSound:play()
    self:createDialog(abilityIcon, abilityName, abilityDescription)
end

function Dialog:updatePauseMenu(x, y, image)
    gfx.pushContext(self.menuImage)
        image:draw(x, y)
    gfx.popContext()
    pd.setMenuImage(self.menuImage)
end

function Dialog:createDialog(abilityIcon, abilityName, abilityDescription)
    whooshSound:play()
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
    local fadeTimer = pd.timer.new(500, 1, 70, pd.easingFunctions.inOutCubic)
    fadeTimer.updateCallback = function(timer)
        print(math.floor(timer.value))
        local fadedImage = fadedImageTable:getImage(math.floor(timer.value))
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