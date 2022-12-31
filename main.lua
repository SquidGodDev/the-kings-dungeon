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
import "scripts/libraries/Utilities"
import "scripts/libraries/DrawText"

-- Game
import "scripts/game/gameScene"
import "scripts/game/player"
import "scripts/game/entities/gate"
import "scripts/game/entities/crankIndicator"
import "scripts/game/entities/destructableBlock"
import "scripts/game/entities/spike"
import "scripts/game/entities/spikeball"
import "scripts/game/entities/chest"
import "scripts/game/dialog"
import "scripts/game/npcs/speechBubble"
import "scripts/game/npcs/npc"
import "scripts/game/npcs/dialogueManager"

-- Title
import "scripts/title/titleScene"

local pd <const> = playdate
local gfx <const> = playdate.graphics

GameScene()

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()
end
