# The Kings Dungeon
Source code for my Playdate game, "The Kings Dungeon". Play in this tiny metroidvania, making your way through platforming challenges and unlocking different abilities to progress through the game. Inspired by [Ascent](https://johanpeitz.itch.io/ascent) on PICO-8. You can find this game on [Itch IO](https://squidgod.itch.io/the-kings-dungeon).

<img src="https://github.com/user-attachments/assets/7e26d658-53ee-443a-a7aa-20012a355f34" width="400" height="240"/>
<img src="https://github.com/user-attachments/assets/c6a0bb9e-c009-4173-964c-e6e2e0644e8f" width="400" height="240"/>
<img src="https://github.com/user-attachments/assets/28d93ce7-beb0-4105-9214-38576c9c1120" width="400" height="240"/>
<img src="https://github.com/user-attachments/assets/8f306eed-b9c4-453c-b444-b0e6947264ab" width="400" height="240"/>

## Project Structure
- `level/` - Holds LDtk level
  - `LDtk_lua_levels` - Cached level data made by `LDtk.lua` library
  - `level.ldtk` - Actual LDtk level that was edited in level editor
- `scripts/`  
  - `end/`
    - `endScene.lua` - UI for showing finished time and score after finished run
  - `game/`
    - `entities/` - Interactable level elements
      - `cheese.lua`
      - `chest.lua`
      - `crankIndicator.lua`
      - `destructableBlock.lua`
      - `gate.lua`
      - `spike.lua`
      - `spikeball.lua`
      - `water.lua`
      - `waterfall.lua`
    - `npcs/`
      - `dialogueManager.lua` - Manager for NPC dialog
      - `npc.lua` - Sprite for npc
      - `speechBubble.lua` - Speech bubble text
    - `dialog.lua` - Full screen dialog for ability unlock
    - `gameScene.lua` - Handles level creation and game management
    - `player.lua` - Player character controller
  - `libraries/`
    - `AnimatedSprite.lua` - By Whitebrim: animation state machine
    - `Fluid.lua` - By Dustin Mierau: simple fluid simulation
    - `LDtk.lua` - By Nic Magnier: converts from LDtk to Playdate compatible data
    - `SceneManager.lua` - Handles scene transitions
    - `Utilities.lua` - Some simple text/sprite functions
  - `title/`
    - `menu.lua` - Main menu UI
    - `speedRunTimesScene.lua` - UI for showing run times
    - `titleScene.lua` - Title screen (uses `menu.lua`)
- `main.lua` - All imports, globals, and data saving

## License
All code is licensed under the terms of the MIT license, with the exception of `Fluid.lua` by Dustin Mierau.
