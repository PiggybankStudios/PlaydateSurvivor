---
-- This file handles bullets as a SOA (structure-of-arrays).
-- Each array contains one part of the following data:
	-- bulletType 
	-- posX
	-- posY
	-- rotation
	-- scale
	-- dirX
	-- dirY
	-- speed
	-- lifeTime
	-- damage
	-- knockback
	-- peircing
	-- tier
	-- mode
	-- timer
-- Bullets are all drawn onto a single screen-sized image, which is passed into a single sprite.
-- The sprite ignores the draw-offset, but the draw-offset is added into the position into each bullet.
-- Bullets are identified by an index number.
-- Bullets are deleted by being swapped to the end, reducing the active bullets number, and setting their BULLET_TYPE to none.
	-- The data for the bullet that was at the end overwrites the bullet that is deleted.
-- Bullets with BULLET_TYPE.none are passed over in the Update and Draw loops.
-- Bullets are created the list position 1 + activeBullets. This avoids the need to search for an empty position.


local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local queryLine <const> = gfx.sprite.querySpritesAlongLine
local mathFloor <const> = math.floor
local mathCeil <const> = math.ceil

local theCurrTime = 0
local playerPos = vec.new(0, 0)

-- Bullet Type Variables --
local BULLET_TYPE = {
	none = 1,
	peagun = 2,
	cannon = 3,
	minigun = 4,
	shotgun = 5,
	burstgun = 6,
	grenade = 7,
	ranggun = 8, -- NOT DONE YET
	wavegun = 9, -- NOT DONE YET
	grenadePellet = 10
}

