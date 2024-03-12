---
-- This file handles bullets as a SOA (structure-of-arrays).
-- Each array contains one part of the following data:

-- Bullets are all drawn onto a single screen-sized image, which is passed into a single sprite.
-- The sprite ignores the draw-offset, but the draw-offset is added into the position into each bullet.
-- Bullets are identified by an index number.
-- Bullets are deleted by:
	-- The bullet info at then end of the list overwriting the to-be-deleted bullet
	-- Reducing the 'active bullets' count
-- Bullets are created at activeBullets+1. This avoids the need to search for an empty position.
---


local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local floor <const> = math.floor
local ceil <const> = math.ceil
local abs <const> = math.abs
local max <const> = math.max
local min <const> = math.min
local random <const> = math.random
local newVec <const> = vec.new
local newPolar <const> = vec.newPolar
local queryLine <const> = gfx.sprite.querySpritesAlongLine
local queryRect <const> = gfx.sprite.querySpritesInRect

-- World Reference
local worldRef
local cellSizeRef


-- +--------------------------------------------------------------+
-- |                         Bullet Data                          |
-- +--------------------------------------------------------------+

-- identical to global tags, localized for speed and readability
local LOCAL_TAGS = TAGS

-- Bullet Type Variables --
local BULLET_TYPE = {
	peagun = 1,
	cannon = 2,
	minigun = 3,
	shotgun = 4,
	burstgun = 5,
	grenade = 6,
	ranggun = 7, -- NOT DONE YET
	wavegun = 8, -- NOT DONE YET
	grenadePellet = 9
}

local BULLET_LIFETIMES = {
	2000, -- peagun
	2000, -- cannon
	2000, -- minigun
	2000, -- shotgun
	2000, -- burstgun
	1000, -- grenade
	6000, -- ranggun
	2000, -- wavegun
	2000 -- grenadePellet
}

local BULLET_SPAWN_DISTANCE = {
	25, -- peagun
	25, -- cannon
	25, -- minigun
	20, -- shotgun
	25, -- burstgun
	25, -- grenade
	25, -- ranggun
	25, -- wavegun
	25 -- grenadePellet
}


-- Index position is the gun type - this list returns the speed for each gun type.
local BULLET_SPEEDS = {
	4, -- peagun
	8, -- cannon
	2, -- minigun
	2.8, -- shotgun
	3, -- burstgun
	2, -- grenade
	4, -- ranggun
	1, -- wavegun
	2  -- grenadePellet
}

local BULLET_ATTACKRATES = {
	4, -- peagun
	5, -- cannon
	1, -- minigun
	3, -- shotgun
	5, -- burstgun
	7, -- grenade
	6, -- ranggun
	3, -- wavegun
	0  -- grenadePellet
}

local BULLET_KNOCKBACKS = {
	3, 		-- peagun
	2, 		-- cannon
	0, 		-- minigun
	0.3,	-- shotgun
	0.1, 	-- burstgun
	2, 		-- grenade
	0.5, 	-- ranggun
	0, 		-- wavegun
	0  		-- grenadePellet
}

-- NOT DONE YET
-- Number of times a bullet can pass through enemies. -1 will always pass through
local BULLET_PEIRCING = {
	0, 		-- peagun
	0, 		-- cannon
	0, 		-- minigun
	0,		-- shotgun
	1,	 	-- burstgun
	0, 		-- grenade
	-1, 	-- ranggun
	-1,		-- wavegun
	1  		-- grenadePellet
}


-- +--------------------------------------------------------------+
-- |                          Rendering                           |
-- +--------------------------------------------------------------+

-- There are 8 images in each bullet image table.
local imgTable_bulletPeagun = gfx.imagetable.new('Resources/Sheets/BulletPeagun')
local imgTable_bulletCannon = gfx.imagetable.new('Resources/Sheets/BulletCannon')
local imgTable_bulletMinigun = gfx.imagetable.new('Resources/Sheets/BulletMinigun')
local imgTable_bulletShotgun = gfx.imagetable.new('Resources/Sheets/BulletShotgun')
local imgTable_bulletBurstgun = gfx.imagetable.new('Resources/Sheets/BulletBurst')
local imgTable_bulletGrenade = gfx.imagetable.new('Resources/Sheets/BulletGrenade')
local imgTable_bulletRanggun = gfx.imagetable.new('Resources/Sheets/BulletRanggun')
--local imgTable_bulletWavegun = 
local imtTable_bulletGrenadePellet = gfx.imagetable.new('Resources/Sheets/BulletGrenadePellet')

