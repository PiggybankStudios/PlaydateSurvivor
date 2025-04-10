local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local random 	<const> = math.random
local sqrt		<const> = math.sqrt
local dt 		<const> = getDT()

-- drawing
local GET_SIZE 		<const> = gfx.image.getSize
local NEW_IMAGE 	<const> = gfx.image.new
local DRAW_IMAGE 	<const> = gfx.image.draw


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local img_Health 		
local img_Weapon 		
local img_Shield 		
local img_AbsorbAll 	
local img_EXP_1 		
local img_EXP_2 		
local img_EXP_3 		
local img_EXP_6 		
local img_EXP_9 		
local img_EXP_16 		
local img_Luck			
local img_Mun2			
local img_Mun10 		
local img_Mun50 		
local img_Petal 		
local img_MultiplierToken

local IMAGE_LIST

local IMAGE_SIZE_HALF = {}
local BIGGEST_ITEM_SIZE

local SCREEN_MAX_X	<const> = 400
local SCREEN_MAX_Y	<const> = 240
local SCREEN_MIN_X 			= 0
local SCREEN_MIN_Y			= 0


local function load_item_v2_images()

	img_Health 			= NEW_IMAGE('Resources/Sprites/item/iHealth')
	img_Weapon 			= NEW_IMAGE('Resources/Sprites/item/iWeapon')
	img_Shield 			= NEW_IMAGE('Resources/Sprites/item/iShield')
	img_AbsorbAll 		= NEW_IMAGE('Resources/Sprites/item/iAbsorbAll')
	img_EXP_1 			= NEW_IMAGE('Resources/Sprites/item/iEXP1')
	img_EXP_2 			= NEW_IMAGE('Resources/Sprites/item/iEXP2')
	img_EXP_3 			= NEW_IMAGE('Resources/Sprites/item/iEXP3')
	img_EXP_6 			= NEW_IMAGE('Resources/Sprites/item/iEXP6')
	img_EXP_9 			= NEW_IMAGE('Resources/Sprites/item/iEXP9')
	img_EXP_16 			= NEW_IMAGE('Resources/Sprites/item/iEXP16')
	img_Luck			= NEW_IMAGE('Resources/Sprites/item/iLuck')
	img_Mun2			= NEW_IMAGE('Resources/Sprites/item/iMun2')
	img_Mun10 			= NEW_IMAGE('Resources/Sprites/item/iMun10')
	img_Mun50 			= NEW_IMAGE('Resources/Sprites/item/iMun50')
	img_Petal 			= NEW_IMAGE('Resources/Sprites/item/iPetal')
	img_MultiplierToken	= NEW_IMAGE('Resources/Sheets/ActionBanner/MultiplierToken')

	IMAGE_LIST = {
		img_Health,
		img_Weapon,
		img_Shield,
		img_AbsorbAll,
		img_EXP_1,
		img_EXP_2,
		img_EXP_3,
		img_EXP_6,
		img_EXP_9,
		img_EXP_16,  
		img_Luck,
		img_Mun2,
		img_Mun10,
		img_Mun50,
		img_Petal,
		img_MultiplierToken
	}

	-- items should be square images, so checking only width is fine
	BIGGEST_ITEM_SIZE = 0
	for i = 1, #IMAGE_LIST do
		local width = GET_SIZE(IMAGE_LIST[i])
		IMAGE_SIZE_HALF[i] = width * 0.5
		BIGGEST_ITEM_SIZE = BIGGEST_ITEM_SIZE < width and width or BIGGEST_ITEM_SIZE
	end

	SCREEN_MIN_X = -BIGGEST_ITEM_SIZE
	SCREEN_MIN_Y = getBannerHeight() - BIGGEST_ITEM_SIZE
end


-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

-- Constants
local ITEM_MOVE_SPEED	 			<const> = 6
local PLAYER_COLLISION_DISTANCE 	<const> = 20 * 20	-- distance from player (SQUARED) that is close enough to mimic a collision

-- Variables
local itemsCollected = 0
local defaultDistanceCheck = getPlayerMagnetStat()
local absorbAllFlag = false

-- Items
local maxItems <const> = 200
local activeItems = 0

-- Tags Reference
local ITEM_TAG <const> = ITEM_TYPE

