local pd 	<const> = playdate
local gfx 	<const> = pd.graphics
local tm 	<const> = gfx.tilemap
local ldtk 	<const> = LDtk

local LOCK_FOCUS 				<const> = gfx.lockFocus
local UNLOCK_FOCUS 				<const> = gfx.unlockFocus	
local NEXT 						<const> = next

local DRAW 						<const> = gfx.image.draw
local CLEAR_DISPLAY				<const> = gfx.clear
local NEW_IMAGE					<const> = gfx.image.new
local COLOR_BLACK				<const> = gfx.kColorBlack

local GET_TM_COLLISION_RECTS	<const> = tm.getCollisionRects
local GET_TM_TILE_SIZE			<const> = tm.getTileSize
local TM_DRAW_STATIC			<const> = tm.drawIgnoringOffset
	
local LDTK_LOAD 				<const> = ldtk.load	
local LDTK_GET_RECT				<const> = ldtk.get_rect
local LDTK_GET_LAYERS			<const> = ldtk.get_layers
local LDTK_CREATE_TILEMAP		<const> = ldtk.create_tilemap
local LDTK_GET_EMPTY_TILE_IDS	<const> = ldtk.get_empty_tileIDs
--local ldtk_get_level_list		<const> = ldtk.get_level_list

local BUMP_NEW_WORLD			<const> = bump.newWorld
local BUMP_ADD_TO_WORLD			<const> = addToWorld

local GET_LEVEL_DATA 			<const> = flowerGame_get_Level_Data
	
local WORLD_TO_OBJECTS 			<const> = sendWorldCollidersToObjects
local WORLD_TO_BULLETS 			<const> = sendWorldCollidersToBullets
local WORLD_TO_ENEMIES 			<const> = sendWorldCollidersToEnemies


-- +--------------------------------------------------------------+
-- |                          Variables                           |
-- +--------------------------------------------------------------+

local tilemaps = {0, 0, 0, 0} -- room for extra tilemaps in case there's a level with a lot of layers
local totalTilemaps = #tilemaps
local tilemap_combined = 0

local world, width, height = 0, 0, 0, 0, 0
local offsetWidth, offsetHeight = 0, 0

local currentLevel = 0

-- World files in LDtk, will probably use for theming and other tilemaps later on.
local worlds_list = {
	"Resources/Levels/world.ldtk"
}


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

-- Draw the level, and clear the frame only when the camera goes outside the level bounds.
function updateGameScene(screenOffsetX, screenOffsetY)
	
	if 	0 < screenOffsetX or screenOffsetX < offsetWidth or 
		0 < screenOffsetY or screenOffsetY < offsetHeight then
			CLEAR_DISPLAY()
	end
	DRAW(tilemap_combined, 0, 0)


	
	-- DEBUG - only draw white background
	--[[
	local offX, offY = gfx.getDrawOffset()
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRect(-offX, -offY, 400, 240)
	]]
end


-- +--------------------------------------------------------------+
-- |                        Initialization                        |
-- +--------------------------------------------------------------+

function gameScene_v2_initialize_world()

	print("")
	print(" -- Initializing World of Levels --")
	local currentTask = 1
	local totalTasks = 1
	coroutine.yield(currentTask, totalTasks, "Levels: Loading")

	local timeStart = pd.getCurrentTimeMilliseconds()
	LDTK_LOAD(worlds_list[1])
	local timeEnd = pd.getCurrentTimeMilliseconds()

	print("time to load level: " .. timeEnd - timeStart)
end


-- +--------------------------------------------------------------+
-- |                  Level Loading & Collisions                  |
-- +--------------------------------------------------------------+


local function CreateBumpCollisionForLayer(layer, layer_name, level_name, tileString, tileTag)

	local zIndex = layer.zIndex + 1	
	local tileMap = LDTK_CREATE_TILEMAP(level_name, layer_name)	
	tilemaps[zIndex] = tileMap		

	local emptyTiles = LDTK_GET_EMPTY_TILE_IDS(level_name, tileString, layer_name)
	if (emptyTiles) then

		-- Bump Collision
		local wallRectList = GET_TM_COLLISION_RECTS(tileMap, emptyTiles)
		local tileSize = GET_TM_TILE_SIZE(tileMap)

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
			r.tag = tileTag
			BUMP_ADD_TO_WORLD(world, r, r.x, r.y, r.width, r.height)
		end
	end
