local pd 	<const> = playdate
local gfx 	<const> = pd.graphics
local vec 	<const> = pd.geometry.vector2D

local random 	<const> = math.random
local abs 		<const> = math.abs
local sqrt		<const> = math.sqrt

local dt 		<const> = getDT()

local GET_SIZE 	<const> = gfx.image.getSize


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local img_Health 	= gfx.image.new('Resources/Sprites/item/iHealth')
local img_Weapon 	= gfx.image.new('Resources/Sprites/item/iWeapon')
local img_Shield 	= gfx.image.new('Resources/Sprites/item/iShield')
local img_AbsorbAll = gfx.image.new('Resources/Sprites/item/iAbsorbAll')
local img_EXP_1 	= gfx.image.new('Resources/Sprites/item/iEXP1')
local img_EXP_2 	= gfx.image.new('Resources/Sprites/item/iEXP2')
local img_EXP_3 	= gfx.image.new('Resources/Sprites/item/iEXP3')
local img_EXP_6 	= gfx.image.new('Resources/Sprites/item/iEXP6')
local img_EXP_9 	= gfx.image.new('Resources/Sprites/item/iEXP9')
local img_EXP_16 	= gfx.image.new('Resources/Sprites/item/iEXP16')
local img_Luck		= gfx.image.new('Resources/Sprites/item/iLuck')
local img_Mun2		= gfx.image.new('Resources/Sprites/item/iMun2')
local img_Mun10 	= gfx.image.new('Resources/Sprites/item/iMun10')
local img_Mun50 	= gfx.image.new('Resources/Sprites/item/iMun50')

local IMAGE_LIST = {
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
	img_Mun50	
}

-- items should be square images, so checking only width is fine
local IMAGE_SIZE_HALF = {}
local BIGGEST_ITEM_SIZE = 0
for i = 1, #IMAGE_LIST do
	local width = GET_SIZE(IMAGE_LIST[i])
	IMAGE_SIZE_HALF[i] = width * 0.5
	BIGGEST_ITEM_SIZE = BIGGEST_ITEM_SIZE < width and width or BIGGEST_ITEM_SIZE
end


-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

-- Constants
local ITEM_MOVE_SPEED	 			<const> = 6
local PLAYER_COLLISION_DISTANCE 	<const> = 20 * 20	-- distance from player (SQUARED) that is close enough to mimic a collision

-- Variables
local defaultDistanceCheck = getPlayerMagnetStat()
local absorbAllFlag = false



-- Items
local maxItems <const> = 200
local activeItems = 0

-- Arrays
local itemType = {}
local posX = {}
local posY = {}
local rotation = {}
local distanceCheck = {}
local lifeTime = {}



-- +--------------------------------------------------------------+
-- |                    Init, Create, Delete                      |
-- +--------------------------------------------------------------+


--- Init Arrays ---
for i = 1, maxItems do
	itemType[i] = 0
	posX[i] = 0
	posY[i] = 0
	rotation[i] = 0
	distanceCheck[i] = 0
	lifeTime[i] = 0
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

function spawnShieldItem()
	createItem(ITEM_TYPE.shield, 100, 100)
end


-- To be called at the end of the pause animation.
function getPauseTime_Items(pauseTime)
	for i = 1, activeItems do
		local life = lifeTime[i]
		if life > -1 then
			lifeTime[i] = life + pauseTime
		end
	end
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
end


local HEAL_PLAYER 			<const> = healPlayer
local NEW_WEAPON_GRABBED 	<const> = newWeaponGrabbed
local SHIELD_PLAYER 		<const> = shieldPlayer
local ADD_EXP 				<const> = addPlayerEXP
local ADD_PLAYER_LUCK 		<const> = addPlayerLuck
local ADD_MUN 				<const> = addMun

local activateItemEffect = {
	-- Health
	function() HEAL_PLAYER(20) 		return 1 end,

	-- Weapon
	function() NEW_WEAPON_GRABBED() return 1 end,

	-- Shield
	function() SHIELD_PLAYER(10000) return 1 end,

	--AbsorbAll
	function() absorbAllFlag = true return 1 end,

	--Exp1
	function() ADD_EXP(1) 			return 0 end,

	--Exp2
	function() ADD_EXP(2) 			return 0 end,

	--Exp3
	function() ADD_EXP(3) 			return 0 end,

	--Exp6
	function() ADD_EXP(6) 			return 0 end,

	--Exp9
	function() ADD_EXP(9) 			return 0 end,

	--Exp16
	function() ADD_EXP(16) 			return 0 end,

	--Luck
	function() ADD_PLAYER_LUCK() 	return 1 end,

	--Mun2
	function() ADD_MUN(2) 			return 0 end,

	--Mun10
	function() ADD_MUN(5) 			return 0 end,

	--Mun50
	function() ADD_MUN(20) 			return 0 end
}



-- +--------------------------------------------------------------+
-- |                          Management                          |
-- +--------------------------------------------------------------+


local SCREEN_MIN_X 			<const> = -BIGGEST_ITEM_SIZE
local SCREEN_MAX_X 			<const> = 400
local SCREEN_MIN_Y 			<const> = getBannerHeight() - BIGGEST_ITEM_SIZE
local SCREEN_MAX_Y 			<const> = 240

-- update function for moving items and removing from item lists
local function updateItemLists(time, playerX, playerY, offsetX, offsetY)
	
	-- Items Collected Count
	local itemsCollected = 0

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
				IMAGE_LIST[type]:draw(itemX - halfSize, itemY - halfSize) 
			end
			i = i + 1

		-- Delete
		else 
			itemsCollected = itemsCollected + activateItemEffect[type]()
			deleteItem(i, currentActiveItems)
			currentActiveItems = currentActiveItems - 1
		end 
	end


	-- After all items are changed for absorb distance, reset this flag
	removeDistanceCheck = false
	activeItems = currentActiveItems

	-- Return the items collected this frame
	return itemsCollected
end



-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+




function updateItems(time, playerX, playerY, offsetX, offsetY)
	
	-- Returns the items collected this tick, after updating all items
	return updateItemLists(time, playerX, playerY, offsetX, offsetY)
	
end