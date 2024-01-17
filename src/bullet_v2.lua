---
-- This file handles bullets as a SOA (structure-of-arrays).
-- Each array contains one part of the following data:
	-- bullet type
	-- position x
	-- position y
	-- direction x
	-- direction y
	-- speed
	-- rotation
	-- lifetime
	-- damage
	-- knockback
	-- tier
-- Bullets are all drawn onto 


local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local queryLine <const> = gfx.sprite.querySpritesAlongLine

local theCurrTime = 0

-- Bullet Sprites
--[[
local img_bulletCannon = gfx.image.new('Resources/Sprites/BulletCannon')
local img_bulletMinigun = gfx.image.new('Resources/Sprites/BulletMinigun')
local img_bulletPeagun = gfx.image.new('Resources/Sprites/BulletPeagun')
local img_bulletShotgun = gfx.image.new('Resources/Sprites/BulletShotgun')
local img_bulletBurstGun = gfx.image.new('Resources/Sprites/BulletBurstgun')
local img_bulletGrenade = gfx.image.new('Resources/Sprites/BulletGrenade')
local img_bulletRanggun = gfx.image.new('Resources/Sprites/BulletRanggun')
local img_bulletWavegun = gfx.image.new('Resources/Sprites/BulletWavegun')
local img_bulletGrenadePellet = gfx.image.new('Resources/Sprites/BulletGrenadePellet')
]]--

class('bullet').extends(gfx.sprite)

-- Bullet Types
local BULLET_TYPE = {
	none = 1,
	peagun = 2,
	cannon = 3,
	minigun = 4,
	shotgun = 5,
	burstgun = 6,
	grenade = 7,
	ranggun = 8,
	wavegun = 9,
	grenadePellet = 10
}

-- Index position is the gun type - this list returns the speed for each gun type.
local BULLET_SPEEDS = {
	0, -- none
	4, -- peagun
	8, -- cannon
	2, -- minigun
	3, -- shotgun
	3, -- burstgun
	2, -- grenade
	2, -- ranggun
	1, -- wavegun
	2  -- grenadePellet
}

