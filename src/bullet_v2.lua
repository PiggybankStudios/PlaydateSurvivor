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

local mathFloor <const> = math.floor
local mathCeil <const> = math.ceil
local random <const> = math.random
local newVec <const> = vec.new
local newPolar <const> = vec.newPolar
local queryLine <const> = gfx.sprite.querySpritesAlongLine
local queryRect <const> = gfx.sprite.querySpritesInRect


-- identical to global tags, localized for speed and readability
local LOCAL_TAGS = {
	walls = 1,
	player = 2,
	weapon = 3,
	enemy = 4,
}

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
	2, -- peagun
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
	0, 		-- peagun
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

-- Bullets
local bulletLifetime <const> = 	2000
local maxBullets <const> = 		1000 -- max that can exist in the world at one time
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
local timer = {}

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
-- |                           Timers                             |
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
	timer[i] = 0
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

	if activeBullets >= maxBullets then do return end end -- if too many bullets exist, then don't make another bullet


	activeBullets += 1
	addShot()
	local total = activeBullets
	local direction = newPolar(1, newRotation)

	bulletType[total] = type
	posX[total] = spawnX
	posY[total] = spawnY
	rotation[total] = newRotation
	scale[total] = 1
	dirX[total] = direction.x
	dirY[total] = direction.y 
	speed[total] = BULLET_SPEEDS[type] * getPlayerBulletSpeed()
	lifeTime[total] = mainLoopTime + bulletLifetime
	knockback[total] = BULLET_KNOCKBACKS[type]
	peircing[total] = BULLET_PEIRCING[type]
	tier[total] = newTier
	--damage[total] = BULLET_DAMAGE[type]()
	mode[total] = 0
	timer[total] = 0

	if type == BULLET_TYPE.cannon then
		damage[total] = 3 + getPlayerGunDamage() * (1 + newTier)
		scale[total] = newTier

	elseif type == BULLET_TYPE.minigun then
		damage[total] = 1 + mathCeil(getPlayerGunDamage() / 2)

	elseif type == BULLET_TYPE.shotgun then
		damage[total] = 1 + mathFloor(getPlayerGunDamage() / 2) --round down

	elseif type == BULLET_TYPE.burstgun then
		damage[total] = 1 + getPlayerGunDamage()

	elseif type == BULLET_TYPE.grenade then
		damage[total] = 2 + getPlayerGunDamage()
		lifeTime[total] = mainLoopTime + 1000

	elseif type == BULLET_TYPE.ranggun then
		damage[total] = 1 + mathFloor(getPlayerGunDamage() / 3)
		lifeTime[total] = mainLoopTime + 6000
		scale[total] = newTier

	elseif type == BULLET_TYPE.wavegun then
		damage[total] = 4 + getPlayerGunDamage()

	elseif type == BULLET_TYPE.grenadePellet then
		damage[total] = 1 + mathFloor(getPlayerGunDamage() / 2)

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
	timer[i] = timer[total]
end


-- Grenade Pellet Only
local function createGrenadePellets(index, gX, gY, totalBullets, mainLoopTime)
	local grenadeX = gX
	local grenadeY = gY
	local grenadeTier = tier[index]
	local amount = 4 + (4 * grenadeTier)
	local degree = mathFloor(360/amount)
	local newRotation = 0
	for i = 1, amount do
		newRotation += degree
		create(BULLET_TYPE.grenadePellet, grenadeX, grenadeY, newRotation, grenadeTier, mainLoopTime)
	end

	return totalBullets + amount
end


-- Determine the bullet that needs to be created
local function determineBullet(iGunSlot, mainLoopTime, elapsedPauseTime)

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
	local playerPos = getPlayerPosition()
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
local function handleCreatingBullets(playerGunStats, mainLoopTime, elapsedPauseTime)

	local totalGunSlots = #theGunSlots
	for iGunSlot = 1, totalGunSlots do
		determineBullet(iGunSlot, playerGunStats, mainLoopTime, elapsedPauseTime)
	end

end


-- +--------------------------------------------------------------+
-- |                           Movement                           |
-- +--------------------------------------------------------------+


