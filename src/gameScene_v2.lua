local gfx <const> = playdate.graphics
local ldtk <const> = LDtk
--local bump = import "bump"

ldtk.load("Resources/Levels/world.ldtk", false)

class('gameScene').extends()

local world
local x, y, width, height
local drawState = false




-- +--------------------------------------------------------------+
-- |                  Level Loading & Collisions                  |
-- +--------------------------------------------------------------+


function gameScene:init()
	local level_name = "Level_0"
	local levelRect = ldtk.get_rect(level_name)
	x = levelRect.x
	y = levelRect.y
	width = levelRect.width
	height = levelRect.height

	self:goToLevel(level_name)
end


function gameScene:goToLevel(level_name)
	gfx.sprite.removeAll()

	-- catch for if a tileset png name follows the naming convention required by LDtk
	if ldtk.get_layers(level_name) == nil then
		print("no layers in level - something might be wrong with a file name")
		return
	end

	world = bump.newWorld(16) -- default cell size is 64
	--local width, height = self.width, self.height
	-- !!player position here --


	-- load in the level's tileset and (hopefully) collision
	for layer_name, layer in pairs(ldtk.get_layers(level_name)) do
		if layer.tiles then
			local tilemap = ldtk.create_tilemap(level_name, layer_name)
			
			local layerSprite = gfx.sprite.new()
			layerSprite:setTilemap(tilemap)
			layerSprite:setCenter(0, 0)
			layerSprite:moveTo(0, 0)
			layerSprite:setZIndex(layer.zIndex)
			layerSprite:add()

			local emptyTiles = ldtk.get_empty_tileIDs(level_name, "Solid", layer_name)
			if (emptyTiles) then

				-- playdate collision
				--[[
				local wallSpriteList = gfx.sprite.addWallSprites(tilemap, emptyTiles)
				for i = 1, #wallSpriteList do
					wallSpriteList[i]:setGroups(GROUPS.walls)	-- set each collider to the wall group
					wallSpriteList[i]:setTag(TAGS.walls)
				end
				]]

				-- Bump Collision
				local wallRectList = tilemap:getCollisionRects(emptyTiles)
				local tileSize = tilemap:getTileSize()
				for i = 1, #wallRectList do
					local rect = wallRectList[i]
					local r = { x = 0, y = 0, width = 0, height = 0, tag = 0 }
					r.x = rect.x * tileSize
					r.y = rect.y * tileSize
					r.width = rect.width * tileSize
					r.height = rect.height * tileSize
					r.tag = TAGS.walls
					world:add(r, r.x, r.y, r.width, r.height)
				end
				
			end
		end
	end
	

	-- add the player's sprite back to the list and start the scene
	addPlayerSpritesToList(world, width, height)
	addBulletSpriteToList(world)
	addEnemiesSpriteToList(world)
	addItemSpriteToList()
	addParticleSpriteToList()
	addUIBanner()
	snapCamera()
end


-- +--------------------------------------------------------------+
-- |                           Globals                            |
-- +--------------------------------------------------------------+


function getWorld()
	return world
end


-- +--------------------------------------------------------------+
-- |                          Debugging                           |
-- +--------------------------------------------------------------+

local drawOffset <const> = gfx.getDrawOffset

local debugImage = gfx.image.new(400, 240, gfx.kColorWhite)
local debugSprite = gfx.sprite.new(debugImage)
debugSprite:setIgnoresDrawOffset(true)
debugSprite:moveTo(200, 120)
debugSprite:setZIndex(ZINDEX.item)
------------------

local function getCellRect(world, cx, cy)
	local cellSize = world.cellSize
	local l, t = world:toWorld(cx, cy)
	return l, t, cellSize, cellSize
end


function worldToggleDrawCells()
	drawState = not drawState

	debugImage:clear(gfx.kColorClear)
	debugSprite:remove()
end


function gameSceneUpdate()

	if drawState == false then
		return
	end

	local offsetX
	local offsetY 
	offsetX, offsetY = drawOffset()

	debugImage:clear(gfx.kColorWhite)
	gfx.pushContext(debugImage)

		gfx.setColor(gfx.kColorBlack)

		
		-- draw cells
		for cy, row in pairs(world.rows) do
			for cx, cell in pairs(row) do
				local l, t, w, h = getCellRect(world, cx, cy)
				l += offsetX
				t += offsetY
				local cellCount = cell.itemCount
				
				gfx.drawRect(l, t, w, h)
				gfx.drawText(cellCount, l + (0.4 * w), t + (0.4 * h))
			end
		end
		

		-- draw colliders
		local colliders, length = world:queryRect(0, 0, width, height)
		for i = 1, length do 
			local r = colliders[i]
			gfx.drawRect(r.x + offsetX, r.y + offsetY, r.width, r.height)

			if r.index then
				gfx.drawText(r.index, r.x + offsetX - 15, r.y + offsetY)
			end
		end

	gfx.popContext()
	debugSprite:setImage(debugImage)
	debugSprite:add()
end