local BULLET_ATTACKRATES = {
	0, -- none
	2, -- peagun
	5, -- cannon
	1, -- minigun
	3, -- shotgun
	1, -- burstgun
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


local bulletLifetime <const> = 3000 --1500

local maxTimer = 0
local minFPS = 100

-- Bullets
local maxBullets <const> = 1000 -- max that can exist in the world at one time
local activeBullets = 0
--local calculateInterval <const> = 3 -- number of frames to skip for each movement calc
--local calculateOffset = 0 -- 0, 1, or 2. Determines which bullets from the interval that will be updated
--local calculateBullet = 1
--local bullets = {}
local bulletType = {}
local posX = {}
local posY = {}
local rotation = {}
local dirX = {}
local dirY = {}
local speed = {}
local lifeTime = {}
local damage = {}
local knockback = {}
local tier = {}

-- Gun Slots
local theShotTimes = {0, 0, 0, 0} --how long until next shot
local theGunSlots = {BULLET_TYPE.minigun, BULLET_TYPE.minigun, BULLET_TYPE.minigun, BULLET_TYPE.minigun} --what gun in each slot
local theGunLogic = {0, 0, 0, 0} --what special logic that slotted gun needs
local theGunTier = {3, 3, 3, 3} -- what tier the gun is at


-- +--------------------------------------------------------------+
-- |                 Init, Create, Delete, Set                    |
-- +--------------------------------------------------------------+

--- Init Arrays ---
for i = 1, maxBullets do
	bulletType[i] = BULLET_TYPE.none
	posX[i] = 0
	posY[i] = 0
	rotation[i] = 0
	dirX[i] = 0
	dirY[i] = 0
	speed[i] = 0
	lifeTime[i] = 0
	damage[i] = 0
	knockback[i] = 0
	tier[i] = 0
end


-- Create a bullet at the end of the list
local function createBullet(type, spawnX, spawnY, newRotation, newTier)
	if activeBullets >= maxBullets then do return end end -- if too many bullets exist, then don't make another bullet

	activeBullets += 1
	local direction = vec.newPolar(1, newRotation)

	bulletType[activeBullets] = type
	posX[activeBullets] = spawnX
	posY[activeBullets] = spawnY
	rotation[activeBullets] = newRotation
	dirX[activeBullets] = direction.x
	dirY[activeBullets] = direction.y 
	speed[activeBullets] = BULLET_SPEEDS[type] * getPlayerBulletSpeed()
	lifeTime[activeBullets] = theCurrTime + bulletLifetime
	knockback[activeBullets] = BULLET_KNOCKBACKS[type]
	tier[activeBullets] = newTier

	if type == BULLET_TYPE.cannon then
		damage[activeBullets] = 3 + getPlayerGunDamage() * (1 + newTier)

	elseif type == BULLET_TYPE.minigun then
		damage[activeBullets] = 1 + math.ceil(getPlayerGunDamage() / 2)

	elseif type == BULLET_TYPE.shotgun then
		damage[activeBullets] = 1 + math.floor(getPlayerGunDamage() / 2) --round down

	elseif type == BULLET_TYPE.burstgun then
		damage[activeBullets] = 1 + getPlayerGunDamage()

	elseif type == BULLET_TYPE.grenade then
		damage[activeBullets] = 2 + getPlayerGunDamage() 

	elseif type == BULLET_TYPE.ranggun then
		damage[activeBullets] = 1 + math.floor(getPlayerGunDamage() / 3)

	elseif type == BULLET_TYPE.wavegun then
		damage[activeBullets] = 4 + getPlayerGunDamage()

	elseif type == BULLET_TYPE.grenadePellet then
		damage[activeBullets] = 1 + math.floor(getPlayerGunDamage() / 2)

	else -- peagun
		damage[activeBullets] = 1 + getPlayerGunDamage()

	end
end


local function deleteBullet(index)
	-- overwrite the to-be-deleted bullet with the bullet at the end
	bulletType[index] = bulletType[activeBullets]
	posX[index] = posX[activeBullets]
	posY[index] = posY[activeBullets]
	rotation[index] = rotation[activeBullets]
	dirX[index] = dirX[activeBullets]
	dirY[index] = dirY[activeBullets]
	speed[index] = speed[activeBullets]
	lifeTime[index] = lifeTime[activeBullets]
	damage[index] = damage[activeBullets]
	knockback[index] = knockback[activeBullets]
	tier[index] = tier[activeBullets]

	-- set the last bullet to NONE and reduce active bullets (effectively deletes the bullet)
	bulletType[activeBullets] = BULLET_TYPE.none
	lifeTime[activeBullets] = 0
	activeBullets -= 1
end


--[[
-- Set an existing bullet with new data
function bullet:set(x, y, rotation, newLifeTime, type, index, tier)
	bullet.super.init(self)
	self:setScale(1) -- reset the sprite scale from the previous bullet

	if type == BULLET_TYPE.cannon then
		self:setImage(img_bulletCannon:copy())
		self.speed = getPlayerBulletSpeed() * 8
		self.damage = 3 + getPlayerGunDamage() * (1 + tier)
		self.knockback = 4
		self:setScale(tier)

	elseif type == BULLET_TYPE.minigun then
		self:setImage(img_bulletMinigun:copy())
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.ceil(getPlayerGunDamage() / 2) --round up
		self.knockback = 0

	elseif type == BULLET_TYPE.shotgun then
		self:setImage(img_bulletShotgun:copy())
		self.speed = getPayerBulletSpeed() * 3
		self.damage = 1 + math.floor(getPlayerGunDamage() / 2) --round down
		self.knockback = 2

	elseif type == BULLET_TYPE.burstgun then
		self:setImage(img_bulletBurstGun:copy())
		self.speed = getPayerBulletSpeed() * 3
		self.damage = 1 + getPlayerGunDamage()
		self.knockback = 3

	elseif type == BULLET_TYPE.grenade then
		self:setImage(img_bulletGrenade:copy())
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 2 + getPlayerGunDamage()
		self.knockback = 0

	elseif type == BULLET_TYPE.ranggun then
		self:setImage(img_bulletRanggun:copy())
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.floor(getPlayerGunDamage() / 3)
		self.knockback = 1
		self:setScale(tier)

	elseif type == BULLET_TYPE.wavegun then
		self:setImage(img_bulletWavegun:copy())
		self.speed = getPayerBulletSpeed()
		self.damage = 4 + getPlayerGunDamage()
		self.knockback = 0

	elseif type == BULLET_TYPE.grenadePellet then
		self:setImage(img_bulletGrenadePellet:copy())
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.floor(getPlayerGunDamage() / 2)
		self.knockback = 0

	else
		self:setImage(img_bulletPeagun:copy())
		self.speed = getPayerBulletSpeed() * 4
		self.damage = 1 + getPlayerGunDamage()
		self.knockback = 0
	end
	
	self:moveTo(x, y)
	self:setRotation(rotation)	
	self:setCollideRect(0, 0, self:getSize())
	self.direction = vec.newPolar(1, rotation)
	self.mode = 0
	self.type = type
	--self.index = index
	self.lifeTime = newLifeTime
	self.timer = 0
	self.tier = tier
	addShot()

	-- Add this bullet to the sprite list
	self:add()
end
]]--

-- +--------------------------------------------------------------+
-- |                           Movement                           |
-- +--------------------------------------------------------------+

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
	

function bullet:calculateMove()
	-- Ranggun --
	if self.type == BULLET_TYPE.ranggun then
		-- Move in given direction
		if self.mode == 0 then 
			if (self.lifeTime - 5000) < theCurrTime then self.mode = 1 end

		-- Rotate over time
		elseif self.mode == 1 then
			local newRotation = self:getRotation() - 25
			self:setRotation(newRotation)
			self.direction = vec.newPolar(1, newRotation)
			if (self.lifeTime - 3000) < theCurrTime then self.mode = 2 end

		-- Return to player
		elseif self.mode == 2 then
			local playerPos = getPlayerPosition()
			self.direction = vec.new(playerPos.x - self.x, playerPos.y - self.y):normalized()
			local newRotation = 180 - self.direction:angleBetween(vec.new(0, 1))			
			self:setRotation(newRotation)
			local playerDistance = (playerPos - vec.new(self.x, self.y)):magnitudeSquared()	-- destroy self when close to player
			if playerDistance < 200 then self.lifeTime = 0 end
		end

	-- Wavegun --
	elseif self.type == BULLET_TYPE.wavegun then
		if self.lifeTime - 1300 + (200 * self.mode) < theCurrTime then 
			self.mode += 1
			if self.damage > 1 then self.damage = math.ceil(self.damage/2) end
			self:setScale(1 + self.mode/2 * self.tier, 1)
			self:setCollideRect(0, 0, self:getSize())
		end
	end
end

]]--


