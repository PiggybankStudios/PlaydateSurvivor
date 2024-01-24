local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local theCurrTime = 0
local playerPos = vec.new(0, 0)


-- Item Type Variables --
local itemMoveSpeed <const> = 120
local defaultDistanceCheck = getPlayerMagnetStat()
local playerCollisionDistance <const> = 10	-- distance from player that is close enough to mimic a collision

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
local lifeTime = {}


-- +--------------------------------------------------------------+
-- |                Init, Create, Delete, Handle                  |
-- +--------------------------------------------------------------+


--- Init Arrays ---
for i = 1, maxItems do
	itemType[i] = ITEM_TYPE.none
	posX[i] = 0
	posY[i] = 0
	rotation[i] = 0
	distanceCheck[i] = 0
	lifeTime[i] = 0
end


-- LOCAL create
local function createItem(type, spawnX, spawnY)
	if activeItems >= maxItems then do return end end -- if too many items exist, then don't make another item
	if type == ITEM_TYPE.none then do return end end	

	-- optional parameters
	activeItems += 1

	itemType[activeItems] = type
	posX[activeItems] = spawnX
	posY[activeItems] = spawnY
	rotation[activeItems] = newRotation
	distanceCheck[activeItems] = defaultDistanceCheck
	lifeTime[activeItems] = -1
end


local function deleteItem(index)
	-- overwrite the to-be-deleted item with the item at the end
	itemType[index] = itemType[activeItems]
	posX[index] = posX[activeItems]
	posY[index] = posY[activeItems]
	rotation[index] = rotation[activeItems]
	distanceCheck[index] = distanceCheck[activeItems]
	lifeTime[index] = lifeTime[activeItems]

	-- set the last item to NONE and reduce active items (effectively deletes the item)
	itemType[activeItems] = ITEM_TYPE.none
	activeItems -= 1
end


-- GLOBAL create
function spawnItem(type, spawnX, spawnY)
	createItem(type, spawnX, spawnY)
end


-- +--------------------------------------------------------------+
-- |                       Item Management                        |
-- +--------------------------------------------------------------+


function debugAbsorbAll()
	absorbAllFlag = true
end


--GLOBAL adjust distance check
function setDistanceCheckToPlayerMagnetStat(value)
	defaultDistanceCheck = value
end


-- Effects
local function activateItemEffect(index)
	local type = itemType[index]

	if type == ITEM_TYPE.health then
		heal(3)
		addItemsGrabbed()

	elseif type == ITEM_TYPE.weapon then
		newWeaponGrabbed(math.random(2, 9), decideWeaponTier())
		addItemsGrabbed()

	elseif type == ITEM_TYPE.shield then
		shield(10000)
		addItemsGrabbed()

	elseif type == ITEM_TYPE.absorbAll then 
		absorbAllFlag = true
		print("absorb all collected")
		addItemsGrabbed()

	elseif type == ITEM_TYPE.luck then
		incLuck()

	elseif type == ITEM_TYPE.exp1 then
		addEXP(1)

	elseif type == ITEM_TYPE.exp2 then
		addEXP(2)

	elseif type == ITEM_TYPE.exp3 then
		addEXP(3)

	elseif type == ITEM_TYPE.exp6 then
		addEXP(6)

	elseif type == ITEM_TYPE.exp9 then
		addEXP(9)

	elseif type == ITEM_TYPE.exp16 then
		addEXP(16)

	else
		addEXP(1)	-- default is exp1

	end
end


--[[
-- Scale
local function adjustParticle(i, dt)
	local type = particleType[i]

	-- decrease size	
	local scalar = (lifeTime[i] - theCurrTime) / PARTICLE_LIFETIMES[type]
	scale[i] *= scalar
	if scale[i] <= minParticleScale then 
		lifeTime[i] = 0
	end
end
]]--


-- Movement
local function moveItem(i, dt)
	local vecToPlayer = vec.new(playerPos.x - posX[i], playerPos.y - posY[i])
	local playerDistance = vecToPlayer:magnitude()

	-- If item is close enough to player, then mark it for collision and stop moving item
	if playerDistance < playerCollisionDistance then
		lifeTime[i] = 0
		do return end
	end

	-- If item is within range of player OR is set to move towards player (-1), then move towards player
	if playerDistance < distanceCheck[i] or distanceCheck[i] == -1 then
		local direction = vecToPlayer:normalized()
		posX[i] += (direction.x * itemMoveSpeed * dt)
		posY[i] += (direction.y * itemMoveSpeed * dt)
	end
