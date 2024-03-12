local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local random <const> = math.random

local theCurrTime = 0
local playerPos = vec.new(0, 0)


-- Item Type Variables --
local itemMoveSpeed <const> = 120
local defaultDistanceCheck = getPlayerMagnetStat()
local playerCollisionDistance <const> = 15	-- distance from player that is close enough to mimic a collision

-- Items
local maxItems <const> = 500 -- max that can exist in the world at one time
local activeItems = 0
local absorbAllFlag = false

-- Arrays
local itemType = {}
local posX = {}
local posY = {}
local rotation = {}
local distanceCheck = {}
local lifeTime = {} -- NO LIFE TIMES


-----------
-- Debug --
local maxUpdateTimer = 0
local currentUpdateTimer = 0
-----------
-----------

-- +--------------------------------------------------------------+
-- |                           Timers                             |
-- +--------------------------------------------------------------+


local function getUpdateTimer()
	currentUpdateTimer = playdate.getElapsedTime()
	if maxUpdateTimer < currentUpdateTimer then
		maxUpdateTimer = currentUpdateTimer
		print("ITEM -- Update: " .. 1000*maxUpdateTimer)
	end
end


-- +--------------------------------------------------------------+
-- |                Init, Create, Delete, Handle                  |
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


-- LOCAL create
local function createItem(type, spawnX, spawnY)
	if activeItems >= maxItems then do return end end -- if too many items exist, then don't make another item

	activeItems += 1
	local total = activeItems

	itemType[total] = type
	posX[total] = spawnX
	posY[total] = spawnY
	rotation[total] = 0
	distanceCheck[total] = defaultDistanceCheck
	lifeTime[total] = -1
end


local function deleteItem(index, currentActiveItems)
	local i = index
	local total = currentActiveItems

	-- overwrite the to-be-deleted item with the item at the end
	itemType[i] = itemType[total]
	posX[i] = posX[total]
	posY[i] = posY[total]
	rotation[i] = rotation[total]
	distanceCheck[i] = distanceCheck[total]
	lifeTime[i] = lifeTime[total]
end


-- GLOBAL create
function spawnItem(type, spawnX, spawnY)
	createItem(type, spawnX, spawnY)
end


-- GLOBAL debug create
local create <const> = createItem
function debugItemSpawn()
	local type = 1
	for i = 1, 10000 do		
		local x = random(-1000, 1000)
		local y = random(-1000, 1000)
		create(type, x, y)
	end
	absorbAllFlag = true
end


-- +--------------------------------------------------------------+
-- |                       Item Management                        |
-- +--------------------------------------------------------------+


--GLOBAL adjust distance check
function setDistanceCheckToPlayerMagnetStat(value)
	defaultDistanceCheck = value
end


-- GLOBAL clear all items
function clearItems()
	activeItems = 0
end


local activateItemEffect = {
	-- Health
	function()
		heal(20) 
		addItemsGrabbed() 
	end,

	-- Weapon
	function()
		newWeaponGrabbed() -- not allowing choice of boomerange or wavegun, until fixed
		addItemsGrabbed()
	end,

	-- Shield
	function()
		shield(10000)
		addItemsGrabbed()
	end,

	--AbsorbAll
	function()
		absorbAllFlag = true
		addItemsGrabbed()
	end,

	--Exp1
	function() addEXP(1) end,

	--Exp2
	function() addEXP(2) end,

	--Exp3
	function() addEXP(3) end,

	--Exp6
	function() addEXP(6) end,

	--Exp9
	function() addEXP(9) end,

	--Exp16
	function() addEXP(16) end,

	--Luck
	function() incLuck() end,

	--Mun2
	function() addMun(2) end,

	--Mun10
	function() addMun(5) end,

	--Mun50
	function() addMun(20) end
}


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+


--[[
	health = 1,
	weapon = 2, 
	shield = 3, 
	absorbAll = 4,
	exp1 = 5, 
	exp2 = 6, 
	exp3 = 7, 
	exp6 = 8, 
	exp9 = 9, 
	exp16 = 10, 
	luck = 11 ,
	mun2 = 12 ,
	mun10 = 13 ,
	mun50 = 14 
]]--

local img_Health = gfx.image.new('Resources/Sprites/item/iHealth')
local img_Weapon = gfx.image.new('Resources/Sprites/item/iWeapon')
local img_Shield = gfx.image.new('Resources/Sprites/item/iShield')
local img_AbsorbAll = gfx.image.new('Resources/Sprites/item/iAbsorbAll')
local img_EXP_1 = gfx.image.new('Resources/Sprites/item/iEXP1')
local img_EXP_2 = gfx.image.new('Resources/Sprites/item/iEXP2')
local img_EXP_3 = gfx.image.new('Resources/Sprites/item/iEXP3')
local img_EXP_6 = gfx.image.new('Resources/Sprites/item/iEXP6')
local img_EXP_9 = gfx.image.new('Resources/Sprites/item/iEXP9')
local img_EXP_16 = gfx.image.new('Resources/Sprites/item/iEXP16')
local img_Luck = gfx.image.new('Resources/Sprites/item/iLuck')
local img_Mun2 = gfx.image.new('Resources/Sprites/item/iMun2')
local img_Mun10 = gfx.image.new('Resources/Sprites/item/iMun10')
local img_Mun50 = gfx.image.new('Resources/Sprites/item/iMun50')


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


