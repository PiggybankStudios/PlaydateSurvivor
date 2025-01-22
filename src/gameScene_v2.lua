local pd 	<const> = playdate
local gfx 	<const> = pd.graphics
local tm 	<const> = gfx.tilemap
local ldtk 	<const> = LDtk


ldtk.load("Resources/Levels/world.ldtk", false)


local tilemaps = {0, 0, 0, 0} -- room for extra tilemaps in case there's a level with a lot of layers
local totalTilemaps = #tilemaps
local tilemap_combined = 0

local world, x, y, width, height = 0, 0, 0, 0, 0
local offsetWidth, offsetHeight = 0, 0

local currentLevel = 0
local level_list = ldtk.get_level_list()


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local DRAW 		<const> = gfx.image.draw
local CLEAR 	<const> = gfx.clear

-- Draw the level, and clear the frame only when the camera goes outside the level bounds.
function updateGameScene(screenOffsetX, screenOffsetY)
	
	if 	0 < screenOffsetX or screenOffsetX < offsetWidth or 
		0 < screenOffsetY or screenOffsetY < offsetHeight then
			CLEAR()
	end
	DRAW(tilemap_combined, 0, 0)


	--[[
	-- DEBUG - only draw white background
	local offX, offY = gfx.getDrawOffset()
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRect(-offX, -offY, 400, 240)
	]]
end



-- +--------------------------------------------------------------+
-- |                  Level Loading & Collisions                  |
-- +--------------------------------------------------------------+

local lockFocus 			<const> = gfx.lockFocus
local unlockFocus 			<const> = gfx.unlockFocus

local NEXT 					<const> = next

local newImage				<const> = gfx.image.new
local colorBlack			<const> = gfx.kColorBlack

local getCollisionRects		<const> = tm.getCollisionRects
local getTileSize			<const> = tm.getTileSize
local drawIgnoringOffset	<const> = tm.drawIgnoringOffset
	
local ldtk_getRect 			<const> = ldtk.get_rect
local ldtk_getLayers		<const> = ldtk.get_layers
local ldtk_createTilemap	<const> = ldtk.create_tilemap
local ldtk_getEmptyTileIDs	<const> = ldtk.get_empty_tileIDs
local ldtk_get_level_list	<const> = ldtk.get_level_list

local bump_newWorld			<const> = bump.newWorld
local bump_addToWorld		<const> = addToWorld

local worldToObjects  		<const> = sendWorldCollidersToObjects
local worldToBullets 		<const> = sendWorldCollidersToBullets
local worldToEnemies 		<const> = sendWorldCollidersToEnemies



local function gameScene_goToLevel(level_name)

	-- catch for if a tileset png name follows the naming convention required by LDtk
	if ldtk_getLayers(level_name) == nil then
		print("no layers in level - something might be wrong with a file name")
		return
	end

	-- Create a bump collision world
	world = bump_newWorld(16) -- default cell size is 64

	-- load in the level's tileset and collision
	for layer_name, layer in NEXT, ldtk_getLayers(level_name) do
		if layer.tiles then

			local zIndex = layer.zIndex + 1		
			tilemaps[zIndex] = ldtk_createTilemap(level_name, layer_name)			


			--- Walls ---
			local emptyTiles = ldtk_getEmptyTileIDs(level_name, "Solid", layer_name)
			if (emptyTiles) then

				-- Bump Collision
				local wallRectList = getCollisionRects(tilemaps[zIndex], emptyTiles)
				local tileSize = getTileSize(tilemaps[zIndex])

				for i = 1, #wallRectList do
					local rect = wallRectList[i]
					-- weak key-value table to be able to be garbage collected
					local r = setmetatable(	{ x = 0, y = 0, width = 0, height = 0, tag = 0 },
											{ __mode = 'kv' }
											)

					-- add wall object to world
					r.x = rect.x * tileSize
					r.y = rect.y * tileSize
					r.width = rect.width * tileSize
					r.height = rect.height * tileSize
					r.tag = TAGS.walls
					bump_addToWorld(world, r, r.x, r.y, r.width, r.height)
				end
			end


			--- Damaging Tiles ---
			emptyTiles = ldtk_getEmptyTileIDs(level_name, "Damage", layer_name)
			if (emptyTiles) then

				-- Bump Collision
				local wallRectList = getCollisionRects(tilemaps[zIndex], emptyTiles)
				local tileSize = getTileSize(tilemaps[zIndex])

				for i = 1, #wallRectList do
					local rect = wallRectList[i]	
					-- weak key-value table to be able to be garbage collected
					local r = setmetatable(	{ x = 0, y = 0, width = 0, height = 0, tag = 0 },
											{ __mode = 'kv' }
											)					
					r.x = rect.x * tileSize
					r.y = rect.y * tileSize
					r.width = rect.width * tileSize
					r.height = rect.height * tileSize
					r.tag = TAGS.damage
					bump_addToWorld(world, r, r.x, r.y, r.width, r.height)
				end
			end
		end
	end


	-- combine the separate tilemaps into a single image, based on their zIndex
	tilemap_combined = newImage(width, height, colorBlack) 
	lockFocus(tilemap_combined)
		for i = 1, totalTilemaps do
			if tilemaps[i] ~= 0 then -- If this layer doesn't have anything, then don't attempt to draw. Just skip it.
				drawIgnoringOffset(tilemaps[i], 0, 0)
			end
		end
	unlockFocus()


	-- Add objects (ldtk entities) to room
	worldToObjects(world)
	resetPlayerSpawnPositions()
	for _, entity in NEXT, ldtk.get_entities(level_name) do
		createObject(entity)		
	end

	
	-- Perform inits at start of level, and pass the new world collision to everything that needs it
	local playerX, playerY = getPlayerSpawnPosition() -- a playerSpawner object sets the spawn position.
	initPlayerInNewWorld(world, playerX, playerY)
	worldToBullets(world)
	worldToEnemies(world)


	-- Run the 'End Transition' animation
	runTransitionEnd()