local function calculateMoveChanges(index)
	-- Ranggun --
	if bulletType[index] == BULLET_TYPE.ranggun then
		local currentMode = mode[index]

		-- Move in given direction
		if currentMode == 0 then 
			if (lifeTime[index] - 5000) < theCurrTime then mode[index] = 1 end

		-- Rotate over time
		elseif currentMode == 1 then
			rotation[index] -= 15
			local newDirection = newPolar(1, rotation[index])
			dirX[index] = newDirection.x
			dirY[index] = newDirection.y
			if (lifeTime[index] - 3000) < theCurrTime then mode[index] = 2 end

		-- Return to player
		elseif currentMode == 2 then
			local vecToPlayer = vec.new(playerPos.x - posX[index], playerPos.y - posY[index])
			local newDirection = vecToPlayer:normalized()
			dirX[index] = newDirection.x 
			dirY[index] = newDirection.y		
			local playerDistance = vecToPlayer:magnitudeSquared()	-- destroy self when close to player			
			if playerDistance < 300 then lifeTime[index] = 0 end
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




local function handleCollision(index, startX, startY, endX, endY)
	local tag
	local enemy
	local currentBullet = bulletType[index]
	local collisionSprites = queryLine(startX, startY, endX, endY) -- basically ray casting - doesn't take bullet size into consideration
	for k = 1, #collisionSprites do
		enemy = collisionSprites[k]
		tag = enemy:getTag()
		if tag == TAGS.enemy then
			 
			if peircing[index] > 0 then peircing[index] = math.max(peircing[index] - 1, 0)	
			elseif peircing[index] == 0 then lifeTime[index] = 0			
			end

			enemy:damage(damage[index])
			enemy:applyKnockback(knockback[index])
			enemy:potentialStun()
			do return end
		elseif tag == TAGS.walls then
			lifeTime[index] = 0
			do return end
		end
	end
end
]]--

--[[
local function moveBullet(i, dt, offX, offY)
	local bulletSpeed = speed[i]

	local moveX = (dirX[i] * bulletSpeed * dt)
	local moveY = (dirY[i] * bulletSpeed * dt)

	--local startX = posX[i] - moveX
	--local startY = posY[i] - moveY
	--local endX = posX[i] + moveX
	--local endY = posY[i] + moveY

	--if allowBulletCollisions == true then 
	--	handleCollision(i, startX, startY, endX, endY)
	--end
	
	posX[i] += moveX
	posY[i] += moveY
end
]]--


-- Constants for speed
local colliderBlockWidth <const> = 50
local colliderBlockHeight <const> = 48
local blocksHor <const> = 8
local blocksVer <const> = 5
local blocksTotal <const> = 40

local colliderBlocks = { 
	0, 0, 0, 0, 0, 0, 0, 0,	-- 8 x 5
	0, 0, 0, 0, 0, 0, 0, 0,	-- 40 total
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
}

local function queryColliderBlocks(offX, offY)	
	for i = 1, blocksVer do
		local blockY = (i - 1) * 8

		for j = 1, blocksHor do
			local x = (j - 1) * colliderBlockWidth
			local y = (i - 1) * colliderBlockHeight
			local sprites = queryRect(x-offX, y-offY, colliderBlockWidth, colliderBlockHeight)
			local spriteCount = #sprites

			-- Do not count the player collider
			for k = 1, spriteCount do
				if sprites[k]:getTag() == TAGS.player then spriteCount -= 1 end
				break
			end

			colliderBlocks[j+blockY] = spriteCount

			-- debug drawing
			--gfx.setColor(gfx.kColorWhite)
			--gfx.fillRect(x, y, colliderBlockWidth, colliderBlockHeight)
			--gfx.setColor(gfx.kColorBlack)
			--gfx.drawRect(x, y, colliderBlockWidth, colliderBlockHeight)			
			--gfx.drawText(colliderBlocks[j+blockY], x + (colliderBlockWidth/2.5), y + (colliderBlockHeight/3))
		end
	end
end

--[[
local function printColliderBlocks()
	for index = 0, blocksVer-1 do
		local i = (index * 8) + 1
		print(	
			colliderBlocks[i] .. ", " .. 
			colliderBlocks[i+1] .. ", " ..
			colliderBlocks[i+2] .. ", " ..
			colliderBlocks[i+3] .. ", " ..
			colliderBlocks[i+4] .. ", " ..
			colliderBlocks[i+5] .. ", " ..
			colliderBlocks[i+6] .. ", " ..
			colliderBlocks[i+7]
			)
	end
end
]]--