end


-- update function for moving items and removing from item lists
local function updateItemLists(dt)

	-- No matter which item set the ABSORB_ALL flag, make sure all existing items are affected
	if absorbAllFlag == true then
		removeDistanceCheck = true
		absorbAllFlag = false
	end

	for i = 1, activeItems do
		-- Absorb All
		if removeDistanceCheck == true then 
			distanceCheck[i] = -1 
			print("distanceCheck set to -1 for item: " .. i)
		end

		-- Movement
		--adjustItems(i, dt)
		moveItem(i, dt)		

		-- Delete
		if theCurrTime >= lifeTime[i] and lifeTime[i] ~= -1 then -- lifeTime of -1 means it will exist until set to 0
			activateItemEffect(i)
			deleteItem(i)
			i -= 1
		end
	end

	-- After all items are changed for absorb distance, reset this flag
	removeDistanceCheck = false
end


function clearItems()
	for i = 1, maxItems do
		itemType[i] = ITEM_TYPE.none
		lifeTime[i] = 0
	end

	activeItems = 0
end


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+


local img_AbsorbAll = gfx.image.new('Resources/Sprites/Items/iAbsorbAll')
local img_EXP_1 = gfx.image.new('Resources/Sprites/Items/iEXP1')
local img_EXP_2 = gfx.image.new('Resources/Sprites/Items/iEXP2')
local img_EXP_3 = gfx.image.new('Resources/Sprites/Items/iEXP3')
local img_EXP_6 = gfx.image.new('Resources/Sprites/Items/iEXP6')
local img_EXP_9 = gfx.image.new('Resources/Sprites/Items/iEXP9')
local img_EXP_16 = gfx.image.new('Resources/Sprites/Items/iEXP16')
local img_Health = gfx.image.new('Resources/Sprites/Items/iHealth')
local img_Luck = gfx.image.new('Resources/Sprites/Items/iLuck')
local img_Shield = gfx.image.new('Resources/Sprites/Items/iShield')
local img_Weapon = gfx.image.new('Resources/Sprites/Items/iWeapon')

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
}


local itemsImage = gfx.image.new(400, 240) -- screen size draw
local itemsSprite = gfx.sprite.new(itemsImage)
itemsSprite:setIgnoresDrawOffset(true)
itemsSprite:setZIndex(ZINDEX.item)
itemsSprite:moveTo(200, 120)


-- Draws a specific single item
local function drawSingleItem(index, offsetX, offsetY)

	local type = itemType[index]
	if type == ITEM_TYPE.none then -- if the item doesn't exist, don't draw it
		do return end
	end

	local imageID = type - 1 -- subtract 1 b/c NONE is 1, need to offset item type list to match image list
	local x = posX[index] + offsetX
	local y = posY[index] + offsetY
	local outsideScreen = false

	-- if item is too far outside the screen, don't draw it, but DON'T delete it
	if x < -50 or x > 450 then outsideScreen = true end
	if y < -50 or y > 290 then outsideScreen = true end
	if outsideScreen == true then
		do return end
	end

	--IMAGE_LIST[imageID]:drawRotated(x, y, angle, size)
	IMAGE_LIST[imageID]:draw(x, y)
end


-- Draws all items to a screen-sized sprite in one push context
local function drawItems()	

	itemsImage:clear(gfx.kColorClear)
	local offX, offY = gfx.getDrawOffset()

	-- if no items, clear the sprite and don't try to draw anything
	if activeItems == 0 then do return end end

	-- Create the new items image
		gfx.pushContext(itemsImage)
			-- set details
			gfx.setColor(gfx.kColorBlack)

			-- loop through and draw each item
			for i = 1, activeItems do
				drawSingleItem(i, offX, offY)
			end
		gfx.popContext()

	-- Draw the new item sprite
	itemsSprite:setImage(itemsImage)
end


-- Global to be called after level creation, b/c level start clears the sprite list
function addItemSpriteToList()
	itemsSprite:add()
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


function updateItems(dt)
	-- Get run-time variables
	theCurrTime = playdate.getCurrentTimeMilliseconds()
	playerPos = getPlayerPosition()

	-- Particle Handling
	updateItemLists(dt)
	drawItems()

end