end



-- TO DO: make a level selection system
function gameScene_init()
	local level_name = "Level_3"
	local levelRect = ldtk_getRect(level_name)
	x = levelRect.x
	y = levelRect.y
	width = levelRect.width
	height = levelRect.height

	offsetWidth = -width + 400
	offsetHeight = -height + 240

	gameScene_goToLevel(level_name)
end


function gameScene_NextLevel()
	-- new level name
	local newLevel = math.random(1, #level_list)
	if newLevel == currentLevel then 
		newLevel = newLevel + 1 
		if newLevel > #level_list then newLevel = 1 end
	end

	--TEST--
	newLevel = 1
	--------

	currentLevel = newLevel

	-- clear bullets, enemies, items, objects
	clearBullets()
	clearEnemies()
	clearItems()
	clearObjects()

	-- new level setup
	local level_name = level_list[newLevel]
	local levelRect = ldtk_getRect(level_name)
	x = levelRect.x
	y = levelRect.y
	width = levelRect.width
	height = levelRect.height

	offsetWidth = -width + 400
	offsetHeight = -height + 240

	gameScene_goToLevel(level_name)
end

-- +--------------------------------------------------------------+
-- |                           Globals                            |
-- +--------------------------------------------------------------+


function getWorld()
	return world
end


-- +--------------------------------------------------------------+
-- |                            Debug                             |
-- +--------------------------------------------------------------+

local SET_DITHER_PATTERN 	<const> = gfx.setDitherPattern
local DITHER_DIAGONAL 		<const> = gfx.image.kDitherTypeDiagonalLine

local setColor		<const> = gfx.setColor
local drawRect 		<const> = gfx.drawRect
local fillRect 		<const> = gfx.fillRect
local drawText 		<const> = gfx.drawText
local setFont 		<const> = gfx.setFont

local font = gfx.font.new('Resources/Fonts/peridot_7')

local function getCellRect(world, cx, cy)
	local cellSize = world.cellSize
	local l, t = world:toWorld(cx, cy)
	return l, t, cellSize, cellSize
end


local drawCells 		= false
local drawColliders 	= true
local drawCellCount 	= false
local drawRectCoords 	= false

function gameSceneDebugUpdate()

	setColor(colorBlack)

	if drawCells then
		for cy, row in NEXT, world.rows do
			for cx, cell in NEXT, row do
				local l, t, w, h = getCellRect(world, cx, cy)
				drawRect(l, t, w, h)

				if drawCellCount then
					setFont(font)
					local cellCount = cell.itemCount
					drawText(cellCount, l + (0.4 * w), t + (0.4 * h))
				end
				if drawRectCoords then				
					setFont(font)
					drawText(cx .. "x", l + (0.1 * w), t + 0.05 * h)
					drawText(cy .. "y", l + (0.1 * w), t + (0.55 * h))
				end
			end
		end
	end
	
	if drawColliders then
		local colliders, length = world:queryRect(0, 0, width, height)
		for i = 1, length do 
			local item = colliders[i]
			local rX, rY, rW, rH = world:getRect(item)

			if item.tag == TAGS.damage then 
				SET_DITHER_PATTERN(0.6, DITHER_DIAGONAL)
				fillRect(rX, rY, rW, rH)
				setColor(colorBlack)
				drawRect(rX, rY, rW, rH)
			else
				drawRect(rX, rY, rW, rH)
			end
		end
	end
end
