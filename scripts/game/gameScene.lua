local pd <const> = playdate
local gfx <const> = playdate.graphics

DIRECTIONS = {
	north = "north",
	south = "south",
	east = "east",
	west = "west"
}

TAGS = {
	CLIMABLE = 1
}

Z_INDEXES = {
	PLAYER = 100
}

local ldtk <const> = LDtk

local usePrecomputedLevels = not pd.isSimulator

-- Load the ldtk main file
ldtk.load("level/level.ldtk", usePrecomputedLevels)

-- if we run in the simulator, we export the level to the save directory.
if pd.isSimulator then
	ldtk.export_to_lua_files()
end

class('GameScene').extends()

function GameScene:init()
    self:goToLevel("Level_0")

	self.player = Player(200, 120, self)
end

function GameScene:enterRoom(direction)
	local level = ldtk.get_neighbours(self.level_name, direction)[1]
	self:goToLevel(level)
	self.player:add()
	if direction == DIRECTIONS.north then
		self.player:moveTo(self.player.x, 240)
	elseif direction == DIRECTIONS.south then
		self.player:moveTo(self.player.x, 0)
	elseif direction == DIRECTIONS.east then
		self.player:moveTo(0, self.player.y)
	elseif direction == DIRECTIONS.west then
		self.player:moveTo(400, self.player.y)
	end
end

function GameScene:goToLevel(level_name)
    if not level_name then return end

	local previous_level = self.level_name

	self.level_name = level_name
	ldtk.load_level(level_name)

	-- we release the previous level after loading the new one so that it doesn't unload the tileset if we reuse it
	ldtk.release_level(previous_level)
	gfx.sprite.removeAll()

	self.layerSprites = {}
	for layer_name, layer in pairs(ldtk.get_layers(level_name)) do
		if layer.tiles then
			local tilemap = ldtk.create_tilemap(level_name, layer_name)

			local layerSprite = gfx.sprite.new()
			layerSprite:setTilemap(tilemap)
			layerSprite:moveTo(0, 0)
			layerSprite:setCenter(0, 0)
			layerSprite:setZIndex(layer.zIndex)
			layerSprite:add()
			self.layerSprites[layer_name] = layerSprite

			local nonSolidTiles = ldtk.get_empty_tileIDs(level_name, "Solid", layer_name)

			if nonSolidTiles then
				gfx.sprite.addWallSprites(tilemap, nonSolidTiles)
			end

			local nonClimableTiles = ldtk.get_empty_tileIDs(level_name, "Climable", layer_name)

			if nonClimableTiles then
				local climableTiles = gfx.sprite.addWallSprites(tilemap, nonClimableTiles)
				for i=1,#climableTiles do
					local climableTile = climableTiles[i]
					climableTile:setTag(TAGS.CLIMABLE)
				end
			end
		end
	end
end