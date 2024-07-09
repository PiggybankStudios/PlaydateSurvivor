local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

local random 	<const> = math.random
local sqrt		<const> = math.sqrt

local dt 		<const> = getDT()

local GET_SIZE 		<const> = gfx.image.getSize
local GET_IMAGE 	<const> = gfx.imagetable.getImage



-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local imgTable_PlayerSpawner	= gfx.imagetable.new('Resources/Sheets/Objects/playerSpawner')
local imgTable_Teleporter 		= gfx.imagetable.new('Resources/Sheets/Objects/teleporter')
local imgTable_Spikeball 		= gfx.imagetable.new('Resources/Sheets/Objects/spike')
local imgTable_EnemySpawner 	= gfx.imagetable.new('Resources/Sheets/Objects/enemySpawner')


local IMAGETABLE_LIST = {
	imgTable_PlayerSpawner,
	imgTable_Teleporter,
	imgTable_Spikeball,
	imgTable_EnemySpawner
}

-- items should be square images, so checking only width is fine
local IMAGE_SIZE = {}
local IMAGE_SIZE_HALF = {}
local BIGGEST_HALF_IMAGE_SIZE = 0
for i = 1, #IMAGETABLE_LIST do
	local width = GET_SIZE( GET_IMAGE(IMAGETABLE_LIST[i], 1) )
	IMAGE_SIZE[i] = width
	IMAGE_SIZE_HALF[i] = width * 0.5
	BIGGEST_HALF_IMAGE_SIZE = BIGGEST_HALF_IMAGE_SIZE < IMAGE_SIZE_HALF[i] and IMAGE_SIZE_HALF[i] or BIGGEST_HALF_IMAGE_SIZE
end



-- +--------------------------------------------------------------+
-- |                         Object Data                          |
-- +--------------------------------------------------------------+


local function getObjectType(name)
	if not name then 
		print("Entity name not provided when trying to find object type. Returning 0.")
		return 0
	end

	if 		name == "PlayerSpawner" then return 1
	elseif 	name == "Teleporter" 	then return 2
	elseif 	name == "SpikeBall" 	then return 3
	elseif  name == "EnemySpawner"	then return 4
	end

	print ("Entity name not found when trying to find object type. This name needs to be added to 'getObjectType' function.")
	return 0
end


local STATES = {
	default = 1,
	toggle_off = 2,
	damage_player = 3
}


-- remove?
local OBJECT_STATES = {
	STATES.default, 		-- teleporter
	STATES.damage_player 	-- spikeball
}


local DAMAGE_TAG 		<const> = TAGS.damage
local BREAKABLE_TAG 	<const> = TAGS.breakable
local OBJECT_TAGS = {
	false, 			-- playerSpawner
	false,			-- teleporter
	DAMAGE_TAG,	 	-- spikeball
	BREAKABLE_TAG	-- enemySpawner
}


-- neg 1 means object cannot be damaged or be deleted via heath
local OBJECT_HEALTH = {
	1, 		-- playerSpawner
	1,		-- teleporter 
	1, 		-- spikeball
	100		-- enemySpawner
}


-- This is squared so it can be compared with a squared magnitude as distance
-- no DIST for playerSpawner
local DIST_TELEPORTER 	<const> = 20 * 20
local DIST_SPIKEBALL 	<const> = 18 * 18
local DIST_ENEMYSPAWNER	<const> = 30 * 30

local OBJECT_DISTANCE_CHECK = {
	0, 					-- playerSpawner
	DIST_TELEPORTER,
	DIST_SPIKEBALL,
	DIST_ENEMYSPAWNER
}


-- Object Types
local PLAYERSPAWNER_TYPE 	<const> = getObjectType("PlayerSpawner")
local TELEPORTER_TYPE 		<const> = getObjectType("Teleporter")
local SPIKEBALL_TYPE 		<const> = getObjectType("SpikeBall")
local ENEMYSPAWNER_TYPE 	<const> = getObjectType("EnemySpawner")


-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

-- Objects
local maxObjects <const> = 100
local activeObjects = 0