-- Arrays
local itemType = {}
local posX = {}
local posY = {}
local rotation = {}
local distanceCheck = {}
local lifeTime = {}

-- Letter Lists
local droppedLetterList = {}
local collectedLetters = 0


-- +--------------------------------------------------------------+
-- |                    Init, Create, Delete                      |
-- +--------------------------------------------------------------+

function item_v2_initialize_data()

	print("")
	print(" -- Initializing Items --")
	local currentTask = 0
	local totalTasks = 2

	--- 1: Loading Images ---
	currentTask += 1
	coroutine.yield(currentTask, totalTasks, "Items: Loading Images")
	load_item_v2_images()

	--- 2: Init Arrays ---
	currentTask += 1
	coroutine.yield(currentTask, totalTasks, "Items: Initializing Arrays")
	for i = 1, maxItems do
		itemType[i] = 0
		posX[i] = 0
		posY[i] = 0
		rotation[i] = 0
		distanceCheck[i] = 0
		lifeTime[i] = 0
	end
end


function createItem(type, spawnX, spawnY)
	
	local total = activeItems + 1		
	if total > maxItems then return end
	activeItems = total

	itemType[total] = type
	posX[total] = spawnX
	posY[total] = spawnY
	rotation[total] = 0
	distanceCheck[total] = defaultDistanceCheck * defaultDistanceCheck -- This is squared so it can be compared with a squared magnitude as distance
	lifeTime[total] = -1
end


-- TO DO:
	-- need to test if replacing an item with a petal when at max items actually works
function createPetal(letter, spawnX, spawnY)

	local total = activeItems + 1
	local id
	if total > maxItems then
		total -= 1
		for k = 1, maxItems do -- find a non-petal item and replace it
			if itemType[k] ~= ITEM_TAG.petal then
				id = k
				break
			end
		end
	else 
		id = total
		activeItems = total
	end
	
	-- petal letter details
	local nextLetter = #droppedLetterList + 1
	droppedLetterList[nextLetter] = letter

	-- item details
	itemType[id] = ITEM_TAG.petal
	posX[id] = spawnX
	posY[id] = spawnY
	rotation[id] = 0 
	distanceCheck[total] = defaultDistanceCheck * defaultDistanceCheck
	lifeTime[total] = -1

end


-- overwrite the to-be-deleted item with the item at the end
local function deleteItem(i, total)
	itemType[i] = itemType[total]
	posX[i] = posX[total]
	posY[i] = posY[total]
	rotation[i] = rotation[total]
	distanceCheck[i] = distanceCheck[total]
	lifeTime[i] = lifeTime[total]
end


-- GLOBAL debug create
function debugItemSpawn()
	local type = 1
	for i = 1, 100 do		
		local x = random(180, 220)
		local y = random(180, 220)
		createItem(type, x, y)
	end
end

--[[
function spawnShieldItem()
	createItem(ITEM_TYPE.shield, 100, 100)
end
]]


-- To be called at the end of the pause animation.
function getPauseTime_Items(pauseTime)
	for i = 1, activeItems do
		local life = lifeTime[i]
		if life > -1 then
			lifeTime[i] = life + pauseTime
		end
	end
end


function items_GetItemsCollectedInFinishedArea()
	return itemsCollected
end


-- +--------------------------------------------------------------+
-- |                           Effects                            |
-- +--------------------------------------------------------------+


--GLOBAL adjust distance check
function setDistanceCheckToPlayerMagnetStat(value)
	defaultDistanceCheck = value
end


-- GLOBAL clear all items
function clearItems()
	activeItems = 0
	itemsCollected = 0
end



local HEAL_PLAYER 				<const> = healPlayer
local NEW_WEAPON_GRABBED 		<const> = newWeaponGrabbed
local SHIELD_PLAYER 			<const> = shieldPlayer
local ADD_EXP 					<const> = addPlayerEXP
local ADD_PLAYER_LUCK 			<const> = addPlayerLuck
local ADD_MUN 					<const> = addMun
local COLLECT_LETTER 			<const> = flowerGame_CollectNewLetter
local COLLECT_MULTIPLIER_TOKEN 	<const> = player_CollectNewMultiplierToken


