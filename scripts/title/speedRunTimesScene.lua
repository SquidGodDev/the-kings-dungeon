local pd <const> = playdate
local gfx <const> = playdate.graphics

local util <const> = utilities

class('SpeedRunTimesScene').extends(gfx.sprite)

function SpeedRunTimesScene:init()
    local blackImage = gfx.image.new(400, 240, gfx.kColorBlack)
    gfx.sprite.setBackgroundDrawingCallback(function()
        blackImage:draw(0, 0)
    end)
    local largeFont = gfx.font.new("images/fonts/m5x7-24")

    local worldOneTimeText = "World 1 Time: "
    if not BEST_TIME_WORLD_1 then
        worldOneTimeText = worldOneTimeText .. "----"
    else
        worldOneTimeText = worldOneTimeText .. self:timeFormat(BEST_TIME_WORLD_1)
    end
    local worldOneTimeSprite = util.centeredTextSpriteFont(worldOneTimeText, largeFont)
    worldOneTimeSprite:moveTo(200, 80)
    worldOneTimeSprite:add()

    local worldTwoTimeText = "World 2 Time: "
    if not BEST_TIME_WORLD_2 then
        worldTwoTimeText = worldTwoTimeText .. "----"
    else
        worldTwoTimeText = worldTwoTimeText .. self:timeFormat(BEST_TIME_WORLD_2)
    end
    local worldTwoTimeSprite = util.centeredTextSpriteFont(worldTwoTimeText, largeFont)
    worldTwoTimeSprite:moveTo(200, 160)
    worldTwoTimeSprite:add()

    self:add()
end

function SpeedRunTimesScene:update()
    if pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB) then
        SCENE_MANAGER:switchScene(TitleScene)
    end
end

function SpeedRunTimesScene:timeFormat(time)
    local seconds = tonumber(string.format("%.2f", time / 1000))
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = string.format("%.2f", seconds - minutes * 60)
    return tostring(minutes) .. " min " .. remainingSeconds .. " sec"
end