local IMAGETABLE_LIST = {
	imgTable_bulletPeagun,
	imgTable_bulletCannon,
	imgTable_bulletMinigun,
	imgTable_bulletShotgun,
	imgTable_bulletBurstgun,
	imgTable_bulletGrenade,
	imgTable_bulletRanggun,
	imgTable_bulletPeagun, -- This shouldn't ever be referenced, but filling the table space for ease of mind
	imtTable_bulletGrenadePellet
}

-- All images in the image table should be the same size, so get the width/height of the first image in the given image table.
local IMAGE_WIDTH, IMAGE_HEIGHT = {}, {}
for i = 1, #IMAGETABLE_LIST do
	local image = IMAGETABLE_LIST[i]:getImage(1)
	IMAGE_WIDTH[i], IMAGE_HEIGHT[i] = image:getSize()
end

local DRAW_TYPE = {
	1, 		-- peagun
	2, 		-- cannon
	1, 		-- minigun
	1,		-- shotgun
	1,	 	-- burstgun
	1, 		-- grenade
	2,	 	-- ranggun
	3,		-- wavegun
	1  		-- grenadePellet
}

local DRAW_METHOD = {
	function(image, x, y) image:draw(x, y) end,
	function(image, x, y, size) image:drawScaled(x, y, size) end
	-- wavegun function
}


local bulletsImage = gfx.image.new(400, 240) -- screen size draw
local bulletsSprite = gfx.sprite.new(bulletsImage)	-- drawing image w/ sprite so we can draw via zIndex order
bulletsSprite:setIgnoresDrawOffset(true)			
bulletsSprite:setZIndex(ZINDEX.weapon)
bulletsSprite:moveTo(200, 120)


-- +--------------------------------------------------------------+
-- |                         Bullet Lists                         |
-- +--------------------------------------------------------------+

-- Bullets
--local bulletLifetime <const> = 	2000
local maxBullets <const> = 		500 -- max that can exist in the world at one time
local activeBullets = 0

-- Arrays
local bulletType = {}
local posX = {}
local posY = {}
local rotation = {}
local scale = {}
local dirX = {}
local dirY = {}
local speed = {}
local lifeTime = {}
local damage = {}
local knockback = {}
local peircing = {}
local tier = {}
local mode = {}
local misc = {}
local timer = {}
local bounce = {}
local rotatedImage = {}

-- GrenadePellet Arrays and Count
local grenadeX = {}
local grenadeY = {}
local grenadeTier = {}
local grenadeCount = 0

-- Gun Slots
local theShotTimes = {0, 0, 0, 0} --how long until next shot
local theGunSlots = {BULLET_TYPE.peagun, 0, 0, 0} --what gun in each slot
local theGunLogic = {0, 0, 0, 0} --what special logic that slotted gun needs
local theGunTier = {1, 0, 0, 0} -- what tier the gun is at


-----------
-- Debug --
local maxCreateTimer = 0
local currentCreateTimer = 0
local maxUpdateTimer = 0
local currentUpdateTimer = 0
local maxDrawTimer = 0
local currentDrawTimer = 0
local minFPS = 100
local allowBulletCollisions = true
-----------
-----------


-- +--------------------------------------------------------------+
-- |                        Timers & Misc                         |
-- +--------------------------------------------------------------+


local function getCreateTimer()
	currentCreateTimer = playdate.getElapsedTime()
	if maxCreateTimer < currentCreateTimer then 
		maxCreateTimer = currentCreateTimer
		print("BULLET - Create: " .. 1000*maxCreateTimer)
	end
end


local function getUpdateTimer()
	currentUpdateTimer = playdate.getElapsedTime()
	if maxUpdateTimer < currentUpdateTimer then
		maxUpdateTimer = currentUpdateTimer
		print("BULLET -- Update: " .. 1000*maxUpdateTimer)
	end
end


