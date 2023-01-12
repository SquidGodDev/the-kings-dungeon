local pd <const> = playdate
local gfx <const> = playdate.graphics

local round <const> = function(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

DIRECTIONS = {
	north = "north",
	south = "south",
	east = "east",
	west = "west"
}

TAGS = {
	Solid = 1,
	Climable = 2,
	WallClimable = 3,
	Player = 4,
	Destructable = 5,
	Hazard = 6,
	Interactable = 7,
	Pickup = 8
}

Z_INDEXES = {
	PLAYER = 100,
	NPC = 90,
	ABILITY = 150,
	GATE = 0,
	UI = 1000,
	DIALOG = 1200,
	WATERFALL = 10,
	WATER = 20,
	PICKUP = 30,
	CHEST = 50,
	DESTRUCTABLE_BLOCK = 50,
	HAZARDS = 50,
	TIMER = 1500
}

COLLISION_GROUPS = {
    player = 1
}

MAX_CHEESE_WORLD_1 = 11
MAX_CHEESE_WORLD_2 = 8

local ldtk <const> = LDtk

local usePrecomputedLevels = not pd.isSimulator

-- Load the ldtk main file
ldtk.load("level/level.ldtk", usePrecomputedLevels)

-- if we run in the simulator, we export the level to the save directory.
if pd.isSimulator then
	ldtk.export_to_lua_files()
end

local waterRushSound <const> = pd.sound.sampleplayer.new("sound/entities/waterfall")

class('GameScene').extends(gfx.sprite)

function GameScene:init(world, level, x, y, abilities, levels)
	GameMusic:play(0)
	TitleMusic:stop()
	self.baseTime = pd.getCurrentTimeMilliseconds()
	self.savedTime = 0
	self.elapsedTime = 0
	if level then
		ldtk.load_saved_entities(levels)
		self:goToLevel(level)
		self.spawnX = x
		self.spawnY = y
		self.savedTime = GAME_TIME
	else
		CHEESE = 0
		WORLD = world
		if world == 1 then
			self:goToLevel("Level_0")
			self.spawnX = 2 * 32 -- 2
			self.spawnY = 5 * 32 -- 5
		else
			self:goToLevel("Level_36") -- 36
			self.spawnX = 3 * 32 -- 3
			self.spawnY = 4 * 32 -- 4
		end
	end

	self.player = Player(self.spawnX, self.spawnY, self, abilities)

	local systemMenu = pd.getSystemMenu()
	systemMenu:removeAllMenuItems()
	systemMenu:addMenuItem("Save + Exit", function()
		CUR_LEVEL = self.level_name
		CUR_X = self.spawnX
		CUR_Y = self.spawnY
		ABILITIES = {
			crankKeyAbility = self.player.crankKeyAbility,
			smashAbility = self.player.smashAbility,
			wallClimbAbility = self.player.wallClimbAbility,
			doubleJumpAbility = self.player.doubleJumpAbility,
			dashAbility = self.player.dashAbility
		}
		ACTIVE_SAVE = true
		LEVELS = LDtk.save_entites()
		SCENE_MANAGER:switchScene(TitleScene)
		GameMusic:stop()
		GAME_TIME = self.savedTime + self.elapsedTime
	end)

	self.timeSprite = gfx.sprite.new()
	self.timeSprite:setCenter(1.0, 0.0)
	self.timeSprite:setZIndex(Z_INDEXES.TIMER)
	if SPEED_RUN_MODE then
		self.timeSprite:add()
		self.timeSprite:moveTo(400, 0)
	end
	self.speedRunMode = SPEED_RUN_MODE
	self.timeFont = gfx.font.new("images/fonts/m5x7-24")
	self.timeFontHeight = self.timeFont:getHeight()

	self:add()
end

function GameScene:update()
	self.elapsedTime = pd.getCurrentTimeMilliseconds() - self.baseTime
	if self.speedRunMode then
		local timeText = string.format("%.2f", (self.savedTime + self.elapsedTime) / 1000)
		local imageWidth = self.timeFont:getTextWidth(timeText)
		local imageHeight = self.timeFontHeight
		local timeImage = gfx.image.new(imageWidth, imageHeight)
		gfx.pushContext(timeImage)
			gfx.setColor(gfx.kColorBlack)
			gfx.fillRect(0, 0, imageWidth, imageHeight)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			self.timeFont:drawText(timeText, 0, 0)
		gfx.popContext()
		self.timeSprite:setImage(timeImage)
	end
end

function GameScene:resetLevel()
	self:goToLevel(self.level_name)
	self.timeSprite:add()
	self:add()
	self.player:add()
	self.player:moveTo(self.spawnX, self.spawnY)
end

function GameScene:resetPlayer()
	self.player:moveTo(self.spawnX, self.spawnY)
end

function GameScene:enterRoom(direction)
	waterRushSound:stop()
	local level = ldtk.get_neighbours(self.level_name, direction)[1]
	self:goToLevel(level)
	self.player:add()
	self:add()
	self.timeSprite:add()
	local spawnX, spawnY
	if direction == DIRECTIONS.north then
		spawnX, spawnY = self.player.x, 240
	elseif direction == DIRECTIONS.south then
		spawnX, spawnY = self.player.x, 0
	elseif direction == DIRECTIONS.east then
		spawnX, spawnY = 0, self.player.y
	elseif direction == DIRECTIONS.west then
		spawnX, spawnY = 400, self.player.y
	end
	self.player:moveTo(spawnX, spawnY)
	self.spawnX = spawnX
	self.spawnY = spawnY
end

function GameScene:goToLevel(level_name)
    if not level_name then return end

	self.level_name = level_name

	gfx.sprite.removeAll()
	local allTimers = pd.timer.allTimers()
    for _, timer in ipairs(allTimers) do
        timer:remove()
    end

	for layer_name, layer in pairs(ldtk.get_layers(level_name)) do
		if layer.tiles then
			local tilemap = ldtk.create_tilemap(level_name, layer_name)

			local layerSprite = gfx.sprite.new()
			layerSprite:setTilemap(tilemap)
			layerSprite:moveTo(0, 0)
			layerSprite:setCenter(0, 0)
			layerSprite:setZIndex(layer.zIndex)
			layerSprite:add()

			for enum, tag in pairs(TAGS) do
				local emptyTiles = ldtk.get_empty_tileIDs(level_name, enum, layer_name)
				if emptyTiles then
					local tileSprites = gfx.sprite.addWallSprites(tilemap, emptyTiles)
					for i=1,#tileSprites do
						local tileSprite = tileSprites[i]
						tileSprite:setTag(tag)
					end
				end
			end
		end
	end

	local waterEntity
	local waterfallList = {}
	for _, entity in ipairs(ldtk.get_entities(level_name)) do
		local entityX, entityY = entity.position.x, entity.position.y
		local entityName = entity.name
		if entityName == "Gate" then
			Gate(entityX, entityY, entity)
		elseif entityName == "DestructableBlock" then
			DestructableBlock(entityX, entityY, entity)
		elseif entityName == "Spike" then
			Spike(entityX, entityY)
		elseif entityName == "Spikeball" then
			Spikeball(entityX, entityY, entity)
		elseif entityName == "Chest" then
			Chest(entityX, entityY, entity)
		elseif entityName == "NPC" then
			Npc(entityX, entityY, entity)
		elseif entityName == "Water" then
			waterEntity = entity
		elseif entityName == "Waterfall" then
			table.insert(waterfallList, entity)
		elseif entityName == "Cheese" then
			Cheese(entityX, entityY, entity)
		end
	end

	if #waterfallList > 0 then
		waterRushSound:play(0)
	end
	if waterEntity then
		Water(waterEntity.position.x, waterEntity.position.y, waterEntity, waterfallList)
	else
		for i=1,#waterfallList do
			local waterfallEntity = waterfallList[i]
			Waterfall(waterfallEntity.position.x, waterfallEntity.position.y, waterfallEntity)
		end
	end
end