local itemsImage = gfx.image.new(400, 240) -- screen size draw
local itemsSprite = gfx.sprite.new(itemsImage)
itemsSprite:setIgnoresDrawOffset(true)
itemsSprite:setZIndex(ZINDEX.item)
itemsSprite:moveTo(200, 120)


-- Global to be called after level creation, b/c level start clears the sprite list
function addItemSpriteToList()
	itemsSprite:add()
end


-- Constants for speed
local lockFocus <const> = gfx.lockFocus
local unlockFocus <const> = gfx.unlockFocus
local setColor <const> = gfx.setColor
local colorBlack <const> = gfx.kColorBlack
local colorClear <const> = gfx.kColorClear
local newVec <const> = vec.new
local abs <const> = math.abs
local drawOffset <const> = gfx.getDrawOffset

-- update function for moving items and removing from item lists
local function updateItemLists(dt)

	local deltaTime = dt
	local removeDistanceCheck = false
	local playerX = playerPos.x
	local playerY = playerPos.y
	local offsetX
	local offsetY
	offsetX, offsetY = drawOffset()

	-- No matter which item set the ABSORB_ALL flag, make sure all existing items are affected
	if absorbAllFlag == true then
		removeDistanceCheck = true
		absorbAllFlag = false
	end

	itemsImage:clear(colorClear)
	lockFocus(itemsImage)

		-- set details
		setColor(colorBlack)

		local i = 1
		local currentActiveItems = activeItems
		while i <= currentActiveItems do

			-- Absorb All
			if removeDistanceCheck == true then distanceCheck[i] = -1 end

			-- Movement
			local x = posX[i]
			local y = posY[i]
			local distanceX = abs(playerX - x)
			local distanceY = abs(playerY - y)	
			local moveTowardsPlayer = distanceCheck[i]	
			if (distanceX < moveTowardsPlayer and distanceY < moveTowardsPlayer) or moveTowardsPlayer == -1 then
				local direction = newVec(playerX - x, playerY - y):normalized()
				posX[i] += (direction.x * itemMoveSpeed * deltaTime)
				posY[i] += (direction.y * itemMoveSpeed * deltaTime)
			end		

			-- Draw - only within screen
			local drawX = abs(x + offsetX + 50)
			local drawY = abs(y + offsetY + 50)
			local type = itemType[i]
			if drawX < 500 and drawY < 290 then 
				IMAGE_LIST[type]:draw(x + offsetX, y + offsetY) 

				-- If item is close enough to player, then mark it for collision and stop moving item
				-- Only check collision if item is on-screen
				if distanceX < playerCollisionDistance and distanceY < playerCollisionDistance then lifeTime[i] = 0 end

				-- Delete
				local itemLifeTime = lifeTime[i]
				if theCurrTime >= itemLifeTime and itemLifeTime ~= -1 then -- lifeTime of -1 means it will exist until set to 0
					activateItemEffect[type]()
					deleteItem(i, currentActiveItems)
					currentActiveItems -= 1
					i -= 1
				end
			end

			-- increment
			i += 1	
		end
	unlockFocus()

	-- After all items are changed for absorb distance, reset this flag
	removeDistanceCheck = false
	activeItems = currentActiveItems
end



-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


--- DEBUG TEXT ---
local debugImage = gfx.image.new(160, 175, gfx.kColorWhite)
local debugSprite = gfx.sprite.new(debugImage)
debugSprite:setIgnoresDrawOffset(true)
debugSprite:moveTo(80, 100)
debugSprite:setZIndex(ZINDEX.uidetails)
------------------


function updateItems(dt, mainTimePassed, mainLoopTime)
	-- Get run-time variables
	theCurrTime = mainLoopTime
	playerPos = getPlayerPosition()


	playdate.resetElapsedTime()
		updateItemLists(dt)
	getUpdateTimer()

	--[[
	-- DEBUGGING
	debugImage:clear(gfx.kColorWhite)
	gfx.pushContext(debugImage)
		gfx.setColor(gfx.kColorWhite)
		gfx.drawRect(0, 0, 140, 150)
		gfx.setColor(gfx.kColorBlack)
		--gfx.drawText(" Cur C: " .. 1000*currentCreateTimer, 0, 0)
		gfx.drawText(" Update Timer: " .. 1000*currentUpdateTimer, 0, 25)
		gfx.drawText("Max Items: " .. maxItems, 0, 75)
		gfx.drawText("Active Items: " .. activeItems, 0, 100)
		gfx.drawText("FPS: " .. playdate.getFPS(), 0, 125)
		gfx.drawText("Main Time:" .. mainTimePassed, 0, 150)
	gfx.popContext()
	debugSprite:setImage(debugImage)
	debugSprite:add()
	-----
	]]--
end