local function getDrawTimer()
	currentDrawTimer = playdate.getElapsedTime()
	if maxDrawTimer < currentDrawTimer then
		maxDrawTimer = currentDrawTimer
		print("BULLET --- Draw: " .. 1000*maxDrawTimer)
	end
end


local function getMinFPS()
	local currFPS = playdate.getFPS()
	if currFPS > 0 and currFPS < minFPS then
		minFPS = currFPS
		print("minFPS: " .. minFPS)	-- just show milliseconds
	end

	return minFPS
end


local function clamp(value, min, max)
	if value > max then
		return max
	elseif value < min then 
		return min
	else
		return value
	end
end


local function constrain(value, min, max)
	if value > max then 
		return value - max
	elseif value < min then
		return value + max
	else
		return value
	end
end


-- +--------------------------------------------------------------+
-- |                Init, Create, Delete, Handle                  |
-- +--------------------------------------------------------------+

--- Init Arrays ---
for i = 1, maxBullets do
	bulletType[i] = 0
	posX[i] = 0
	posY[i] = 0
	rotation[i] = 0
	scale[i] = 0
	dirX[i] = 0
	dirY[i] = 0
	speed[i] = 0
	lifeTime[i] = 0
	damage[i] = 0
	knockback[i] = 0
	peircing[i] = 0
	tier[i] = 0
	mode[i] = 0
	misc[i] = 0
	timer[i] = 0
	bounce[i] = 0
	rotatedImage[i] = 0

	-- GrenadePellets
	grenadeX[i] = 0
	grenadeY[i] = 0
	grenadeTier[i] = 0
end


--[[
local BULLET_DAMAGE = {
	function() return 0 end, 											-- none
	function() return 1 + getPlayerGunDamage() end, 					-- peagun
	function() return 3 + getPlayerGunDamage() * (1) end, 				-- cannon
	function() return 1 + mathCeil(getPlayerGunDamage() / 2) end, 		-- minigun
	function() return 1 + mathFloor(getPlayerGunDamage() / 2) end,		-- shotgun
	function() return 1 + getPlayerGunDamage() end,	 					-- burstgun
	function() return 2 + getPlayerGunDamage() end, 					-- grenade
	function() return 1 + mathFloor(getPlayerGunDamage() / 3) end, 		-- ranggun
	function() return 4 + getPlayerGunDamage() end,						-- wavegun
	function() return 1 + mathFloor(getPlayerGunDamage() / 2) end  		-- grenadePellet
}
]]--

-- Create a bullet at the end of the list
local function createBullet(type, spawnX, spawnY, newRotation, newTier, mainLoopTime)

	if activeBullets >= maxBullets then return end -- if too many bullets exist, then don't make another bullet


	activeBullets += 1
	addShot()
	local total = activeBullets
	local direction = newPolar(1, newRotation)

	bulletType[total] = type
	posX[total] = spawnX
	posY[total] = spawnY
	rotation[total] = floor(newRotation)
	scale[total] = 1
	dirX[total] = direction.x
	dirY[total] = direction.y 
	speed[total] = BULLET_SPEEDS[type] * getPlayerBulletSpeed()
	lifeTime[total] = mainLoopTime + BULLET_LIFETIMES[type]
	knockback[total] = BULLET_KNOCKBACKS[type]
	peircing[total] = BULLET_PEIRCING[type]
	tier[total] = newTier
	--damage[total] = BULLET_DAMAGE[type]()
	mode[total] = 0
	misc[total] = 0
	timer[total] = 0
	bounce[total] = 0


	-- Image from bullet's imageTable, drawn at correct rotation
	local rot = rotation[total] + 22
	if rot > 360 then rot -= 360 end
	local index = max(ceil(rot / 45), 1)
	rotatedImage[total] = IMAGETABLE_LIST[type]:getImage(index)


	-- Special cases for each bullet
	if type == BULLET_TYPE.cannon then
		damage[total] = 3 + getPlayerGunDamage() * (1 + newTier)
		scale[total] = newTier

	elseif type == BULLET_TYPE.minigun then
		damage[total] = 1 + ceil(getPlayerGunDamage() / 2)

	elseif type == BULLET_TYPE.shotgun then
		damage[total] = 1 + floor(getPlayerGunDamage() / 2) --round down

	elseif type == BULLET_TYPE.burstgun then
		damage[total] = 1 + getPlayerGunDamage()

	elseif type == BULLET_TYPE.grenade then
		damage[total] = 2 + getPlayerGunDamage()
		lifeTime[total] = mainLoopTime + 1000

	elseif type == BULLET_TYPE.ranggun then
		damage[total] = 1 + floor(getPlayerGunDamage() / 3)
		lifeTime[total] = mainLoopTime + 6000
		scale[total] = newTier
		bounce[total] = 4

	elseif type == BULLET_TYPE.wavegun then
		damage[total] = 4 + getPlayerGunDamage()

	elseif type == BULLET_TYPE.grenadePellet then
		damage[total] = 1 + floor(getPlayerGunDamage() / 2)

	else -- peagun
		damage[total] = 1 + getPlayerGunDamage()

	end
