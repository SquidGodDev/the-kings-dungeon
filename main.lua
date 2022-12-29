-- CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "CoreLibs/animation"

-- Libraries
import "scripts/libraries/AnimatedSprite"
import "scripts/libraries/SceneManager"
import "scripts/libraries/LDtk"

-- Game
import "scripts/game/gameScene"
import "scripts/game/player"
import "scripts/game/entities/gate"
import "scripts/game/entities/crankIndicator"

-- Title
import "scripts/title/titleScene"

local pd <const> = playdate
local gfx <const> = playdate.graphics

GameScene()

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()
end
