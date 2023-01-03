local pd <const> = playdate
local gfx <const> = playdate.graphics

class('TitleScene').extends(gfx.sprite)

function TitleScene:init()
    -- Create title image
    self:add()
end

function TitleScene:update()
    if pd.buttonJustPressed(pd.kButtonA) then
        SCENE_MANAGER:switchScene(GameScene)
    end
end