end
-- Constants for speed
local create <const> = createBullet


-- Deleted bullet is swapped with bullet at the ends of all lists
local function deleteBullet(index, currentActiveBullets)
	local i = index
	local total = currentActiveBullets

	-- overwrite the to-be-deleted bullet with the bullet at the end
	bulletType[i] = bulletType[total]
	posX[i] = posX[total]
	posY[i] = posY[total]
	rotation[i] = rotation[total]
	scale[i] = scale[total]
	dirX[i] = dirX[total]
	dirY[i] = dirY[total]
	speed[i] = speed[total]
	lifeTime[i] = lifeTime[total]
	damage[i] = damage[total]
	knockback[i] = knockback[total]
	tier[i] = tier[total]
	mode[i] = mode[total]
	misc[i] = misc[total]
	rotatedImage[i] = rotatedImage[total]
end


-- Grenade Pellet Only
local function createGrenadePellets(tier, gX, gY, mainLoopTime)
	local amount = 4 + (4 * tier)
	local degree = floor(360/amount)
	local newRotation = 0
	for i = 1, amount do
		newRotation += degree
		create(BULLET_TYPE.grenadePellet, gX, gY, newRotation, tier, mainLoopTime)
	end
end


-- Determine the bullet that needs to be created
local function determineBullet(iGunSlot, mainLoopTime, elapsedPauseTime, playerPos)

	-- check the bullet that needs to be created - if bullet is 0, then skip creation
	local currentBullet = theGunSlots[iGunSlot]
	if currentBullet < 1 then 
		do return end 
	end

	-- check if it's the right time to spawn this bullet
	theShotTimes[iGunSlot] += elapsedPauseTime 		-- add possible pause time
	if theShotTimes[iGunSlot] > mainLoopTime then 
		do return end 
	end 	

	-- Spawn the bullet
	--local playerPos = getPlayerPosition()
	local playerRot = getCrankAngle()
	local attackRate = getPlayerAttackRate()

	local spawnTime = mainLoopTime - elapsedPauseTime
	local slotAngle = playerRot + (90 * iGunSlot)
	local vecStartPos = newPolar(BULLET_SPAWN_DISTANCE[currentBullet], slotAngle) + playerPos
	local spawnX = vecStartPos.x
	local spawnY = vecStartPos.y
	local gunTier = theGunTier[iGunSlot]
	local gunLogic = theGunLogic[iGunSlot]
	theShotTimes[iGunSlot] = mainLoopTime + attackRate * BULLET_ATTACKRATES[currentBullet]


	-- Cannon --
	if currentBullet == BULLET_TYPE.cannon then
		create(currentBullet, spawnX, spawnY, slotAngle, gunTier, spawnTime)				

	-- Minigun --
	elseif currentBullet == BULLET_TYPE.minigun then
		local angleWiggle = random(-8, 8)
		create(currentBullet, spawnX, spawnY, slotAngle + angleWiggle, gunTier, spawnTime)
		if gunTier > 1 then
			angleWiggle = random(9, 16)
			create(currentBullet, spawnX, spawnY, slotAngle + angleWiggle, gunTier, spawnTime)
		end
		if gunTier > 2 then
			angleWiggle = random(9, 16)
			create(currentBullet, spawnX, spawnY, slotAngle - angleWiggle, gunTier, spawnTime)
		end

	-- Shotgun --
	elseif currentBullet == BULLET_TYPE.shotgun then
		create(currentBullet, spawnX, spawnY, slotAngle - 10, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 10, gunTier, spawnTime)
		--[[
		create(currentBullet, spawnX, spawnY, slotAngle - 2, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 2, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 4, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 4, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 6, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 6, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 8, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 8, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 12, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 12, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 14, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 14, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 16, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 16, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 18, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 18, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 20, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 20, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 22, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 22, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 24, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 24, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 26, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 26, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 28, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 28, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 30, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 30, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 32, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 32, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 34, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 34, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 36, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 36, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 38, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 38, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 40, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 40, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 42, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 42, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 44, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 44, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 46, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 46, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 48, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 48, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle - 50, gunTier, spawnTime)
		create(currentBullet, spawnX, spawnY, slotAngle + 50, gunTier, spawnTime)
		]]
		if theGunTier[iGunSlot] > 1 then
			create(currentBullet, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		end
		if theGunTier[iGunSlot] > 2 then
			create(currentBullet, spawnX, spawnY, slotAngle - 20, gunTier, spawnTime)
			create(currentBullet, spawnX, spawnY, slotAngle + 20, gunTier, spawnTime)
		end
	
	-- Burstgun --
	elseif currentBullet == BULLET_TYPE.burstgun then
		if gunLogic < 3 then
			theShotTimes[iGunSlot] = spawnTime + 30
			theGunLogic[iGunSlot] += 1
			create(currentBullet, spawnX, spawnY, slotAngle, gunTier, spawnTime)

			if gunTier > 1 then 
				create(currentBullet, spawnX, spawnY, slotAngle - 7, gunTier, spawnTime)
			end
			if gunTier > 2 then
				create(currentBullet, spawnX, spawnY, slotAngle + 7, gunTier, spawnTime)
			end
		else
			theGunLogic[iGunSlot] = 0
		end
	
	-- Grenade --
	elseif currentBullet == BULLET_TYPE.grenade then
		create(currentBullet, spawnX, spawnY, slotAngle, gunTier, spawnTime)

	-- Ranggun --
	elseif currentBullet == BULLET_TYPE.ranggun then
		create(currentBullet, spawnX, spawnY, slotAngle, gunTier, spawnTime)

	--[[
	-- Wavegun -- 
	elseif theGunSlots[sIndex] == BULLET_TYPE.wavegun then
		createBullet(playerPos, newRotation, (newLifeTime), theGunSlots[sIndex], sIndex, theGunTier[sIndex])
	]]--

	-- Peagun
	else
		create(currentBullet, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		if gunTier > 1 then
			local tempVec = (newPolar(1, slotAngle):leftNormal() * 10) + vecStartPos
			create(currentBullet, tempVec.x, tempVec.y, slotAngle, gunTier, spawnTime)
		end
		if gunTier > 2 then
			local tempVec = (newPolar(1, slotAngle):rightNormal() * 10) + vecStartPos
			create(currentBullet, tempVec.x, tempVec.y, slotAngle, gunTier, spawnTime)
		end
	end

end


-- Create bullets for each gun slot
local function handleCreatingBullets(playerGunStats, mainLoopTime, elapsedPauseTime, playerPos)

	local totalGunSlots = #theGunSlots
	for iGunSlot = 1, totalGunSlots do
		determineBullet(iGunSlot, playerGunStats, mainLoopTime, elapsedPauseTime, playerPos)
	end

end


-- +--------------------------------------------------------------+
-- |                           Globals                            |
-- +--------------------------------------------------------------+


function clearBullets()
	activeBullets = 0
end


function clearGunStats()
	theShotTimes = {0, 0, 0, 0}
	theGunSlots = {BULLET_TYPE.peagun, 0, 0, 0}
	theGunLogic = {0, 0, 0, 0}
	theGunTier = {1, 0, 0, 0}
end


function toggleBulletCollisions()
	allowBulletCollisions = not allowBulletCollisions
	maxUpdateTimer = 0
	print(" ---- Toggled bullet collision to: " .. tostring(allowBulletCollisions) .. " ---- reset 'Update Timer' ")
end


function getEquippedGun(index)
	return theGunSlots[index]
end


function getTierForGun(index)
	return theGunTier[index]
end


function getNumEquippedGuns()
	local totEquipped = 1
	if theGunSlots[2] > 0 then totEquipped += 1 end
	if theGunSlots[3] > 0 then totEquipped += 1 end
	if theGunSlots[4] > 0 then totEquipped += 1 end
	return totEquipped
end


function newWeaponChosen(weapon, slot, tier)
	theGunSlots[slot] = weapon
	theGunTier[slot] = tier
	updateMenuWeapon(slot, weapon)
end


-- Equip the next gun in the bullet type list. For testing.
function equipNextGun()
	local gun = theGunSlots[1]
	gun +=1
	if gun >= 7 then gun = 1 end

	theGunSlots[1] = gun
end


-- To be called after level creation, b/c level start clears the sprite list.
function addBulletSpriteToList(gameSceneWorld)
	worldRef = gameSceneWorld
	cellSizeRef = worldRef.cellSize
	bulletsSprite:add()
end


-- +--------------------------------------------------------------+
-- |                          Movement                            |
-- +--------------------------------------------------------------+

-- Constants for speed
local lockFocus <const> = gfx.lockFocus
local unlockFocus <const> = gfx.unlockFocus
local setColor <const> = gfx.setColor
local colorBlack <const> = gfx.kColorBlack
local colorClear <const> = gfx.kColorClear
local drawOffset <const> = gfx.getDrawOffset
local delete <const> = deleteBullet
local hitEnemy <const> = bulletEnemyCollision
local enemyPos <const> = getEnemyPosition

local BOUNCE_TIMER <const> = 200


local function calculateMoveChanges(i, type, playerPos, localCurrentTime)
	-- Ranggun --
	if type == BULLET_TYPE.ranggun then 
		local currentMode = mode[i]
		local life = lifeTime[i]

		-- Spin rang image
		misc[i] -= 40
		local rot = misc[i]
		if rot < 0 then 
			rot += 360 
			misc[i] = rot
		end
		local index = max(ceil(rot / 45), 1)
		rotatedImage[i] = IMAGETABLE_LIST[type]:getImage(index)

		-- Move rang in a circle
		if currentMode == 1 then 
			rotation[i] -= 15
			local newDirection = newPolar(1, rotation[i])
			dirX[i], dirY[i] = newDirection.x, newDirection.y
			if (life - 3000) < localCurrentTime then mode[i] = 2 end
			return false

		-- Return rang to player and destroy rang
		else if currentMode == 2 then 
			local vecToPlayer = newVec(playerPos.x - posX[i], playerPos.y - posY[i])
			local playerDistance = vecToPlayer:magnitudeSquared()
			if playerDistance < 300 then
				return true -- DESTROYED
			end
			local newDirection = vecToPlayer:normalized()
			dirX[i], dirY[i] = newDirection.x, newDirection.y
			return false

		-- Move rang in original direction
		else 
			if (life - 5000) < localCurrentTime then mode[i] = 1
			return false
		end
	end

	return false
end

	--[[
	-- Wavegun --
	elseif self.type == BULLET_TYPE.wavegun then
		if self.lifeTime - 1300 + (200 * self.mode) < theCurrTime then 
			self.mode += 1
			if self.damage > 1 then self.damage = math.ceil(self.damage/2) end
			self:setScale(1 + self.mode/2 * self.tier, 1)
			self:setCollideRect(0, 0, self:getSize())
		end
	]]--
	end
end


--[[
function bullet:collisionResponse(other)
	self.lifeTime = 0
	return 'overlap'
	
	local tag = other:getTag()
	if tag == TAGS.player then
		return 'overlap'
	--elseif tag == TAGS.weapon then
	--	return 'overlap'
	elseif tag == TAGS.item then
		return 'overlap'
	elseif tag == TAGS.itemAbsorber then
		return 'overlap'
	elseif tag == TAGS.enemy then
		if self.type == BULLET_TYPE.ranggun then
			if self.timer < theCurrTime then
				other:damage(self.damage)
				other:potentialStun()
				self.timer = theCurrTime + 50
			end
			return 'overlap'
		elseif self.type == BULLET_TYPE.wavegun then
			if self.timer < theCurrTime then
				other:damage(self.damage)
				other:potentialStun()
				self.timer = theCurrTime + 50
			end
			return 'overlap'
		else
			self.lifeTime = 0 
			other:damage(self.damage)
			other:potentialStun()
			other:applyKnockback(self.x, self.y, self.knockback)
			return 'overlap'
		end
	else --tag == walls
		self.lifeTime = 0
		return 'overlap'
	end
	
end

]]--



local function getCollisionCheckFromCells(world, x1, y1, x2, y2) --, offsetX, offsetY)

	local cellSize = cellSizeRef
	local xMin, xMax = floor(x1 / cellSize) + 1, floor(x2 / cellSize) + 1
	local yMin, yMax = floor(y1 / cellSize) + 1, floor(y2 / cellSize) + 1
	local totalItems = 0

	-- DEBUGGING
	--print("xMin: " .. xMin .. ", yMin: " .. yMin .. "  -  xMax: " .. xMax .. ", yMax: " .. yMax)
	--local width, height = x2 - x1, y2 - y1	
	--gfx.drawRect(x1 + offsetX, y1 + offsetY, width, height)

	-- If starting position is outside cell bounds, ignore collision.
	if xMin < 1 or yMin < 1 then 
		return -1
	end

	-- Loop through all the cells of this 'rect' of movement and count the first non-player item
	for i = yMin, yMax do
		local row = world.rows[i]
		if row then
			for j = xMin, xMax do
				local cell = row[j]
				if cell then

					-- If this is NOT the player, then allow collisions
					for item,_ in pairs(cell.items) do
						if item.tag ~= LOCAL_TAGS.player then 
							return 1 
						end
			        end
				end
			end
		end
	end

	return 0
end


-- enclosed in local function to allow return out at any point while staying inside while loop
local function collideMove(dt, i, type, offsetX, offsetY, playerPos, localCurrentTime)

	local worldStartX = posX[i]
	local worldStartY = posY[i]
	local startOffsetX = worldStartX + offsetX
	local startOffsetY = worldStartY + offsetY	

	-- out of camera bounds - checking before movement/collision bc bullet could be deleted from camera movement
	if startOffsetX < -50 or 450 < startOffsetX or startOffsetY < -50 or 290 < startOffsetY then 
		lifeTime[i] = 0
		return worldStartX, worldStartY
	end

	-- do special direction calcs for certain bullets - if TRUE then this destroyed the bullet
	if calculateMoveChanges(i, type, playerPos, localCurrentTime) == true then 
		lifeTime[i] = 0
		return worldStartX, worldStartY
	end

	-- movement calcs for every bullet
	local bulletSpeed = speed[i]
	posX[i] += (dirX[i] * bulletSpeed * dt)
	posY[i] += (dirY[i] * bulletSpeed * dt)
	local endX, endY = posX[i], posY[i]
	local size = scale[i]
	local width, height = IMAGE_WIDTH[type], IMAGE_HEIGHT[type]		
	local halfWidth = width * size * 0.5
	local halfHeight = height * size * 0.5

	
	-- If this world cell has NO colliders in it, then only move bullet
	local x1, x2 = worldStartX - halfWidth, endX + halfWidth
	local y1, y2 = worldStartY - halfHeight, endY + halfHeight
	local cellCount = getCollisionCheckFromCells(worldRef, x1, y1, x2, y2) --, offsetX, offsetY)

	-- out of bounds - delete
	if cellCount < 0 then 
		lifeTime[i] = 0
		return endX, endY
	end

	-- no collision
	if cellCount < 1 then 
		return endX, endY, halfWidth, halfHeight, size
	end
	
	-- collision checking:
	local queryX, queryY = min(x1, x2), min(y1, y2)
	local queryWidth, queryHeight = abs(x2 - x1), abs(y2 - y1)
	local rect = worldRef:queryRectFast(queryX, queryY, queryWidth, queryHeight)
	if rect then 		
		if rect.tag == LOCAL_TAGS.enemy then

			-- don't allow damage if timer exists
			--if timer[i] > localCurrentTime then 
			--	return endX, endY, halfWidth, halfHeight, size
			--end
	
			-- damage enemy
			local enemyIndex = rect.index
			hitEnemy(enemyIndex, damage[i], knockback[i], playerPos, localCurrentTime)

			--[[
			-- if allowed to bounce off an enemy, use up a bounce
			if bounce[i] > 0 then 
				bounce[i] -= 1
				timer[i] = localCurrentTime + BOUNCE_TIMER
				lifeTime[i] = localCurrentTime + BULLET_LIFETIMES[type]
				mode[i] = 0
				local enemyX, enemyY = enemyPos(enemyIndex)
				local newDirection = newVec(worldStartX - enemyX, worldStartY - enemyY):normalized()
				dirX[i], dirY[i] = newDirection.x, newDirection.y
				posX[i] = enemyX + (dirX[i] * width * 2)
				posY[i] = enemyY + (dirY[i] * height * 2)

				return endX, endY, halfWidth, halfHeight, size
			end
			]]
		end 

		lifeTime[i] = 0
		return endX, endY, halfWidth, halfHeight, size
	end
	

	-- move
	return endX, endY, halfWidth, halfHeight, size
