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
	Player = 4
}

Z_INDEXES = {
	PLAYER = 100,
	GATE = 0,
	UI = 1000
}

COLLISION_GROUPS = {
    player = 1
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

	self.level_name = level_name

	-- we release the previous level after loading the new one so that it doesn't unload the tileset if we reuse it
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

	for _, entity in ipairs(ldtk.get_entities(level_name)) do
		if entity.name=="Gate" then
			local gateX, gateY = entity.position.x, entity.position.y
			Gate(gateX, gateY, entity)
		end
	end
end