-- Index position is the gun type - this list returns the speed for each gun type.
local BULLET_SPEEDS = {
	0, -- none
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
	0, -- none
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
	0, 		-- none
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
	0, 		-- none
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
local bulletLifetime <const> = 	1000 --1500
local maxBullets <const> = 		1000 -- max that can exist in the world at one time
local activeBullets = 0

local tempMaxBullets = { 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000 }
local tempMaxBulletsIndex = 1

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
local theGunSlots = {BULLET_TYPE.shotgun, BULLET_TYPE.shotgun, BULLET_TYPE.shotgun, BULLET_TYPE.shotgun} --what gun in each slot
local theGunLogic = {0, 0, 0, 0} --what special logic that slotted gun needs
local theGunTier = {3, 3, 3, 3} -- what tier the gun is at


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
		print(" - Create: " .. 1000*maxCreateTimer)
	end
end


local function getUpdateTimer()
	currentUpdateTimer = playdate.getElapsedTime()
	if maxUpdateTimer < currentUpdateTimer then
		maxUpdateTimer = currentUpdateTimer
		print(" -- Update: " .. 1000*maxUpdateTimer)
	end
end


local function getDrawTimer()
	currentDrawTimer = playdate.getElapsedTime()
	if maxDrawTimer < currentDrawTimer then
		maxDrawTimer = currentDrawTimer
		print(" --- Draw: " .. 1000*maxDrawTimer)
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
	bulletType[i] = BULLET_TYPE.none
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


function nextBulletMax()
	tempMaxBulletsIndex += 1
	if tempMaxBulletsIndex > #tempMaxBullets then tempMaxBulletsIndex = 1 end
end


-- Create a bullet at the end of the list
local function createBullet(type, spawnX, spawnY, newRotation, newTier)

	--if activeBullets >= maxBullets then do return end end -- if too many bullets exist, then don't make another bullet

	if activeBullets >= tempMaxBullets[tempMaxBulletsIndex] then do return end end
	if type == BULLET_TYPE.none then do return end end

	activeBullets += 1
	addShot()
	local total = activeBullets
	local direction = vec.newPolar(1, newRotation)

	bulletType[total] = type
	posX[total] = spawnX
	posY[total] = spawnY
	rotation[total] = newRotation
	scale[total] = 1
	dirX[total] = direction.x
	dirY[total] = direction.y 
	speed[total] = BULLET_SPEEDS[type] * getPlayerBulletSpeed()
	lifeTime[total] = theCurrTime + bulletLifetime
	knockback[total] = BULLET_KNOCKBACKS[type]
	peircing[total] = BULLET_PEIRCING[type]
	tier[total] = newTier
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
		lifeTime[total] = theCurrTime + 1000

	elseif type == BULLET_TYPE.ranggun then
		damage[total] = 1 + mathFloor(getPlayerGunDamage() / 3)
		lifeTime[total] = theCurrTime + 6000
		scale[total] = newTier

	elseif type == BULLET_TYPE.wavegun then
		damage[total] = 4 + getPlayerGunDamage()

	elseif type == BULLET_TYPE.grenadePellet then
		damage[total] = 1 + mathFloor(getPlayerGunDamage() / 2)

	else -- peagun
		damage[total] = 1 + getPlayerGunDamage()

	end
end


-- Deleted bullet is swapped with bullet at the ends of all lists
local function deleteBullet(index, currentActiveBullets)
	local total = currentActiveBullets

	-- overwrite the to-be-deleted bullet with the bullet at the end
	bulletType[index] = bulletType[total]
	posX[index] = posX[total]
	posY[index] = posY[total]
	rotation[index] = rotation[total]
	scale[index] = scale[total]
	dirX[index] = dirX[total]
	dirY[index] = dirY[total]
	speed[index] = speed[total]
	lifeTime[index] = lifeTime[total]
	damage[index] = damage[total]
	knockback[index] = knockback[total]
	tier[index] = tier[total]
	mode[index] = mode[total]
	timer[index] = timer[total]
end


-- Constants for speed
local create <const> = createBullet
local random <const> = math.random

-- Grenade Pellet Only
local function createGrenadePellets(index, gX, gY, totalBullets)
	local grenadeX = gX
	local grenadeY = gY
	local grenadeTier = tier[index]
	local amount = 4 + (4 * grenadeTier)
	local degree = mathFloor(360/amount)
	local newRotation = 0
	for i = 1, amount do
		newRotation += degree
		create(BULLET_TYPE.grenadePellet, grenadeX, grenadeY, newRotation, grenadeTier)
	end

	return totalBullets + amount
end

-- All other bullets, spawned in timed intervals
local function handleCreatingBullets()
	local playerX = playerPos.x
	local playerY = playerPos.y
	local playerRot = getCrankAngle()
	local playerAttackRate = getPlayerAttackRate()
	
	-- for each gun slot, check the weapon and the shot time to see if a bullet can be created
	for iGunSlot = 1, #theGunSlots do

		local currentBullet = theGunSlots[iGunSlot]
		local slotAngle = playerRot + (90 * iGunSlot)
		local gunTier = theGunTier[iGunSlot]
		local gunLogic = theGunLogic[iGunSlot]

		if currentBullet > 0 then 
			if theShotTimes[iGunSlot] < theCurrTime then

				-- Set values for this type of bullet
				theShotTimes[iGunSlot] = theCurrTime + playerAttackRate * BULLET_ATTACKRATES[currentBullet]

				-- Cannon --
				if currentBullet == BULLET_TYPE.cannon then
					create(currentBullet, playerX, playerY, slotAngle, gunTier)				

				-- Minigun --
				elseif currentBullet == BULLET_TYPE.minigun then
					local angleWiggle = random(-8, 8)
					create(currentBullet, playerX, playerY, slotAngle + angleWiggle, gunTier)
					if gunTier > 1 then
						angleWiggle = random(9, 16)
						create(currentBullet, playerX, playerY, slotAngle + angleWiggle, gunTier)
					end
					if gunTier > 2 then
						angleWiggle = random(9, 16)
						create(currentBullet, playerX, playerY, slotAngle - angleWiggle, gunTier)
					end

				-- Shotgun --
				elseif currentBullet == BULLET_TYPE.shotgun then
					create(currentBullet, playerX, playerY, slotAngle - 2, gunTier)
					create(currentBullet, playerX, playerY, slotAngle + 2, gunTier)

					create(currentBullet, playerX, playerY, slotAngle - 4, gunTier)
					create(currentBullet, playerX, playerY, slotAngle + 4, gunTier)

					create(currentBullet, playerX, playerY, slotAngle - 6, gunTier)
					create(currentBullet, playerX, playerY, slotAngle + 6, gunTier)

					create(currentBullet, playerX, playerY, slotAngle - 8, gunTier)
					create(currentBullet, playerX, playerY, slotAngle + 8, gunTier)

					create(currentBullet, playerX, playerY, slotAngle - 10, gunTier)
					create(currentBullet, playerX, playerY, slotAngle + 10, gunTier)

					create(currentBullet, playerX, playerY, slotAngle - 12, gunTier)
					create(currentBullet, playerX, playerY, slotAngle + 12, gunTier)

					create(currentBullet, playerX, playerY, slotAngle - 14, gunTier)
					create(currentBullet, playerX, playerY, slotAngle + 14, gunTier)

					create(currentBullet, playerX, playerY, slotAngle - 16, gunTier)
					create(currentBullet, playerX, playerY, slotAngle + 16, gunTier)

					create(currentBullet, playerX, playerY, slotAngle - 18, gunTier)
					create(currentBullet, playerX, playerY, slotAngle + 18, gunTier)

					if theGunTier[iGunSlot] > 1 then
						create(currentBullet, playerX, playerY, slotAngle, gunTier)
					end
					if theGunTier[iGunSlot] > 2 then
						create(currentBullet, playerX, playerY, slotAngle - 20, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 20, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 22, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 22, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 24, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 24, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 26, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 26, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 28, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 28, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 30, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 30, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 32, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 32, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 34, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 34, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 36, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 36, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 38, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 38, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 40, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 40, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 42, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 42, gunTier)

						create(currentBullet, playerX, playerY, slotAngle - 44, gunTier)
						create(currentBullet, playerX, playerY, slotAngle + 44, gunTier)
					end
				
				-- Burstgun --
				elseif currentBullet == BULLET_TYPE.burstgun then
					if gunLogic < 3 then
						theShotTimes[iGunSlot] = theCurrTime + 30
						theGunLogic[iGunSlot] += 1
						create(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)

						if gunTier > 1 then 
							create(currentBullet, playerPos.x, playerPos.y, slotAngle - 7, gunTier)
						end
						if gunTier > 2 then
							create(currentBullet, playerPos.x, playerPos.y, slotAngle + 7, gunTier)
						end
					else
						theGunLogic[iGunSlot] = 0
					end
				
				-- Grenade --
				elseif currentBullet == BULLET_TYPE.grenade then
					create(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)

				-- Ranggun --
				elseif currentBullet == BULLET_TYPE.ranggun then
					create(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)

				--[[
				-- Wavegun -- 
				elseif theGunSlots[sIndex] == BULLET_TYPE.wavegun then
					createBullet(playerPos, newRotation, (newLifeTime), theGunSlots[sIndex], sIndex, theGunTier[sIndex])
				]]--

				-- Peagun
				else
					create(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)
					if gunTier > 1 then
						local tempVec = (vec.newPolar(1, slotAngle):leftNormal() * 10) + playerPos
						create(currentBullet, tempVec.x, tempVec.y, slotAngle, gunTier)
					end
					if gunTier > 2 then
						local tempVec = (vec.newPolar(1, slotAngle):rightNormal() * 10) + playerPos
						create(currentBullet, tempVec.x, tempVec.y, slotAngle, gunTier)
					end
				end

			end
		end
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
			local newDirection = vec.newPolar(1, rotation[index])
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

-- +--------------------------------------------------------------+
-- |                           Management                         |
-- +--------------------------------------------------------------+


function clearBullets()
	for i = 1, maxBullets do
		bulletType[i] = BULLET_TYPE.none
		lifeTime[i] = 0
	end

	activeBullets = 0
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


function getTierForGun(index)
	return theGunTier[index]
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
	if gun >= 9 then gun = 1 end

	theGunSlots[1] = gun
end


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local img_bulletPeagun = gfx.image.new('Resources/Sprites/BulletPeagun')
local img_bulletCannon = gfx.image.new('Resources/Sprites/BulletCannon')
local img_bulletMinigun = gfx.image.new('Resources/Sprites/BulletMinigun')
local img_bulletShotgun = gfx.image.new('Resources/Sprites/BulletShotgun')
local img_bulletBurstGun = gfx.image.new('Resources/Sprites/BulletBurstgun')
local img_bulletGrenade = gfx.image.new('Resources/Sprites/BulletGrenade')
local img_bulletRanggun = gfx.image.new('Resources/Sprites/BulletRanggun')
local img_bulletWavegun = gfx.image.new('Resources/Sprites/BulletWavegun')
local img_bulletGrenadePellet = gfx.image.new('Resources/Sprites/BulletGrenadePellet')

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
local black <const> = gfx.kColorBlack
local drawOffset <const> = gfx.getDrawOffset
local delete <const> = deleteBullet

-- Move, Collide, Draw and Delete all bullets
local function updateBulletLists(dt)

	local offsetX
	local offsetY 
	offsetX, offsetY = drawOffset()

	bulletsImage:clear(gfx.kColorClear)	
	lockFocus(bulletsImage)

		-- set details
		setColor(black)

		-- loop over bullets
		local i = 1
		local currentActiveBullets = activeBullets
		while i <= currentActiveBullets do			
			-- move
			--calculateMoveChanges(i)		
			local bulletSpeed = speed[i]			
			posX[i] += (dirX[i] * bulletSpeed * dt)
			posY[i] += (dirY[i] * bulletSpeed * dt)
			local x = posX[i] + offsetX
			local y = posY[i] + offsetY

			-- draw
			local type = bulletType[i] - 1
			local size = scale[i]
			IMAGE_LIST[type]:drawScaled(x, y, size)

			-- out of bounds
			if x < -50 or 450 < x or y < -50 or 290 < y then lifeTime[i] = 0 end

			-- delete
			if theCurrTime > lifeTime[i] then
				if type + 1 == BULLET_TYPE.grenade then 
					gX = x - offsetX
					gY = y - offsetY
					currentActiveBullets = createGrenadePellets(i, gX, gY, currentActiveBullets) 
				end
				delete(i, currentActiveBullets)
				currentActiveBullets -= 1
				i -= 1	
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


function updateBullets(dt, mainTimePassed)
	-- Get run-time variables
	theCurrTime = playdate.getCurrentTimeMilliseconds()
	playerPos = getPlayerPosition()
	
	-- Bullet Handling
	playdate.resetElapsedTime()
		handleCreatingBullets()
	getCreateTimer()
	
	playdate.resetElapsedTime()	
		updateBulletLists(dt)
	getUpdateTimer()

	-- DEBUGGING
	debugImage:clear(gfx.kColorWhite)
	gfx.pushContext(debugImage)
		gfx.setColor(gfx.kColorWhite)
		gfx.drawRect(0, 0, 140, 150)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawText(" Cur C: " .. 1000*currentCreateTimer, 0, 0)
		gfx.drawText(" Update Timer: " .. 1000*currentUpdateTimer, 0, 25)
		--gfx.drawText("Max Bullets: " .. #bulletType, 0, 75)
		gfx.drawText("Max Bullets: " .. tempMaxBullets[tempMaxBulletsIndex], 0, 75)
		gfx.drawText("Active Bullets: " .. activeBullets, 0, 100)
		gfx.drawText("FPS: " .. playdate.getFPS(), 0, 125)
		gfx.drawText("Main Time:" .. mainTimePassed, 0, 150)
	gfx.popContext()
	debugSprite:setImage(debugImage)
	debugSprite:add()
	-----

end