-- Returning a value indicates how many items were collected when this item is picked up. 
-- Money and EXP are not added towards the total item count.
local activateItemEffect = {
	-- Health
	function() HEAL_PLAYER(20) 		return 1 end,

	-- Weapon
	function() NEW_WEAPON_GRABBED() return 1 end,

	-- Shield
	function(time) SHIELD_PLAYER(time + 10000) return 1 end,

	-- AbsorbAll
	function() absorbAllFlag = true return 1 end,

	-- Exp1
	function() ADD_EXP(1) 			return 0 end,

	-- Exp2
	function() ADD_EXP(2) 			return 0 end,

	-- Exp3
	function() ADD_EXP(3) 			return 0 end,

	-- Exp6
	function() ADD_EXP(6) 			return 0 end,

	-- Exp9
	function() ADD_EXP(9) 			return 0 end,

	-- Exp16
	function() ADD_EXP(16) 			return 0 end,

	-- Luck
	function() ADD_PLAYER_LUCK() 	return 1 end,

	-- Mun2
	function() ADD_MUN(2) 			return 0 end,

	-- Mun10
	function() ADD_MUN(5) 			return 0 end,

	-- Mun50
	function() ADD_MUN(20) 			return 0 end,

	-- Petal
	function(time, i) 
		collectedLetters += 1
		local newLetter = droppedLetterList[collectedLetters]
		flowerGame_CollectNewLetter(newLetter) 
		banner_CollectNewPetal(time, newLetter, posX[i], posY[i])	
		return 1 
	end,

	-- Multiplier Token
	function(time) COLLECT_MULTIPLIER_TOKEN(time) return 1 end
}




-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

-- update function for moving items and removing from item lists
function updateItems(time, playerX, playerY, offsetX, offsetY)
	
	-- No matter which item set the ABSORB_ALL flag, make sure all existing items are affected
	local removeDistanceCheck = false
	if absorbAllFlag then
		removeDistanceCheck = true
		absorbAllFlag = false
	end

	-- Loop over all items
	local i = 1
	local currentActiveItems = activeItems
	while i <= currentActiveItems do

		local type = itemType[i]
		local itemX, itemY = posX[i], posY[i]

		-- Move and Delete
		local xDiff, yDiff = playerX - itemX, playerY - itemY
		local magnitudeSquared = xDiff * xDiff + yDiff * yDiff
		if removeDistanceCheck then distanceCheck[i] = magnitudeSquared + 1000 end  -- absorb all check

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

		-- Draw
		local itemLifeTime = lifeTime[i]
		if 	itemLifeTime < 0 or 	-- lifeTime is -1, which means it doesn't die by a timer - alive indefinitely.
			time < itemLifeTime 	-- Any lifeTime greater than -1 will die by a timer.
			then

			local drawX = itemX + offsetX
			local drawY = itemY + offsetY		
			if 	SCREEN_MIN_X < drawX and drawX < SCREEN_MAX_X and 
				SCREEN_MIN_Y < drawY and drawY < SCREEN_MAX_Y then

				local halfSize = IMAGE_SIZE_HALF[type]
				DRAW_IMAGE(IMAGE_LIST[type], itemX - halfSize, itemY - halfSize) 
			end
			i = i + 1

		-- Delete
		else 
			itemsCollected = itemsCollected + activateItemEffect[type](time, i)
			deleteItem(i, currentActiveItems)
			currentActiveItems = currentActiveItems - 1
		end 
	end


	-- After all items are changed for absorb distance, reset this flag
	removeDistanceCheck = false
	activeItems = currentActiveItems
end



-- used for the post-pause screen countdown to redraw the screen
function redrawItems(offsetX, offsetY)
	local currentActiveItems = activeItems
	for i = 1, currentActiveItems do	

		local x, y = posX[i], posY[i]
		local drawX = x + offsetX
		local drawY = y + offsetY		
		if 	SCREEN_MIN_X < drawX and drawX < SCREEN_MAX_X and 
			SCREEN_MIN_Y < drawY and drawY < SCREEN_MAX_Y then

			local type = itemType[i]
			local halfSize = IMAGE_SIZE_HALF[type]
			DRAW_IMAGE(IMAGE_LIST[type], x - halfSize, y - halfSize) 
		end

	end
end