-- Arrays
local objectType = {}
local posX = {}
local posY = {}
local distanceCheck = {}
local health = {}
local state = {}
local image = {}
local animTimer = {}
local animFrame = {}
local miscTimer = {}
local collisionDetails = {}

-- World
local worldRef
local cellSize
local changeLevel = false
local playerSpawnCount = 0
local playerSpawnX = { 0, 0, 0, 0, 0}
local playerSpawnY = { 0, 0, 0, 0, 0}


-- +--------------------------------------------------------------+
-- |                    Init, Create, Delete                      |
-- +--------------------------------------------------------------+


--- Init Arrays ---
for i = 1, maxObjects do
	objectType[i] = 0
	posX[i] = 0
	posY[i] = 0
	distanceCheck[i] = 0
	health[i] = 0
	state[i] = 0
	image[i] = 0
	animTimer[i] = 0
	animFrame[i] = 0
	miscTimer[i] = 0
	collisionDetails[i] = 0
end


local ADD_OBJECT <const> = worldAdd_Fast
function createObject(entity)	

	local total = activeObjects + 1
	if total > maxObjects then return end
	activeObjects = total
	
	local type = getObjectType(entity.name)
	local x = entity.position.x
	local y = entity.position.y
	local cell = (x // cellSize + 1) + (y // cellSize + 1)

	objectType[total] = type
	posX[total] = x
	posY[total] = y
	distanceCheck[total] = OBJECT_DISTANCE_CHECK[type]
	health[total] = OBJECT_HEALTH[type]
	state[total] = 0
	image[total] = GET_IMAGE(IMAGETABLE_LIST[type], 1)
	animTimer[total] = 0
	animFrame[total] = cell % 2 == 0 and 1 or #IMAGETABLE_LIST[type] // 2
	miscTimer[total] = 0

	-- object collider
	local object_tag = OBJECT_TAGS[type]
	if object_tag ~= false then 
		collisionDetails[total] = { tag = object_tag, 
									objectIndex = total }
		ADD_OBJECT(	worldRef, 
					collisionDetails[total], 
					x - IMAGE_SIZE_HALF[type], 
					y - IMAGE_SIZE_HALF[type], 
					IMAGE_SIZE[type], 
					IMAGE_SIZE[type])
	end

	-- playerSpawner
	if type == PLAYERSPAWNER_TYPE then 
		playerSpawnCount = playerSpawnCount + 1
		local playerX = x - IMAGE_SIZE_HALF[PLAYERSPAWNER_TYPE] + 4 
		local playerY = y - IMAGE_SIZE_HALF[PLAYERSPAWNER_TYPE] + 2 
		playerSpawnX[playerSpawnCount] = playerX
		playerSpawnY[playerSpawnCount] = playerY
	end
end


local REMOVE_OBJECT <const> = worldRemove_Fast
-- overwrite the to-be-deleted item with the item at the end
local function deleteObject(i, total)
	objectType[i] = objectType[total]
	posX[i] = posX[total]
	posY[i] = posY[total]
	distanceCheck[i] = distanceCheck[total]
	health[i] = health[total]
	state[i] = state[total]
	image[i] = image[total]
	animTimer[i] = animTimer[total]
	animFrame[i] = animFrame[total]
	miscTimer[i] = miscTimer[total]

	-- If this object has collision data in the world, then move it.
	REMOVE_OBJECT(worldRef, collisionDetails[i])
	collisionDetails[i] = collisionDetails[total]
	collisionDetails[i].objectIndex = i
end


function clearObjects()
	activeObjects = 0
end

-- To be called after level creation, b/c level start clears the sprite list.
function sendWorldCollidersToObjects(gameSceneWorld)
	worldRef = gameSceneWorld
	cellSize = worldRef.cellSize
end


-- +--------------------------------------------------------------+
-- |                       Object Actions                         |
-- +--------------------------------------------------------------+

local PLAYERSPAWNER_ANIM_SPEED 			<const> = 60 
local PLAYERSPAWNER_FRAME_COUNT 		<const> = #imgTable_PlayerSpawner

local TELEPORTER_ANIM_SPEED 			<const> = 60
local TELEPORTER_FRAME_COUNT 			<const> = #imgTable_Teleporter
		
local SPIKEBALL_ANIM_SPEED 				<const> = 400
local SPIKEBALL_FRAME_COUNT				<const> = #imgTable_Spikeball
	
local ENEMYSPAWNER_ANIM_SPEED 			<const> = 400
local ENEMYSPAWNER_FRAME_COUNT 			<const> = #imgTable_EnemySpawner
local ENEMYSPAWNER_SPAWN_RATE 			<const> = 400
local ENEMYSPAWNER_SPAWN_RATE_RANDOM	<const> = 300

local DAMAGE_BOUNCE_PLAYER 	<const> = damageBouncePlayer
local CREATE_ENEMY 			<const> = createEnemy
local random 				<const> = math.random


local PerformObjectActions = {

	-- Player Spawner
	function(i, time)

		-- animate
		local frame = animFrame[i]
		if animTimer[i] < time then
			animTimer[i] = time + PLAYERSPAWNER_ANIM_SPEED
			frame = frame % PLAYERSPAWNER_FRAME_COUNT + 1
			animFrame[i] = frame
			image[i] = GET_IMAGE(imgTable_PlayerSpawner, frame)
		end
	end,

	-- Teleporter
	function(i, time, playerX, playerY) 

		-- animate
		local frame = animFrame[i]
		if animTimer[i] < time then
			animTimer[i] = time + TELEPORTER_ANIM_SPEED
			frame = frame % TELEPORTER_FRAME_COUNT + 1
			animFrame[i] = frame
			image[i] = GET_IMAGE(imgTable_Teleporter, frame)
		end

		-- teleport player
		local xDiff, yDiff = playerX - posX[i], playerY - posY[i]
		local magnitudeSquared = xDiff * xDiff + yDiff * yDiff
		if magnitudeSquared < DIST_TELEPORTER then 
			changeLevel = true
		end

	end,

	-- Spike Ball
	function(i, time, playerX, playerY) 

		-- animate
		local frame = animFrame[i]
		if animTimer[i] < time then
			animTimer[i] = time + SPIKEBALL_ANIM_SPEED
			frame = frame % SPIKEBALL_FRAME_COUNT + 1
			animFrame[i] = frame
			image[i] = GET_IMAGE(imgTable_Spikeball, frame)
		end
		
		-- damage player
		local objectX, objectY = posX[i], posY[i]
		local xDiff, yDiff = playerX - objectX, playerY - objectY
		local magnitudeSquared = xDiff * xDiff + yDiff * yDiff
		if magnitudeSquared < DIST_SPIKEBALL then 
			DAMAGE_BOUNCE_PLAYER(objectX, objectY, xDiff, yDiff)
		end
	end,

	-- Enemy Spawner
	function(i, time, playerX, playerY)

		-- animate
		local frame = animFrame[i]
		if animTimer[i] < time then
			animTimer[i] = time + ENEMYSPAWNER_ANIM_SPEED
			frame = frame % ENEMYSPAWNER_FRAME_COUNT + 1
			animFrame[i] = frame 
			image[i] = GET_IMAGE(imgTable_EnemySpawner, frame)
		end

		-- damage player
		local objectX, objectY = posX[i], posY[i]
		local xDiff, yDiff = playerX - objectX, playerY - objectY
		local magnitudeSquared = xDiff * xDiff + yDiff * yDiff
		if magnitudeSquared < DIST_ENEMYSPAWNER then
			DAMAGE_BOUNCE_PLAYER(objectX, objectY, xDiff, yDiff)
		end

		-- spawn enemies
		if miscTimer[i] < time then
			miscTimer[i] = time + ENEMYSPAWNER_SPAWN_RATE + random(ENEMYSPAWNER_SPAWN_RATE_RANDOM)
			local enemyType = 1
			local dirX, dirY = random(0, 1) * 2 - 1, random(0, 1) * 2 - 1
			local vX, vY = random() * dirX * 12, random() * dirY * 12
			CREATE_ENEMY(enemyType, objectX, objectY, vX, vY)
		end
	end
}


function damageObject(i, amount)
	local type = objectType[i]
	if OBJECT_TAGS[type] ~= BREAKABLE_TAG then return end 	-- if this object can't be damaged, then abort.

	health[i] = health[i] - amount
end


function getPlayerSpawnPosition()
	local index = 1
	if playerSpawnCount > 1 then
		index = random(1, playerSpawnCount)
	end
	return playerSpawnX[index], playerSpawnY[index]
end


function resetPlayerSpawnPositions()
	playerSpawnCount = 0
end


function getPauseTime_Objects(pauseTime)

	for i = 1, activeObjects do
		--animTimer[i] - this doesn't need to be given the pause time, it's updated frequently enough.
		miscTimer[i] = miscTimer[i] + pauseTime
	end
end



-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

local SCREEN_MIN_X 			<const> = -BIGGEST_HALF_IMAGE_SIZE
local SCREEN_MAX_X 			<const> = 400 + BIGGEST_HALF_IMAGE_SIZE
local SCREEN_MIN_Y 			<const> = getBannerHeight() - BIGGEST_HALF_IMAGE_SIZE
local SCREEN_MAX_Y 			<const> = 240 + BIGGEST_HALF_IMAGE_SIZE

local FAST_DRAW <const> = gfx.image.draw


function updateObjects(time, playerX, playerY, offsetX, offsetY)
	
	-- Loop over all items
	local i = 1
	local currentActiveObjects = activeObjects
	while i <= currentActiveObjects do

		local type = objectType[i]
		local objectX, objectY = posX[i], posY[i]

		-- Move and Delete
		--[[
		local xDiff, yDiff = playerX - itemX, playerY - itemY
		local magnitudeSquared = xDiff * xDiff + yDiff * yDiff

		if 	magnitudeSquared < distanceCheck[i] then
			local scaledMagnitude = ITEM_MOVE_SPEED / sqrt(magnitudeSquared)
			itemX = xDiff * scaledMagnitude + itemX
			itemY = yDiff * scaledMagnitude + itemY
			posX[i] = itemX
			posY[i] = itemY

			if magnitudeSquared < PLAYER_COLLISION_DISTANCE then 
				lifeTime[i] = 0
			end
		end	
		]]	

		-- Interactions
		PerformObjectActions[type](i, time, playerX, playerY)

		-- Draw
		if 	health[i] > 0 then 
			local drawX = objectX + offsetX
			local drawY = objectY + offsetY		
			if 	SCREEN_MIN_X < drawX and drawX < SCREEN_MAX_X and 
				SCREEN_MIN_Y < drawY and drawY < SCREEN_MAX_Y then

				local halfSize = IMAGE_SIZE_HALF[type]
				FAST_DRAW(image[i], objectX - halfSize, objectY - halfSize) 
			end
			i = i + 1

		-- Delete
		else 
			deleteObject(i, currentActiveObjects)
			currentActiveObjects = currentActiveObjects - 1
		end 
	end

	activeObjects = currentActiveObjects

	-- change level check
	if changeLevel then 
		changeLevel = false
		runTransitionStart( GAMESTATE.flowerMinigame, TRANSITION_TYPE.growingCircles, flowerMiniGame_StateStart )
	end
end


-- used for the post-pause screen countdown to redraw the screen
function redrawObjects(offsetX, offsetY)
	local currentActiveObjects = activeObjects
	for i = 1, currentActiveObjects do	

		local x, y = posX[i], posY[i]
		local drawX = x + offsetX
		local drawY = y + offsetY		
		if 	SCREEN_MIN_X < drawX and drawX < SCREEN_MAX_X and 
			SCREEN_MIN_Y < drawY and drawY < SCREEN_MAX_Y then

			local type = objectType[i]
			local halfSize = IMAGE_SIZE_HALF[type]
			FAST_DRAW(image[i], x - halfSize, y - halfSize) 
		end

	end
end