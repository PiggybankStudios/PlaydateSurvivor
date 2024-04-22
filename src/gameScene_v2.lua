local pd 	<const> = playdate
local gfx 	<const> = pd.graphics
local tm 	<const> = gfx.tilemap
local ldtk 	<const> = LDtk


ldtk.load("Resources/Levels/world.ldtk", false)


local tilemaps = {0, 0, 0, 0} -- room for extra tilemaps in case there's a level with a lot of layers
local totalTilemaps = #tilemaps
local tilemap_combined = 0
local world, x, y, width, height = 0, 0, 0, 0, 0


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local DRAW <const> = gfx.image.draw

-- Draws only the tiles that are in-frame
function updateGameScene()
	
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

local pushContext 			<const> = gfx.pushContext
local popContext 			<const> = gfx.popContext
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

local bump_newWorld			<const> = bump.newWorld
local bump_addToWorld		<const> = addToWorld

local worldToBullets 		<const> = sendWorldCollidersToBullets
local worldToEnemies 		<const> = sendWorldCollidersToEnemies


-- TO DO: make a level selection system
function gameScene_init()
	local level_name = "Level_0"
	local levelRect = ldtk_getRect(level_name)
	x = levelRect.x
	y = levelRect.y
	width = levelRect.width
	height = levelRect.height

	gameScene_goToLevel(level_name)
end


function gameScene_goToLevel(level_name)

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

					r.x = rect.x * tileSize
					r.y = rect.y * tileSize
					r.width = rect.width * tileSize
					r.height = rect.height * tileSize
					r.tag = TAGS.walls
					bump_addToWorld(world, r, r.x, r.y, r.width, r.height)
				end
				
			end
		end
	end

	-- combine the separate tilemaps into a single image, based on their zIndex
	tilemap_combined = newImage(width, height, colorBlack) 
	pushContext(tilemap_combined)
		for i = 1, totalTilemaps do
			if tilemaps[i] == 0 then break end
			drawIgnoringOffset(tilemaps[i], 0, 0)
		end
	popContext()


	-- Perform inits at start of level, and pass the new world collision to everything that needs it
	initPlayerInNewWorld(world, 200, 200)	-- TO DO: make a spawn pos in the level editor, then find it for here
	worldToBullets(world)
	worldToEnemies(world)
	
	-- TO DO - finish below functions and localize
	addItemSpriteToList()
	addParticleSpriteToList()
	--addUIBanner()

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


local setColor		<const> = gfx.setColor
local drawRect 		<const> = gfx.drawRect
local drawText 		<const> = gfx.drawText
local setFont 		<const> = gfx.setFont

local font = gfx.font.new('Resources/Fonts/peridot_7')

local function getCellRect(world, cx, cy)
	local cellSize = world.cellSize
	local l, t = world:toWorld(cx, cy)
	return l, t, cellSize, cellSize
end


local drawCells 		= false
local drawColliders 	= false
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

			drawRect(rX, rY, rW, rH)
		end
	end
end
