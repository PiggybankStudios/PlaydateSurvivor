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

local pd 		<const> = playdate
local gfx 		<const> = pd.graphics

local NEXT 		<const> = next
local ceil 		<const> = math.ceil
local abs 		<const> = math.abs
local max 		<const> = math.max
local min 		<const> = math.min
local sin 		<const> = math.sin 
local cos 		<const> = math.cos
local sqrt		<const> = math.sqrt
local random 	<const> = math.random

local GET_IMAGE	<const> = gfx.imagetable.getImage
local GET_SIZE 	<const> = gfx.image.getSize

-- Globals
local dt 		<const> = getDT()
local M_PI_180 	<const> = 0.017453

-- World Reference
local worldRef
local cellSizeRef

-- Player Variables
local playerBulletSpeed = getPlayerBulletSpeed()
local playerAttackRate = getPlayerAttackRate()
local playerGunDamage = getPlayerGunDamage()

local newShotsFired = 0

-- +--------------------------------------------------------------+
-- |                         Bullet Data                          |
-- +--------------------------------------------------------------+

-- Timers
-- The timer that's passed on each tick increases at an inconsistent rate. Sometimes the new time that's passed
-- is about +35, or +28, or +18. This is on simulator too. For the moveCalcTimer to have proper groups with a 
-- decent framerate, The TIME_SET_SIZE needs to be ~mostly~ above this inconsistent rate. 
-- This will still have some update groups that have more than the GROUP_SIZE, and some with less, but it's 
-- accurate enough and decreases how much the playdate needs to calculate.
local TIME_SET_SIZE 			<const> = 30 
local GROUP_SIZE 				<const> = 5
local GROUP_TIME_SET			<const> = GROUP_SIZE * TIME_SET_SIZE

local BULLET_MOVE_CALC_TIMER_START = {
	0, 		-- peagun
	0, 		-- cannon
	0, 		-- minigun
	0,		-- shotgun
	0,	 	-- burstgun
	0, 		-- grenade
	GROUP_TIME_SET, 	-- ranggun
	GROUP_TIME_SET,		-- wavegun
	0  		-- grenadePellet
}

-- identical to global tags, localized for speed and readability
local LOCAL_TAGS = TAGS

--local PLAYER_TAG 	<const> = LOCAL_TAGS.player
local ENEMY_TAG 	<const> = LOCAL_TAGS.enemy

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

local RANGGUN_TYPE	<const> = BULLET_TYPE.ranggun
local WAVEGUN_TYPE	<const> = BULLET_TYPE.wavegun
local GRENADE_TYPE 	<const> = BULLET_TYPE.grenade

local BOUNCE_TIMER 	<const> = 200