-- +--------------------------------------------------------------+
-- |                           Management                         |
-- +--------------------------------------------------------------+

local resetDone = false
function clearBullets()
	--for i = 1, maxBullets do
	--	lifeTime[i] = 0
	--end

	activeBullets = 0

	resetDone = true
end


function clearGunStats()
	theShotTimes = {0, 0, 0, 0}
	theGunSlots = {BULLET_TYPE.peagun, 0, 0, 0}
	theGunLogic = {0, 0, 0, 0}
	theGunTier = {1, 0, 0, 0}
end


-- +--------------------------------------------------------------+
-- |                           Globals                            |
-- +--------------------------------------------------------------+


function toggleBulletCollisions()
	allowBulletCollisions = not allowBulletCollisions
	maxUpdateTimer = 0
	print(" ---- Toggled bullet collision to: " .. tostring(allowBulletCollisions) .. " ---- reset 'Update Timer' ")
end


function getEquippedGun(index)
	return theGunSlots[index]
end

function getNumEquippedGuns()
	local totEquipped = 1
	if theGunSlots[2] > 0 then totEquipped += 1 end
	if theGunSlots[3] > 0 then totEquipped += 1 end
	if theGunSlots[4] > 0 then totEquipped += 1 end
	return totEquipped
end


function getTierForGun(index)
	return theGunTier[index]
end


function newWeaponChosen(weapon, slot, tier)
	local extraTier = 0
	if (theGunSlots[slot] == weapon) and (theGunTier[slot] == tier) then extraTier = 1 end
	theGunSlots[slot] = weapon
	theGunTier[slot] = math.min(tier + extraTier,3)
	updateMenuWeapon(slot, weapon)
end


-- Equip the next gun in the bullet type list. For testing.
function equipNextGun()
	local gun = theGunSlots[1]
	gun +=1
	if gun >= 9 then gun = 1 end

	theGunSlots[1] = gun
end


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local img_bulletPeagun = gfx.image.new('Resources/Sprites/bullet/BulletPeagun')
local img_bulletCannon = gfx.image.new('Resources/Sprites/bullet/BulletCannon')
local img_bulletMinigun = gfx.image.new('Resources/Sprites/bullet/BulletMinigun')
local img_bulletShotgun = gfx.image.new('Resources/Sprites/bullet/BulletShotgun')
local img_bulletBurstGun = gfx.image.new('Resources/Sprites/bullet/BulletBurstgun')
local img_bulletGrenade = gfx.image.new('Resources/Sprites/bullet/BulletGrenade')
local img_bulletRanggun = gfx.image.new('Resources/Sprites/bullet/BulletRanggun')
local img_bulletWavegun = gfx.image.new('Resources/Sprites/bullet/BulletWavegun')
local img_bulletGrenadePellet = gfx.image.new('Resources/Sprites/bullet/BulletGrenadePellet')

local IMAGE_LIST = {
	img_bulletPeagun,
	img_bulletCannon,
	img_bulletMinigun,
	img_bulletShotgun,
	img_bulletBurstGun,
	img_bulletGrenade,
	img_bulletRanggun,
	img_bulletWavegun,
	img_bulletGrenadePellet	
}

local bulletsImage = gfx.image.new(400, 240) -- screen size draw
local bulletsSprite = gfx.sprite.new(bulletsImage)	-- drawing image w/ sprite so we can draw via zIndex order
bulletsSprite:setIgnoresDrawOffset(true)			
bulletsSprite:setZIndex(ZINDEX.weapon)
bulletsSprite:moveTo(200, 120)


-- GLOBAL -- to be called after level creation, b/c level start clears the sprite list
function addBulletSpriteToList()
	bulletsSprite:add()
end


-- Constants for speed
local lockFocus <const> = gfx.lockFocus
local unlockFocus <const> = gfx.unlockFocus
local setColor <const> = gfx.setColor
local colorBlack <const> = gfx.kColorBlack
local colorClear <const> = gfx.kColorClear
local drawOffset <const> = gfx.getDrawOffset
local delete <const> = deleteBullet

