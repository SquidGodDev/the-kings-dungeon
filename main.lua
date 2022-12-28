-- CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Libraries
import "scripts/libraries/AnimatedSprite"
import "scripts/libraries/SceneManager"
import "scripts/libraries/LDtk"

-- Game
import "scripts/game/gameScene"
import "scripts/game/player"

-- Title
import "scripts/title/titleScene"

local pd <const> = playdate
local gfx <const> = playdate.graphics

COLLISION_GROUPS = {
    player = 1
}

GameScene()

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()
end
