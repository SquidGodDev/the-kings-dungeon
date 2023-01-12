-- CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "CoreLibs/animation"
import "CoreLibs/ui"

-- Libraries
import "scripts/libraries/AnimatedSprite"
import "scripts/libraries/SceneManager"
import "scripts/libraries/LDtk"
import "scripts/libraries/Utilities"
import "scripts/libraries/Fluid"

-- Game
import "scripts/game/gameScene"
import "scripts/game/player"
import "scripts/game/entities/gate"
import "scripts/game/entities/crankIndicator"
import "scripts/game/entities/destructableBlock"
import "scripts/game/entities/spike"
import "scripts/game/entities/spikeball"
import "scripts/game/entities/chest"
import "scripts/game/entities/waterfall"
import "scripts/game/entities/water"
import "scripts/game/entities/cheese"
import "scripts/game/dialog"
import "scripts/game/npcs/speechBubble"
import "scripts/game/npcs/npc"
import "scripts/game/npcs/dialogueManager"

-- Title
import "scripts/title/titleScene"
import "scripts/title/menu"

-- End
import "scripts/end/endScene"

SCENE_MANAGER = SceneManager()

local pd <const> = playdate
local gfx <const> = playdate.graphics

GameMusic = pd.sound.sampleplayer.new("sound/music/CHIPTUNE_Loop_Minstrel_Dance")
GameMusic:setVolume(0.5)

TitleMusic = pd.sound.sampleplayer.new("sound/music/titleScreenMusic")
TitleMusic:setVolume(0.5)

EndMusic = pd.sound.sampleplayer.new("sound/music/gameEndMusic")
EndMusic:setVolume(0.5)

-- Game Data
CUR_LEVEL = "Level_0"
CUR_X = 2 * 32
CUR_Y = 5 * 32

CHEESE = 0

ACTIVE_SAVE = false
SPEED_RUN_MODE = false
LEVELS = nil

WORLD = 1

GAME_TIME = 0

ABILITIES = {
    crankKeyAbility = false,
    smashAbility = false,
    wallClimbAbility = false,
    doubleJumpAbility = false,
    dashAbility = false
}

local gameData = pd.datastore.read()
if gameData then
    CUR_LEVEL = gameData.curLevel
    CUR_X = gameData.curX
    CUR_Y = gameData.curY
    CHEESE = gameData.cheese
    ACTIVE_SAVE = gameData.activeSave
    SPEED_RUN_MODE = gameData.speedRunMode
    ABILITIES = gameData.abilities
    LEVELS = gameData.levels
    WORLD = gameData.world
    GAME_TIME = gameData.gameTime
end

TitleScene()

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()
end

local function saveGameData()
    local data = {
        curLevel = CUR_LEVEL,
        curX = CUR_X,
        curY = CUR_Y,
        cheese = CHEESE,
        activeSave = ACTIVE_SAVE,
        speedRunMode = SPEED_RUN_MODE,
        abilities = ABILITIES,
        levels = LEVELS,
        world = WORLD,
        gameTime = GAME_TIME
    }
    pd.datastore.write(data)
end

function pd.gameWillTerminate()
    saveGameData()
end

function pd.gameWillSleep()
    saveGameData()
end