local BULLET_LIFETIMES = {
	20000, -- peagun
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

local BULLET_DAMAGE = {
	function() 		return playerGunDamage + 1 				end, 	-- peagun
	function(tier) 	return playerGunDamage * (1 + tier) + 3 end, 	-- cannon
	function() 		return playerGunDamage // 2 + 2 		end, 	-- minigun
	function() 		return playerGunDamage // 2 + 1 		end,	-- shotgun
	function() 		return playerGunDamage + 1 				end,	-- burstgun
	function() 		return playerGunDamage + 2 				end, 	-- grenade
	function() 		return playerGunDamage // 3 + 1 		end, 	-- ranggun
	function() 		return playerGunDamage + 4 				end,	-- wavegun
	function() 		return playerGunDamage // 2 + 1 		end  	-- grenadePellet
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

-- min = 1.0 - slightly pauses enemy speed of 1
local BULLET_KNOCKBACKS = {
	0.1, --1, 		-- peagun
	2, 		-- cannon
	0, 		-- minigun
	1,		-- shotgun
	0.8, 	-- burstgun
	2, 		-- grenade
	0.1, --0.5, 	-- ranggun
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

-- TO DO: try to automate largest size
-- Biggest bullet size from all image tables.
	-- Only need 1 number since they're all squares.
	-- Update this number is a bigger bullet is made.
	-- CURRENT BIGGEST = Ranggun, Large Size = 27
local BIGGEST_BULLET_SIZE <const> = 27

-- Screen size constants for destroying bullets
local SCREEN_MIN_X 	<const> = -BIGGEST_BULLET_SIZE
local SCREEN_MAX_X 	<const> = 400 + BIGGEST_BULLET_SIZE
local SCREEN_MIN_Y 	<const> = (getBannerHeight() * 0.5) - BIGGEST_BULLET_SIZE
local SCREEN_MAX_Y 	<const> = 240 + BIGGEST_BULLET_SIZE

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

-- Default Bullet Image Tables
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

-- Cannon tier 2 and 3 sizes
local imgTable_bulletCannon_s2 = gfx.imagetable.new('Resources/Sheets/BulletCannonMedium')
local imgTable_bulletCannon_s3 = gfx.imagetable.new('Resources/Sheets/BulletCannonLarge')
local CANNON_TABLES_LIST = {
	imgTable_bulletCannon_s2,
	imgTable_bulletCannon_s3
}

-- Ranggun tier 2 and 3 sizes
local imgTable_bulletRangGun_s2 = gfx.imagetable.new('Resources/Sheets/BulletRanggunMedium')
local imgTable_bulletRangGun_s3 = gfx.imagetable.new('Resources/Sheets/BulletRanggunLarge')
local RANGGUN_TABLES_LIST = {
	imgTable_bulletRanggun,
	imgTable_bulletRangGun_s2,
	imgTable_bulletRangGun_s3
}

---------------------


--- Bullet Image Sizes ---

-- All images in the image table should be the same size, so get the width/height of the first image in the given image table.
	-- Only get width; height will be the same.
	-- Only need the halfsizes.
local DEFAULT_IMAGE_HALFSIZE = {}
for i = 1, #IMAGETABLE_LIST do
	local image = GET_IMAGE(IMAGETABLE_LIST[i], 1)
	local fullWidth = GET_SIZE(image)
	DEFAULT_IMAGE_HALFSIZE[i] = fullWidth * 0.5
end

-- Cannon
local CANNON_IMAGE_HALFSIZE = {}
for i = 1, #CANNON_TABLES_LIST do
	local image = GET_IMAGE(CANNON_TABLES_LIST[i], 1)
	local fullWidth = GET_SIZE(image)
	CANNON_IMAGE_HALFSIZE[i] = ceil(fullWidth * 0.5)
end

-- Ranggun
local RANGGUN_IMAGE_HALFSIZE = {}
for i = 1, #RANGGUN_TABLES_LIST do
	local image = GET_IMAGE(RANGGUN_TABLES_LIST[i], 1)
	local fullWidth = GET_SIZE(image)
	RANGGUN_IMAGE_HALFSIZE[i] = ceil(fullWidth * 0.5)
end

-- +--------------------------------------------------------------+
-- |                         Bullet Lists                         |
-- +--------------------------------------------------------------+

-- Bullets
local maxBullets <const> = 100 -- max that can exist in the world at one time
local activeBullets = 0

-- Arrays
local bulletType = {}
local posX = {}
local posY = {}
local rotation = {}
local velX = {}
local velY = {}
local speed = {}
local lifeTime = {}
local damage = {}
local knockback = {}
local peircing = {}
local tier = {}
local mode = {}
local misc = {}
local timer = {}
local moveCalcTimer = {}
local bounce = {}
local rotatedImage = {}
local imageHalfSize = {}

-- GrenadePellet Arrays and Count
local grenadeX = {}
local grenadeY = {}
local grenadeTier = {}
local grenadeCount = 0

-- Gun Slots
local theShotTimes = {0, 0, 0, 0} --how long until next shot
local theGunSlots = {BULLET_TYPE.peagun, 0, 0, 0} --what gun in each slot
local theGunLogic = {0, 0, 0, 0} --what special logic that slotted gun needs
local theGunTier = {3, 2, 2, 2} -- what tier the gun is at



-- +--------------------------------------------------------------+
-- |                Init, Create, Delete, Handle                  |
-- +--------------------------------------------------------------+

function initialize_bullets()

	--- Init Arrays ---
	for i = 1, maxBullets do
		bulletType[i] = 0
		posX[i] = 0
		posY[i] = 0
		rotation[i] = 0
		velX[i] = 0
		velY[i] = 0
		speed[i] = 0
		lifeTime[i] = 0
		damage[i] = 0
		knockback[i] = 0
		peircing[i] = 0
		tier[i] = 0
		mode[i] = 0
		misc[i] = 0
		timer[i] = 0
		moveCalcTimer[i] = 0
		bounce[i] = 0
		rotatedImage[i] = 0
		imageHalfSize[i] = 0

		-- GrenadePellets
		grenadeX[i] = 0
		grenadeY[i] = 0
		grenadeTier[i] = 0
	end
	-- yield(currentTaskCompleted, totalNumberOfTasks, loadDescription)
	coroutine.yield()

end


-- Create a bullet at the end of the list
local function createBullet(type, spawnX, spawnY, newRotation, newTier, time)

	local total = activeBullets + 1
	if total > maxBullets then return end -- if too many bullets exist, then don't make another bullet
	activeBullets = total

	newShotsFired = newShotsFired + 1

	

	bulletType[total] = type

	local radian = (newRotation - 90) * M_PI_180
	local dirX, dirY = cos(radian), sin(radian)

	local spawnDist = BULLET_SPAWN_DISTANCE[type]
	posX[total] = dirX * spawnDist + spawnX
	posY[total] = dirY * spawnDist + spawnY
	rotation[total] = newRotation

	local bSpeed = BULLET_SPEEDS[type] * playerBulletSpeed * dt
	velX[total] = dirX * bSpeed
	velY[total] = dirY * bSpeed

	lifeTime[total] = time + BULLET_LIFETIMES[type]
	knockback[total] = BULLET_KNOCKBACKS[type]
	--peircing[total] = BULLET_PEIRCING[type]
	tier[total] = newTier
	damage[total] = BULLET_DAMAGE[type](newTier)

	mode[total] = 0
	misc[total] = 0
	timer[total] = 0
	moveCalcTimer[total] = BULLET_MOVE_CALC_TIMER_START[type]
	--bounce[total] = 0


	-- Image from bullet's imageTable, drawn at correct rotation
	local rot = rotation[total] + 22
	if rot > 360 then rot -= 360 end
	local index = max(ceil(rot / 45), 1)

	-- Different Sizes - cannon or ranggun
	if newTier > 1 then 
		local sizeIndex = newTier - 1

		if type == BULLET_TYPE.cannon then
			rotatedImage[total] = GET_IMAGE(CANNON_TABLES_LIST[sizeIndex], index)
			imageHalfSize[total] = CANNON_IMAGE_HALFSIZE[sizeIndex]
			return

		elseif type == BULLET_TYPE.ranggun then 
			rotatedImage[total] = GET_IMAGE(RANGGUN_TABLES_LIST[sizeIndex], 1)
			imageHalfSize[total] = RANGGUN_IMAGE_HALFSIZE[sizeIndex]
			return
		end
	end

	rotatedImage[total] = GET_IMAGE(IMAGETABLE_LIST[type], index)
	imageHalfSize[total] = DEFAULT_IMAGE_HALFSIZE[type]
end



-- Deleted bullet is replaced with data of bullet at the ends of all lists
local function deleteBullet(i, total)
	bulletType[i] = bulletType[total]
	posX[i] = posX[total]
	posY[i] = posY[total]
	rotation[i] = rotation[total]
	velX[i] = velX[total]
	velY[i] = velY[total]
	lifeTime[i] = lifeTime[total]
	damage[i] = damage[total]
	knockback[i] = knockback[total]
	tier[i] = tier[total]
	mode[i] = mode[total]
	misc[i] = misc[total]
	timer[i] = timer[total]
	moveCalcTimer[i] = moveCalcTimer[total]
	rotatedImage[i] = rotatedImage[total]
	imageHalfSize[i] = imageHalfSize[total]
end


-- Grenade Pellet Only
local function createGrenadePellets(tier, gX, gY, mainLoopTime)
	local amount = 4 * tier + 4
	local degree = 360 // amount
	local newRotation = 0
	for i = 1, amount do
		newRotation = newRotation + degree
		createBullet(BULLET_TYPE.grenadePellet, gX, gY, newRotation, tier, mainLoopTime)
	end
end


local BULLET_CREATE = {
	-- peagun
	function(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		createBullet(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)

		if gunTier > 1 then
			local radian = (slotAngle - 90) * M_PI_180
			local offsetX, offsetY = sin(-radian) * 10, cos(radian) * 10
			createBullet(type, spawnX + offsetX, spawnY + offsetY, slotAngle, gunTier, spawnTime)

			if gunTier > 2 then
				createBullet(type, spawnX - offsetX, spawnY - offsetY, slotAngle, gunTier, spawnTime)
			end 
		end
	end,

	-- cannon
	function(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		createBullet(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)	
	end,				

	-- minigun
	function(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		local angleWiggle = random(-8, 8)
		createBullet(type, spawnX, spawnY, slotAngle + angleWiggle, gunTier, spawnTime)
		if gunTier > 1 then
			angleWiggle = random(9, 16)
			createBullet(type, spawnX, spawnY, slotAngle + angleWiggle, gunTier, spawnTime)
		end
		if gunTier > 2 then
			angleWiggle = random(9, 16)
			createBullet(type, spawnX, spawnY, slotAngle - angleWiggle, gunTier, spawnTime)
		end
	end,

	-- shotgun
	function(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		createBullet(type, spawnX, spawnY, slotAngle - 10, gunTier, spawnTime)
		createBullet(type, spawnX, spawnY, slotAngle + 10, gunTier, spawnTime)
		
		if gunTier > 1 then
			createBullet(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		end
		if gunTier > 2 then
			createBullet(type, spawnX, spawnY, slotAngle - 20, gunTier, spawnTime)
			createBullet(type, spawnX, spawnY, slotAngle + 20, gunTier, spawnTime)
		end
	end,

	-- burstgun
	function(type, spawnX, spawnY, slotAngle, gunTier, spawnTime, gunLogic, i)
		if gunLogic < 3 then
			theShotTimes[i] = spawnTime + 30
			theGunLogic[i] += 1
			createBullet(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)

			if gunTier > 1 then 
				createBullet(type, spawnX, spawnY, slotAngle - 7, gunTier, spawnTime)
			end
			if gunTier > 2 then
				createBullet(type, spawnX, spawnY, slotAngle + 7, gunTier, spawnTime)
			end
		else
			theGunLogic[i] = 0
		end
	end,

	-- grenade
	function(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		createBullet(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)	
	end,

	-- ranggun
	function(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		createBullet(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)	
	end,

	-- wavegun
	function(type, spawnX, spawnY, slotAngle, gunTier, spawnTime)
		-- TO DO
	end
}


-- Create bullets for each gun slot
local function handleCreatingBullets(time, playerX, playerY, crank)
	for iGunSlot = 1, 4 do
		-- check the bullet that needs to be created - if bullet is 0, then skip creation
		local type = theGunSlots[iGunSlot]
		if type > 0 and theShotTimes[iGunSlot] < time then 
			
			-- setup bullet data
			local spawnTime = time -- - elapsedPauseTime
			local slotAngle = (iGunSlot - 1) * 90 + crank
			local gunTier = theGunTier[iGunSlot]
			local gunLogic = theGunLogic[iGunSlot]
			theShotTimes[iGunSlot] = time + playerAttackRate * BULLET_ATTACKRATES[type]

			-- spawn the bullet
			BULLET_CREATE[type](type, playerX, playerY, slotAngle, gunTier, spawnTime, gunLogic, iGunSlot)
		end
	end
end


-- +--------------------------------------------------------------+
-- |                           Globals                            |
-- +--------------------------------------------------------------+


function setPlayerBulletSpeedInBullets(value)
	playerBulletSpeed = value
end

function setPlayerAttackRateInBullets(value)
	playerAttackRate = value
end

function setPlayerGunDamageInBullets(value)
	playerGunDamage = value
end


function clearBullets()
	activeBullets = 0
end


function clearGunStats()
	theShotTimes = {0, 0, 0, 0}
	theGunSlots = {BULLET_TYPE.peagun, 0, 0, 0}
	theGunLogic = {0, 0, 0, 0}
	theGunTier = {1, 0, 0, 0}
end

function getEquippedGunData()
	return 	theGunSlots[1], theGunSlots[2], theGunSlots[3], theGunSlots[4],
	 		theGunTier[1], theGunTier[2], theGunTier[3], theGunTier[4]
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
function sendWorldCollidersToBullets(gameSceneWorld)
	worldRef = gameSceneWorld
	cellSizeRef = worldRef.cellSize
end


-- To be called at the end of the pause animation.
function getPauseTime_Bullets(pauseTime)
	
	-- shot timers for all gun slots
	for i = 1, 4 do
		theShotTimes[i] = theShotTimes[i] + pauseTime
	end

	-- timers for all bullets
	for j = 1, activeBullets do
		lifeTime[j] 		= lifeTime[j] + pauseTime
		timer[j] 			= timer[j] + pauseTime
		moveCalcTimer[j] 	= moveCalcTimer[j] + pauseTime
	end
end


-- +--------------------------------------------------------------+
-- |                          Movement                            |
-- +--------------------------------------------------------------+


local function countCollidersInOccupiedCells(world, x1, y1, x2, y2)
	local cellSize = cellSizeRef
	local xMin, xMax = x1 // cellSize + 1, x2 // cellSize + 1
	local yMin, yMax = y1 // cellSize + 1, y2 // cellSize + 1

				-- DEBUG CODE - this shows the rect that each bullet checks for a collision
				--local width, height = x2 - x1, y2 - y1
				--gfx.drawRect(x1, y1, width, height)

	-- If starting position is outside cell bounds, ignore collision.
	if xMin < 1 or yMin < 1 then 
		return -1
	end

	-- Loop through all the cells of this 'rect' of movement and count the first non-player item
	for i = yMin, yMax do
		for j = xMin, xMax do
			local cell = world.rows[i][j] -- [y][x]
			if cell then
				-- If this is NOT the player, then allow collisions
				for item,_ in NEXT, cell.items do
					--if item.tag ~= PLAYER_TAG then 
						return 1 
					--end
		        end
			end
		end
	end

	-- No collision
	return 0
end


-- Returning 'true' means this bullet reached a death state - 'false' is continue moving.
local BULLET_CALC_MOVE = {

	-- Every Other Bullet --
	function() 
		return false 
	end,


	-- Ranggun --
	function (i, type, startX, startY, playerX, playerY, time)
		
		-- Spin rang image
		local index = misc[i] + 1
		if index > 8 then index = 1 end
		misc[i] = index
		rotatedImage[i] = GET_IMAGE(RANGGUN_TABLES_LIST[ tier[i] ], index)

		-- Move rang in direction found via create
		local currentMode = mode[i]
		if currentMode < 1 then 
			if (lifeTime[i] - 5000) < time then 
				mode[i] = 1
			end
			return false

		-- Move rang in a circle
		elseif currentMode < 2 then
			local bSpeed = BULLET_SPEEDS[type] * playerBulletSpeed * dt 
			local newRot = rotation[i] - 15
			rotation[i] = newRot

			local radian = (newRot - 90) * M_PI_180
			local dirX, dirY = cos(radian), sin(radian)
			velX[i], velY[i] = dirX * bSpeed, dirY * bSpeed

			if (lifeTime[i] - 3000) < time then 
				mode[i] = 2 
			end
			return false

		-- Return rang to player and destroy rang
		else
			-- player distance check
			local xDiff, yDiff = playerX - startX, playerY - startY
			local magSquared = xDiff * xDiff + yDiff * yDiff
			if magSquared < 300 then
				return true -- DESTROYED
			end

			-- move towards player
			local bSpeed = BULLET_SPEEDS[type] * playerBulletSpeed * dt
			local mag = bSpeed / sqrt(magSquared)
			velX[i], velY[i] = xDiff * mag, yDiff * mag
			return false
		end
	end

	--[[
	-- Wavegun --
	function (i, type, startX, startY, playerX, playerY, time)
		if self.lifeTime - 1300 + (200 * self.mode) < theCurrTime then 
			self.mode += 1
			if self.damage > 1 then self.damage = math.ceil(self.damage/2) end
			self:setScale(1 + self.mode/2 * self.tier, 1)
			self:setCollideRect(0, 0, self:getSize())
		end
		return false
	end
	]]--

}


local QUERY_RECT 	<const> = worldQueryRectFast
local HIT_ENEMY 	<const> = bulletEnemyCollision
local ENEMY_POS 	<const> = getEnemyPosition

local MOVE_CALC_TYPE = {
	1, -- peagun
	1, -- cannon
	1, -- minigun
	1, -- shotgun
	1, -- burstgun
	1, -- grenade
		2, -- ranggun
		3, -- wavegun
	1 -- grenadePellet
}

local DAMAGE_TIMER_SET = {
	0, -- peagun
	0, -- cannon
	0, -- minigun
	0, -- shotgun
	0, -- burstgun
	0, -- grenade
		50, -- ranggun
		50, -- wavegun
	0 -- grenadePellet
}

-- enclosed in local function to allow return out at any point while staying inside while loop
local function collideMove(i, type, halfSize, bTier, offsetX, offsetY, playerX, playerY, time)

	local startX, startY = posX[i], posY[i]

	-- IF calc timer is set, then wait to calc new movement until timer elapsed
	local calcTimer = moveCalcTimer[i]
	if 0 < calcTimer and calcTimer < time then

		-- reset timer
		local timeGroupOffset = i % GROUP_SIZE * TIME_SET_SIZE
		local nextTimeGroup = time // GROUP_TIME_SET + 1
		moveCalcTimer[i] = nextTimeGroup * GROUP_TIME_SET + timeGroupOffset

		-- do special direction calcs for certain bullets - if TRUE then this destroyed the bullet
		if BULLET_CALC_MOVE[ MOVE_CALC_TYPE[type] ](i, type, startX, startY, playerX, playerY, time) == true then 
			lifeTime[i] = 0
			return startX, startY
		end	

	end

	-- movement calcs for every bullet
	local endX, endY = startX + velX[i], startY + velY[i] 
	local screenPosX, screenPosY = endX + offsetX, endY + offsetY 

	-- out of camera bounds - checking before movement/collision bc bullet could be deleted from camera movement
	if 	screenPosX < SCREEN_MIN_X or SCREEN_MAX_X < screenPosX or 
		screenPosY < SCREEN_MIN_Y or SCREEN_MAX_Y < screenPosY then 
			lifeTime[i] = 0
			return endX, endY
	end	

	-- If this world cell has NO colliders in it, then only move bullet.
	-- Even though we're looping through cells twice per bullet on collisions, it's still faster to check
	-- with the cheaper loop first since bullets spend more time not colliding with objects.
			-- TO DO: see if this can actually be done in one loop
	local x1, x2, y1, y2 = 0, 0, 0, 0
	local tierOffset = min(bTier, 2)
	if startX < endX then 	x1 = startX - halfSize 
							x2 = tierOffset * halfSize + endX
	else 					x1 = endX - halfSize
							x2 = tierOffset * halfSize + startX
	end
	if startY < endY then 	y1 = startY - halfSize
							y2 = tierOffset * halfSize + endY
	else 					y1 = endY - halfSize
							y2 = tierOffset * halfSize + startY
	end
	local cellCount = countCollidersInOccupiedCells(worldRef, x1, y1, x2, y2)

	-- NEGATIVE - out of bounds - delete
	if cellCount < 0 then 
		lifeTime[i] = 0
		return endX, endY
	end

	-- ZERO - no colliders in occupied cells, so just move
	if cellCount < 1 then 
		posX[i], posY[i] = endX, endY
		return endX, endY
	end

	-- GREATER THAN ZERO - colliders in cells, do collision checking
	local queryX, queryY = min(x1, x2), min(y1, y2)
	local queryWidth, queryHeight = abs(x2 - x1), abs(y2 - y1)
	local rect = QUERY_RECT(worldRef, queryX, queryY, queryWidth, queryHeight)

	-- a rect was found - NOT nil
	if rect then

		-- any enemy rect
		local enemyIndex = rect.index
		if enemyIndex then
			
			-- DAMAGE TIMERS - don't allow damage if timer exists - just move
			if DAMAGE_TIMER_SET[type] > 0 then

				-- no damage 	- yes move
				if timer[i] > time then
					posX[i], posY[i] = endX, endY
					return endX, endY

				-- yes damage 	- yes move
				else
					HIT_ENEMY(enemyIndex, damage[i], knockback[i], playerX, playerY, time)
					timer[i] = time + DAMAGE_TIMER_SET[type]
					posX[i], posY[i] = endX, endY
					return endX, endY
				end
			end
			

			--[[
			-- if allowed to bounce off an enemy, use up a bounce
			if bounce[i] > 0 then 
				bounce[i] -= 1
				timer[i] = time + BOUNCE_TIMER
				lifeTime[i] = time + BULLET_LIFETIMES[type]
				mode[i] = 0
				local enemyX, enemyY = ENEMY_POS(enemyIndex)
				local newDirection = newVec(worldStartX - enemyX, worldStartY - enemyY):normalized()

				-- Deleted dirX and dirY, use velX and velY instead

				dirX[i], dirY[i] = newDirection.x, newDirection.y
				posX[i] = enemyX + (dirX[i] * width * 2)
				posY[i] = enemyY + (dirY[i] * height * 2)

				return endX, endY
			end
			]]

		-- REGULAR ENEMY DAMAGE - 
			HIT_ENEMY(enemyIndex, damage[i], knockback[i], playerX, playerY, time)
			lifeTime[i] = 0
			return endX, endY


		-- a wall OR object rect - delete bullet on this collision
		else
			-- Damage objects within an assigned index
			local objectIndex = rect.objectIndex
			if objectIndex then damageObject(objectIndex, damage[i]) end

			-- Delete this bullet via lifeTime
			lifeTime[i] = 0
			return endX, endY
		end
	end 

	-- in a cell with rects, but NO collision happened - just move
	posX[i], posY[i] = endX, endY
	return endX, endY
end


local FAST_DRAW <const> = gfx.image.draw

-- Move, Collide, Draw and Delete all bullets
local function updateBulletLists(time, playerX, playerY, screenOffsetX, screenOffsetY)

	-- LOOP
	local i = 1
	local currentActiveBullets = activeBullets
	while i <= currentActiveBullets do	

		-- move and collide
		local type = bulletType[i]
		local halfSize = imageHalfSize[i]
		local bTier = tier[i]
		local x, y = collideMove(i, type, halfSize, bTier, screenOffsetX, screenOffsetY, playerX, playerY, time)

		-- draw
		if time < lifeTime[i] then		
			FAST_DRAW(rotatedImage[i], x - halfSize, y - halfSize)
			i = i + 1
		
		-- delete - do NOT need to increment loop here
		else 
			if type == GRENADE_TYPE then
				grenadeCount += 1
				grenadeX[grenadeCount] = x
				grenadeY[grenadeCount] = y
				grenadeTier[grenadeCount] = bTier
			end
			
			deleteBullet(i, currentActiveBullets)
			currentActiveBullets -= 1
		end
	end
	activeBullets = currentActiveBullets

	-- Create new grenade pellets
	if grenadeCount < 1 then return end
	for i = 1, grenadeCount do
		createGrenadePellets(grenadeTier[i], grenadeX[i], grenadeY[i], time)
	end
	grenadeCount = 0
end



-- used for the post-pause screen countdown to redraw the screen
function redrawBullets()
	local currentActiveBullets = activeBullets
	for i = 1, currentActiveBullets do	

		local halfSize = imageHalfSize[i]
		FAST_DRAW(rotatedImage[i], posX[i] - halfSize, posY[i] - halfSize)

	end
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


function updateBullets(time, crank, playerX, playerY, screenOffsetX, screenOffsetY)

	-- Variable setup for this tick
	newShotsFired = 0


	handleCreatingBullets(time, playerX, playerY, crank)
	updateBulletLists(time, playerX, playerY, screenOffsetX, screenOffsetY)

	
	-- Shot bullet tracking for player
	return newShotsFired
end