-- just used within 'collideMove'
local function localClamp(value, min, max)
	if value > max then
		return max
	elseif value < min then 
		return min
	else
		return value
	end
end
	
-- enclosed in local function to allow return out at any point while staying inside while loop
local function collideMove(dt, index, image, offsetX, offsetY)

	local i = index
	
	local colStartX = posX[i]
	local colStartY = posY[i]
	local startOffsetX = colStartX + offsetX
	local startOffsetY = colStartY + offsetY	

	-- out of bounds - checking before movement/collision bc bullet could be deleted from camera movement
	if startOffsetX < -50 or 450 < startOffsetX or startOffsetY < -50 or 290 < startOffsetY then 
		lifeTime[i] = 0
		return colStartX, colStartY
	end

	--calculateMoveChanges(i)	
	local bulletSpeed = speed[i]
	local moveX = (dirX[i] * bulletSpeed * dt)
	local moveY = (dirY[i] * bulletSpeed * dt)
	local size = scale[i]
	local width, height = image:getSize()			
	local halfWidth = width * size * 0.5
	local halfheight = height * size * 0.5
	
	-- collision: pre-movement	
	local blockX = mathFloor(startOffsetX / colliderBlockWidth) + 1
	local blockY = mathFloor(startOffsetY / colliderBlockHeight) * 8
	local block = localClamp(blockX + blockY, 1, 40)	
	if colliderBlocks[block] > 0 then

		-- check current rect position
		local collider = queryRect(colStartX - halfWidth, colStartY - halfheight, width, height)
		local sprite = collider[1]
		if sprite ~= nil then 
			if sprite:getTag() == LOCAL_TAGS.enemy then
				sprite:damage(damage[i])
				sprite:applyKnockback(knockback[i])
				sprite:potentialStun()
			end 

			lifeTime[i] = 0
			return colStartX, colStartY
		end

		-- raycast forward to find intersections
		collider = queryLine(colStartX, colStartY, colStartX + moveX, colStartY + moveY)
		local sprite = collider[1]
		if sprite ~= nil then 
			if sprite:getTag() == LOCAL_TAGS.enemy then
				sprite:damage(damage[i])
				sprite:applyKnockback(knockback[i])
				sprite:potentialStun()
			end 

			lifeTime[i] = 0
			return colStartX, colStartY
		end

	end		

	-- move
	posX[i] += moveX
	posY[i] += moveY
	return (posX[i] + offsetX), (posY[i] + offsetY), halfWidth, halfheight, size
end


-- Move, Collide, Draw and Delete all bullets
local function updateBulletLists(dt, mainLoopTime, elapsedPauseTime)
	local localCurrentTime = mainLoopTime
	local offsetX
	local offsetY 
	offsetX, offsetY = drawOffset()


	bulletsImage:clear(colorClear)	
	lockFocus(bulletsImage)

		-- Query collider blocks for collision handling
		queryColliderBlocks(offsetX, offsetY)

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
			local image = IMAGE_LIST[type]
			local x, y, halfWidth, halfheight, size = collideMove(dt, i, image, offsetX, offsetY)
			
			-- delete
			if localCurrentTime > lifeTime[i] then
				if type == BULLET_TYPE.grenade then
					if halfWidth ~= nil then
						x -= offsetX
						y -= offsetY
					end
					currentActiveBullets = createGrenadePellets(i, x, y, currentActiveBullets, mainLoopTime) 
				end
				delete(i, currentActiveBullets)
				currentActiveBullets -= 1
				i -= 1	
			
			-- draw, if not deleted
			else 
				image:drawScaled(x - halfWidth, y - halfheight, size)

			end

			-- increment
			i += 1		
		end

	unlockFocus()
	activeBullets = currentActiveBullets
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



	-- Bullet Handling
	playdate.resetElapsedTime()
		handleCreatingBullets(mainLoopTime, elapsedPauseTime)
	getCreateTimer()
	
	playdate.resetElapsedTime()	
		updateBulletLists(dt, mainLoopTime, elapsedPauseTime)
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
	]]--
end