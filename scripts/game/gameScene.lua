local pd <const> = playdate
local gfx <const> = playdate.graphics

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
	HAZARDS = 50
}

COLLISION_GROUPS = {
    player = 1
}

CHEESE = 0
MAX_CHEESE = 11

local ldtk <const> = LDtk

local usePrecomputedLevels = not pd.isSimulator

-- Load the ldtk main file
ldtk.load("level/level.ldtk", usePrecomputedLevels)

-- if we run in the simulator, we export the level to the save directory.
if pd.isSimulator then
	ldtk.export_to_lua_files()
end

local waterRushSound <const> = pd.sound.sampleplayer.new("sound/entities/waterfall")

class('GameScene').extends()

function GameScene:init()
	GameMusic:play(0)
	TitleMusic:stop()
    self:goToLevel("Level_29")

	self.spawnX = 9 * 32 -- 5
	self.spawnY = 3 * 32 -- 2
	self.player = Player(self.spawnX, self.spawnY, self)
end

function GameScene:resetLevel()
	self:goToLevel(self.level_name)
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