end


local function gameScene_goToLevel(level_index)

	-- separate level details
	local level_data = GET_LEVEL_DATA(level_index)
	local level_name = level_data.name
	local levelRect = LDTK_GET_RECT(level_name)
	width = levelRect.width
	height = levelRect.height
	offsetWidth = -width + 400
	offsetHeight = -height + 240


	-- catch for if a tileset png name follows the naming convention required by LDtk
	local level_layers = LDTK_GET_LAYERS(level_name)
	if level_layers == nil then
		print("no layers in level - something might be wrong with a file name")
		return
	end

	-- Create a bump collision world
	world = BUMP_NEW_WORLD(16) -- default cell size is 64

	-- load in the level's tileset and collision
	for layer_name, layer in NEXT, level_layers do
		if layer.tiles then
			CreateBumpCollisionForLayer(layer, layer_name, level_name, "Solid", TAGS.walls) 	-- Walls
			CreateBumpCollisionForLayer(layer, layer_name, level_name, "Damage", TAGS.damage)	-- Damaging Tiles	
		end
	end

	-- combine the separate tilemaps into a single image, based on their zIndex
	tilemap_combined = NEW_IMAGE(width, height, COLOR_BLACK) 
	LOCK_FOCUS(tilemap_combined)
		for i = 1, totalTilemaps do
			if tilemaps[i] ~= 0 then -- If this layer doesn't have anything, then don't attempt to draw. Just skip it.
				TM_DRAW_STATIC(tilemaps[i], 0, 0)
			end
		end
	UNLOCK_FOCUS()

	-- clear previous arrays: bullets, enemies, items, objects
	--clearBullets()
	--clearEnemies()
	--clearItems()
	--clearObjects()

	-- Add objects (ldtk entities) to room
	WORLD_TO_OBJECTS(world)
	local entity_list, entity_counts = ldtk.get_entities_and_counts(level_name)
	objects_SetObjectDetailsInLevel(level_data, entity_counts)
	for _, entity in NEXT, entity_list do
		createObject(entity)		
	end

	-- Perform inits at start of level, and pass the new world collision to everything that needs it
	create_ActionBannerUI()
	local playerX, playerY = getPlayerSpawnPosition() -- a playerSpawner object sets the spawn position.
	initPlayerInNewWorld(world, playerX, playerY)
	WORLD_TO_BULLETS(world)
	WORLD_TO_ENEMIES(world)

	-- Run the 'End Transition' animation
	runTransitionEnd()
end


-- TO DO: make a level selection system
function gameScene_startFirstLevel()
	local level_index = 1
	gameScene_goToLevel(level_index)
end


function gameScene_NextLevel()
	-- new level name
	local puzzleCount = flowerGame_puzzleCount()
	local new_level_index = math.random(1, puzzleCount)
	if new_level_index == currentLevel then 
		new_level_index = new_level_index + 1 
		if new_level_index > puzzleCount then new_level_index = 1 end
	end

	--TEST--
	--newLevel = 1
	--------

	currentLevel = new_level_index
	gameScene_goToLevel(new_level_index)
end


-- +--------------------------------------------------------------+
-- |                   End of Action Game Clear                   |
-- +--------------------------------------------------------------+

local CLEAR_ACTION_BANNER_UI 	<const> = clear_ActionBannerUI
local SHOTS_FIRED 				<const> = bullets_GetShotsFiredInFinishedArea
local ENEMIES_KILLED 			<const> = enemy_v2_getEnemiesKilledInFinishedArea
local ITEMS_GRABBED 			<const> = items_GetItemsCollectedInFinishedArea

-- Perform all the 'Clear' functions for the action game in-between transitions.
function gameScene_ClearState()

	CLEAR_ACTION_BANNER_UI()
	player_UpdateShotsFired( SHOTS_FIRED() )
	player_UpdateEnemiesKilled( ENEMIES_KILLED() )
	player_UpdateItemsGrabbed( ITEMS_GRABBED() )

	clearBullets()
	clearEnemies()
	clearItems()
	clearObjects()

	print("")
	print("------------------")
	print("game scene cleared")
	print("------------------")
	print("")
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

	setColor(COLOR_BLACK)

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
				setColor(COLOR_BLACK)
				drawRect(rX, rY, rW, rH)
			else
				drawRect(rX, rY, rW, rH)
			end
		end
	end
end