end


-- Move, Collide, Draw and Delete all bullets
local function updateBulletLists(dt, mainLoopTime, elapsedPauseTime, playerPos)
	local localCurrentTime = mainLoopTime
	local offsetX, offsetY = drawOffset()


	bulletsImage:clear(colorClear)	
	lockFocus(bulletsImage)

		-- set details
		setColor(colorBlack)

		-- LOOP
		local i = 1
		local currentActiveBullets = activeBullets
		while i <= currentActiveBullets do	

			-- adjust pause time
			lifeTime[i] += elapsedPauseTime

			-- move and collide
			local type = bulletType[i]
			local x, y, halfWidth, halfHeight, size = collideMove(dt, i, type, offsetX, offsetY, playerPos, localCurrentTime)
			x, y = x + offsetX, y + offsetY
			
			-- delete
			if localCurrentTime > lifeTime[i] then			
				-- spawn grenade pellets
				delete(i, currentActiveBullets)
				currentActiveBullets -= 1
				if type == BULLET_TYPE.grenade then
					if halfWidth ~= nil then
						x -= offsetX
						y -= offsetY
					end
					grenadeCount += 1
					grenadeX[grenadeCount] = x
					grenadeY[grenadeCount] = y
					grenadeTier[grenadeCount] = tier[i]
				end

				delete(i, currentActiveBullets)
				currentActiveBullets -= 1
				i -= 1	

			
			-- draw, if not deleted
			else 
				x -= halfWidth
				y -= halfHeight
				DRAW_METHOD[ DRAW_TYPE[type] ](rotatedImage[i], x, y, size)
			end

			-- increment
			i += 1		
		end
	
	unlockFocus()
	activeBullets = currentActiveBullets

	-- Create new grenade pellets
	if grenadeCount < 1 then return end
	for i = 1, grenadeCount do
		createGrenadePellets(grenadeTier[i], grenadeX[i], grenadeY[i], mainLoopTime)
	end
	grenadeCount = 0
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