local function moveBullet(i, dt)

	local moveX = (dirX[i] * speed[i] * dt)
	local moveY = (dirY[i] * speed[i] * dt)

	local startX = posX[i] - moveX
	local startY = posY[i] - moveY
	local endX = posX[i] + moveX
	local endY = posY[i] + moveY

	-- loop through collisions to determine which to collide with
	local tag
	local collisionSprites = queryLine(startX, startY, endX, endY)
	for k = 1, #collisionSprites do
		tag = collisionSprites[k]:getTag()
		if tag == TAGS.enemy then
			lifeTime[i] = 0
			collisionSprites[k]:damage(damage[i])
			collisionSprites[k]:applyKnockback(knockback[i])
			do return end
		elseif tag == TAGS.walls then
			lifeTime[i] = 0
			do return end
		end
	end
	
	posX[i] += moveX
	posY[i] += moveY
end


-- +--------------------------------------------------------------+
-- |                           Management                         |
-- +--------------------------------------------------------------+

--[[
function spawnGrenadePellets(grenadeX, grenadeY, tier)
	local grenadePos = vec.new(grenadeX, grenadeY)
	local newLifeTime = theCurrTime + 1500
	local amount = 4 + (4 * tier)
	local degree = math.floor(360/amount)
	for i = amount,1,-1 do
		local newRotation = math.random(degree * (i - 1),degree * i)		
		createBullet(grenadePos, newRotation, newLifeTime, BULLET_TYPE.grenadePellet, 0)
	end
end


local function spawnBullets()

	local playerAttackRate = getPlayerAttackRate()
	local playerRot = player:getRotation()
	local newLifeTime = theCurrTime + 1500
	local playerPos = getPlayerPosition()

	for sIndex,theShotTime in pairs(theShotTimes) do
		if theGunSlots[sIndex] > 0 then
			if Unpaused then theShotTimes[sIndex] += theLastTime end
			if theCurrTime >= theShotTime then
				local newRotation = playerRot + (90 * sIndex)	-- update rotation for the given gun slot
				
				-- Cannon --
				if theGunSlots[sIndex] == BULLET_TYPE.cannon then
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 5
					createBullet(playerPos, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

				-- Minigun --
				elseif theGunSlots[sIndex] == BULLET_TYPE.minigun then
					theShotTimes[sIndex] = theCurrTime + playerAttackRate
					createBullet(playerPos, newRotation + math.random(-8, 8), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

					if theGunTier[sIndex] > 1 then
						createBullet(playerPos, newRotation + math.random(9, 16), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					end
					if theGunTier[sIndex] > 2 then
						createBullet(playerPos, newRotation - math.random(9, 16), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					end

				-- Shotgun --
				elseif theGunSlots[sIndex] == BULLET_TYPE.shotgun then
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 3
					createBullet(playerPos, newRotation + math.random(-8, 8), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					createBullet(playerPos, newRotation + math.random(16, 25), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					createBullet(playerPos, newRotation - math.random(16, 25), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

					if theGunTier[sIndex] > 1 then
						createBullet(playerPos, newRotation + math.random(26, 35), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						createBullet(playerPos, newRotation - math.random(26, 35), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					end
					if theGunTier[sIndex] > 2 then
						createBullet(playerPos, newRotation + math.random(9, 15), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						createBullet(playerPos, newRotation - math.random(9, 15), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					end

				-- Burstgun --
				elseif theGunSlots[sIndex] == BULLET_TYPE.burstgun then
					if theGunLogic[sIndex] < 3 then
						theShotTimes[sIndex] = theCurrTime + playerAttackRate
						createBullet(playerPos, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

						theGunLogic[sIndex] += 1
						if theGunTier[sIndex] > 1 then
							createBullet(playerPos, newRotation + 7, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

						end
						if theGunTier[sIndex] > 2 then
							createBullet(playerPos, newRotation - 7, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

						end
					else
						theShotTimes[sIndex] = theCurrTime + playerAttackRate * 3
						theGunLogic[sIndex] = 0
					end

				-- Grenade --
				elseif theGunSlots[sIndex] == BULLET_TYPE.grenade then
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 7
					createBullet(playerPos, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

				-- Ranggun --
				elseif theGunSlots[sIndex] == BULLET_TYPE.ranggun then
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 6
					createBullet(playerPos, newRotation, (newLifeTime + 4500), theGunSlots[sIndex], sIndex, theGunTier[sIndex])
	
				-- Wavegun -- 
				elseif theGunSlots[sIndex] == BULLET_TYPE.wavegun then
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 3
					createBullet(playerPos, newRotation, (newLifeTime), theGunSlots[sIndex], sIndex, theGunTier[sIndex])

				-- Peagun
				else
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 2
					createBullet(playerPos, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

					if theGunTier[sIndex] > 1 then
						local tempVec = (vec.newPolar(1, newRotation):leftNormal() * 10) + playerPos
						createBullet(tempVec, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

					end
					if theGunTier[sIndex] > 2 then
						local tempVec = (vec.newPolar(1, newRotation):rightNormal() * 10) + playerPos
						createBullet(tempVec, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

					end
				end

			end
		end
	end
end


local function updateBulletsList(dt)
	-- Determine the intervals of bullets that will be updated
	calculateBullet = math.min((1 + calculateOffset), activeBullets) 	-- start interval at beginning of list with offset,
	calculateOffset = (1 + calculateOffset) % calculateInterval 		-- and increase the offset; repeats cycles of 0, 1, 2

	-- Update all bullets
	for i = 1, #bullets do	
		if i > activeBullets then return end 	-- when the end of the active bullets list is reached, end the loop
		if bullets[i].type == BULLET_TYPE.none then -- if attempting to access a destroyed bullet, end the loop
			print("updating empty bullet -- abort")
			return 
		end

		-- Update every interval
		if calculateBullet <= activeBullets then
			bullets[calculateBullet]:calculateMove()
			calculateBullet += calculateInterval	-- increase the interval
		end			

		-- Update every frame
		bullets[i]:move(dt)
		
		if Unpaused then bullets[i].lifeTime += theLastTime end
		if theCurrTime >= bullets[i].lifeTime then
			if bullets[i].type == 6 then spawnGrenadePellets(bullets[i].x, bullets[i].y, bullets[i].tier) end
			bulletSwapRemove(i)
		end
	end
end
]]--


local function handleCreatingBullets()
	local playerPos = getPlayerPosition()
	local playerRot = getCrankAngle()
	local playerAttackRate = getPlayerAttackRate()

	local currentBullet
	local slotAngle
	local gunTier

	-- for each gun slot, check the weapon and the shot time to see if a bullet can be created
	for iGunSlot = 1, #theGunSlots do

		currentBullet = theGunSlots[iGunSlot]
		slotAngle = playerRot + (90 * iGunSlot)
		gunTier = theGunTier[iGunSlot]

		if currentBullet > 0 then 
			if theShotTimes[iGunSlot] < theCurrTime then
				-- Set values for this type of bullet
				theShotTimes[iGunSlot] = theCurrTime + playerAttackRate * BULLET_ATTACKRATES[currentBullet]

				-- Cannon --
				if theGunSlots[iGunSlot] == BULLET_TYPE.cannon then
					createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)

				--[[
				-- Shotgun --
				elseif theGunSlots[iGunSlot] == BULLET_TYPE.shotgun then
					createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)

					createBullet(playerPos, newRotation + math.random(-8, 8), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					createBullet(playerPos, newRotation + math.random(16, 25), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					createBullet(playerPos, newRotation - math.random(16, 25), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])

					if theGunTier[iGunSlot] > 1 then
						createBullet(playerPos, newRotation + math.random(26, 35), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						createBullet(playerPos, newRotation - math.random(26, 35), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					end
					if theGunTier[iGunSlot] > 2 then
						createBullet(playerPos, newRotation + math.random(9, 15), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						createBullet(playerPos, newRotation - math.random(9, 15), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					end
				]]--

				-- Minigun --
				elseif theGunSlots[iGunSlot] == BULLET_TYPE.minigun then
					local angleWiggle = math.random(-8, 8)
					createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle + angleWiggle, gunTier)
					if gunTier > 1 then
						angleWiggle = math.random(9, 16)
						createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle + angleWiggle, gunTier)
					end
					if gunTier > 2 then
						angleWiggle = math.random(9, 16)
						createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle - angleWiggle, gunTier)
					end

				-- Peagun
				else
					createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)
					if gunTier > 1 then
						local tempVec = (vec.newPolar(1, slotAngle):leftNormal() * 10) + playerPos
						createBullet(currentBullet, tempVec.x, tempVec.y, slotAngle, gunTier)
					end
					if gunTier > 2 then
						local tempVec = (vec.newPolar(1, slotAngle):rightNormal() * 10) + playerPos
						createBullet(currentBullet, tempVec.x, tempVec.y, slotAngle, gunTier)
					end
				end

			end
		end
	end
end


local function updateBulletLists(dt)
	for i = 1, activeBullets do
		if bulletType[i] ~= BULLET_TYPE.none then
			moveBullet(i, dt)

			if theCurrTime >= lifeTime[i] then
				deleteBullet(i)
				i -= 1
			end
		end
	end
end


function clearBullets()
	for i = 1, #bullets do
		bulletType[i] = BULLET_TYPE.none
		lifeTime[i] = 0
	end

	activeBullets = 0
end


-- +--------------------------------------------------------------+
-- |                             Stats                            |
-- +--------------------------------------------------------------+


function getTimerMax()
	local elapsedTime = playdate.getElapsedTime()
	local calcTimer = math.max(elapsedTime, maxTimer)
	if maxTimer < calcTimer then
		maxTimer = calcTimer
		print("new max timer: " .. tostring(maxTimer))
	end
end


function getMinFPS()
	local currFPS = playdate.getFPS()
	if currFPS > 0 and currFPS < minFPS then
		minFPS = currFPS
		print("minFPS: " .. minFPS)
	end

	return minFPS
end


function getEquippedGun(weapon)
	return theGunSlots[weapon]
end


function getTierForGun(tier)
	return theGunTier[tier]
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

--[[
-- Prints a list of the bullets created in the table and their current bullet type. BULLET_TYPE.none is 0.
function printBulletList()
	print(" -- active bullets: " .. activeBullets .. " --")
	print("length of list: " .. #bullets)
	for i = 1, #bullets do
		if bullets[i] == nil then 
			print(" -- end of bullet list -- ") 
			break
		end
		print("bullet type: " .. tostring(bullets[i].type))
	end
end
]]--

function clearGunStats()
	theShotTimes = {0, 0, 0, 0}
	theGunSlots = {1, 0, 0, 0}
	theGunLogic = {0, 0, 0, 0}
	theGunTier = {1, 0, 0, 0}
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


local bulletsImage = gfx.image.new(400, 240) -- screen size draw
local bulletsSprite = gfx.sprite.new(bulletsImage)
bulletsSprite:setIgnoresDrawOffset(true)
bulletsSprite:setZIndex(ZINDEX.weapon)
bulletsSprite:moveTo(200, 120)


-- Draws a specific single bullet
local function drawSingleBullet(index, offsetX, offsetY)

	local type = bulletType[index]
	local x = posX[index] + offsetX
	local y = posY[index] + offsetY
	local rot = rotation[index]
	local outsideScreen = false

	-- if image is too far outside the screen, don't draw it
	if x < -50 or x > 450 then outsideScreen = true end
	if y < -50 or y > 290 then outsideScreen = true end
	if outsideScreen == true then
		lifeTime[index] = 0
		-- delete bullet
		do return end
	end

	-- if the bullet doesn't exist, don't draw it
	if type == BULLET_TYPE.none then do return end	

	elseif type == BULLET_TYPE.peagun then img_bulletPeagun:draw(x, y)
	elseif type == BULLET_TYPE.cannon then img_bulletCannon:draw(x, y)	
	elseif type == BULLET_TYPE.minigun then img_bulletMinigun:draw(x, y)	
	elseif type == BULLET_TYPE.shotgun then img_bulletShotgun:draw(x, y)
	elseif type == BULLET_TYPE.burstgun then img_bulletBurstGun:draw(x, y)
	elseif type == BULLET_TYPE.grenade then img_bulletGrenade:draw(x, y)
	elseif type == BULLET_TYPE.ranggun then img_bulletRanggun:draw(x, y)
	elseif type == BULLET_TYPE.wavegun then img_bulletWavegun:draw(x, y)
	elseif type == BULLET_TYPE.grenadePellet then img_bulletGrenadePellet:draw(x, y)

--[[
	elseif type == BULLET_TYPE.peagun then img_bulletPeagun:drawRotated(x, y, rot)
	elseif type == BULLET_TYPE.cannon then img_bulletCannon:drawRotated(x, y, rot)	
	elseif type == BULLET_TYPE.minigun then img_bulletMinigun:drawRotated(x, y, rot)	
	elseif type == BULLET_TYPE.shotgun then img_bulletShotgun:drawRotated(x, y, rot)
	elseif type == BULLET_TYPE.burstgun then img_bulletBurstGun:drawRotated(x, y, rot)
	elseif type == BULLET_TYPE.grenade then img_bulletGrenade:drawRotated(x, y, rot)
	elseif type == BULLET_TYPE.ranggun then img_bulletRanggun:drawRotated(x, y, rot)
	elseif type == BULLET_TYPE.wavegun then img_bulletWavegun:drawRotated(x, y, rot)
	elseif type == BULLET_TYPE.grenadePellet then img_bulletGrenadePellet:drawRotated(x, y, rot)
]]--
	end
end


-- Draws all bullets to a screen-sized sprite in one push context
local function drawBullets()	

	bulletsImage:clear(gfx.kColorClear)
	local offX, offY = gfx.getDrawOffset()

	-- Create the new bullets image
	--if activeBullets > 0 then
		gfx.pushContext(bulletsImage)
			-- set details
			gfx.setColor(gfx.kColorBlack)

			-- loop through and draw each bullet
			for i = 1, activeBullets do
				drawSingleBullet(i, offX, offY)
			end
		gfx.popContext()
	--end

	-- Draw the new bullets sprite
	bulletsSprite:setImage(bulletsImage)
	bulletsSprite:add()
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

--- DEBUG TEXT ---
local debugImage = gfx.image.new(140, 100, gfx.kColorWhite)
local debugSprite = gfx.sprite.new(debugImage)
debugSprite:setIgnoresDrawOffset(true)
debugSprite:moveTo(80, 80)
debugSprite:setZIndex(ZINDEX.uidetails)
------------------

function updateBullets(dt, frame)
	theCurrTime = playdate.getCurrentTimeMilliseconds()

	
	handleCreatingBullets()
	
	
	playdate.resetElapsedTime()	
		updateBulletLists(dt)
	getTimerMax()

	drawBullets()
	
	--[[
	-- DEBUGGING
	debugImage:clear(gfx.kColorWhite)
	gfx.pushContext(debugImage)
		gfx.setColor(gfx.kColorWhite)
		gfx.drawRect(0, 0, 140, 100)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawText("timer: " .. maxTimer, 0, 0)
		gfx.drawText("list size: " .. #bulletType, 0, 25)
		gfx.drawText("cur fps: " .. playdate.getFPS(), 0, 50)
		gfx.drawText("min fps: " .. getMinFPS(), 0, 75)
	gfx.popContext()
	debugSprite:setImage(debugImage)
	debugSprite:add()
	-----
	]]--
end