function updateBullets(dt, mainTimePassed, mainLoopTime, elapsedPauseTime)

	local playerPosRef = getPlayerPosition()

	-- Bullet Handling
	playdate.resetElapsedTime()
		handleCreatingBullets(mainLoopTime, elapsedPauseTime, playerPosRef)
	getCreateTimer()
	
	playdate.resetElapsedTime()	
		updateBulletLists(dt, mainLoopTime, elapsedPauseTime, playerPosRef)
	getUpdateTimer()

	--[[
	-- DEBUGGING
	debugImage:clear(gfx.kColorWhite)
	gfx.pushContext(debugImage)
		gfx.setColor(gfx.kColorWhite)
		gfx.drawRect(0, 0, 140, 150)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawText(" Cur C: " .. 1000*currentCreateTimer, 0, 0)
		gfx.drawText(" Update Timer: " .. 1000*currentUpdateTimer, 0, 25)
		gfx.drawText("Max Bullets: " .. maxBullets, 0, 75)
		gfx.drawText("Active Bullets: " .. activeBullets, 0, 100)
		gfx.drawText("FPS: " .. playdate.getFPS(), 0, 125)
		gfx.drawText("Main Time:" .. mainTimePassed, 0, 150)
	gfx.popContext()
	debugSprite:setImage(debugImage)
	debugSprite:add()
	-----
	]]
end