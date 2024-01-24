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

local theCurrTime = 0
local playerPos = vec.new(0, 0)

-- Bullet Type Variables --
-- Index position is the gun type - this list returns the speed for each gun type.
local BULLET_SPEEDS = {
	0, -- none
	4, -- peagun
	8, -- cannon
	2, -- minigun
	3, -- shotgun
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
local bulletLifetime <const> = 3000 --1500
local maxBullets <const> = 500 -- max that can exist in the world at one time
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
local theGunSlots = {BULLET_TYPE.shotgun, BULLET_TYPE.shotgun, BULLET_TYPE.shotgun, BULLET_TYPE.shotgun} --what gun in each slot
local theGunLogic = {0, 0, 0, 0} --what special logic that slotted gun needs
local theGunTier = {3, 3, 3, 3} -- what tier the gun is at


-----------
-- Debug --
local maxCreateTimer = 0
local maxUpdateTimer = 0
local maxDrawTimer = 0
local minFPS = 100
local allowBulletCollisions = true
-----------
-----------


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


-- Create a bullet at the end of the list
local function createBullet(type, spawnX, spawnY, newRotation, newTier)
	if activeBullets >= maxBullets then do return end end -- if too many bullets exist, then don't make another bullet
	if type == BULLET_TYPE.none then do return end end

	activeBullets += 1
	addShot()
	local direction = vec.newPolar(1, newRotation)

	bulletType[activeBullets] = type
	posX[activeBullets] = spawnX
	posY[activeBullets] = spawnY
	rotation[activeBullets] = newRotation
	scale[activeBullets] = 1
	dirX[activeBullets] = direction.x
	dirY[activeBullets] = direction.y 
	speed[activeBullets] = BULLET_SPEEDS[type] * getPlayerBulletSpeed()
	lifeTime[activeBullets] = theCurrTime + bulletLifetime
	knockback[activeBullets] = BULLET_KNOCKBACKS[type]
	peircing[activeBullets] = BULLET_PEIRCING[type]
	tier[activeBullets] = newTier
	mode[activeBullets] = 0
	timer[activeBullets] = 0

	if type == BULLET_TYPE.cannon then
		damage[activeBullets] = 3 + getPlayerGunDamage() * (1 + newTier)
		scale[activeBullets] = newTier

	elseif type == BULLET_TYPE.minigun then
		damage[activeBullets] = 1 + math.ceil(getPlayerGunDamage() / 2)

	elseif type == BULLET_TYPE.shotgun then
		damage[activeBullets] = 1 + math.floor(getPlayerGunDamage() / 2) --round down

	elseif type == BULLET_TYPE.burstgun then
		damage[activeBullets] = 1 + getPlayerGunDamage()

	elseif type == BULLET_TYPE.grenade then
		damage[activeBullets] = 2 + getPlayerGunDamage()
		lifeTime[activeBullets] = theCurrTime + 1000

	elseif type == BULLET_TYPE.ranggun then
		damage[activeBullets] = 1 + math.floor(getPlayerGunDamage() / 3)
		lifeTime[activeBullets] = theCurrTime + 6000
		scale[activeBullets] = newTier

	elseif type == BULLET_TYPE.wavegun then
		damage[activeBullets] = 4 + getPlayerGunDamage()

	elseif type == BULLET_TYPE.grenadePellet then
		damage[activeBullets] = 1 + math.floor(getPlayerGunDamage() / 2)

	else -- peagun
		damage[activeBullets] = 1 + getPlayerGunDamage()

	end
end


local function createGrenadePellets(index)
	local grenadeX = posX[index]
	local grenadeY = posY[index]
	local grenadeTier = tier[index]
	local amount = 4 + (4 * grenadeTier)
	local degree = math.floor(360/amount)
	local newRotation = 0
	for i = 1, amount do
		newRotation += degree
		createBullet(BULLET_TYPE.grenadePellet, grenadeX, grenadeY, newRotation, grenadeTier)
	end
end


local function deleteBullet(index)
	-- overwrite the to-be-deleted bullet with the bullet at the end
	bulletType[index] = bulletType[activeBullets]
	posX[index] = posX[activeBullets]
	posY[index] = posY[activeBullets]
	rotation[index] = rotation[activeBullets]
	scale[index] = scale[activeBullets]
	dirX[index] = dirX[activeBullets]
	dirY[index] = dirY[activeBullets]
	speed[index] = speed[activeBullets]
	lifeTime[index] = lifeTime[activeBullets]
	damage[index] = damage[activeBullets]
	knockback[index] = knockback[activeBullets]
	tier[index] = tier[activeBullets]
	mode[index] = mode[activeBullets]
	timer[index] = timer[activeBullets]

	-- set the last bullet to NONE and reduce active bullets (effectively deletes the bullet)
	bulletType[activeBullets] = BULLET_TYPE.none
	activeBullets -= 1
end


local function handleCreatingBullets()
	local playerRot = getCrankAngle()
	local playerAttackRate = getPlayerAttackRate()

	local currentBullet
	local slotAngle
	local gunTier
	local gunLogic

	-- for each gun slot, check the weapon and the shot time to see if a bullet can be created
	for iGunSlot = 1, #theGunSlots do

		currentBullet = theGunSlots[iGunSlot]
		slotAngle = playerRot + (90 * iGunSlot)
		gunTier = theGunTier[iGunSlot]
		gunLogic = theGunLogic[iGunSlot]

		if currentBullet > 0 then 
			if theShotTimes[iGunSlot] < theCurrTime then

				-- Set values for this type of bullet
				theShotTimes[iGunSlot] = theCurrTime + playerAttackRate * BULLET_ATTACKRATES[currentBullet]

				-- Cannon --
				if currentBullet == BULLET_TYPE.cannon then
					createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)				

				-- Minigun --
				elseif currentBullet == BULLET_TYPE.minigun then
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

				-- Shotgun --
				elseif currentBullet == BULLET_TYPE.shotgun then					
					createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle - 15, gunTier)
					createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle + 15, gunTier)

					if theGunTier[iGunSlot] > 1 then
						createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)
					end
					if theGunTier[iGunSlot] > 2 then
						createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle - 30, gunTier)
						createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle + 30, gunTier)
					end
				
				-- Burstgun --
				elseif currentBullet == BULLET_TYPE.burstgun then
					if gunLogic < 3 then
						theShotTimes[iGunSlot] = theCurrTime + 30
						theGunLogic[iGunSlot] += 1
						createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)

						if gunTier > 1 then 
							createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle - 7, gunTier)
						end
						if gunTier > 2 then
							createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle + 7, gunTier)
						end
					else
						theGunLogic[iGunSlot] = 0
					end
				
				-- Grenade --
				elseif currentBullet == BULLET_TYPE.grenade then
					createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)

				-- Ranggun --
				elseif currentBullet == BULLET_TYPE.ranggun then
					createBullet(currentBullet, playerPos.x, playerPos.y, slotAngle, gunTier)

				--[[
				-- Wavegun -- 
				elseif theGunSlots[sIndex] == BULLET_TYPE.wavegun then
					createBullet(playerPos, newRotation, (newLifeTime), theGunSlots[sIndex], sIndex, theGunTier[sIndex])
				]]--

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

]]--


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


local function moveBullet(i, dt)

	local moveX = (dirX[i] * speed[i] * dt)
	local moveY = (dirY[i] * speed[i] * dt)

	local startX = posX[i] - moveX
	local startY = posY[i] - moveY
	local endX = posX[i] + moveX
	local endY = posY[i] + moveY

	if allowBulletCollisions == true then 
		handleCollision(i, startX, startY, endX, endY)
	end
	
	posX[i] += moveX
	posY[i] += moveY
end


-- +--------------------------------------------------------------+
-- |                           Management                         |
-- +--------------------------------------------------------------+

--[[

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


local function updateBulletLists(dt)
	for i = 1, activeBullets do
		if bulletType[i] ~= BULLET_TYPE.none then
			calculateMoveChanges(i)
			moveBullet(i, dt)

			if theCurrTime >= lifeTime[i] then
				if bulletType[i] == BULLET_TYPE.grenade then createGrenadePellets(i) end
				deleteBullet(i)
				i -= 1				
			end
		end
	end
end


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
-- |                             Stats                            |
-- +--------------------------------------------------------------+


local function getCreateTimer()
	local elapsedTime = playdate.getElapsedTime()
	if maxCreateTimer < elapsedTime then 
		maxCreateTimer = elapsedTime
		print(" - Create: " .. maxCreateTimer)
	end
end


local function getUpdateTimer()
	local elapsedTime = playdate.getElapsedTime()
	if maxUpdateTimer < elapsedTime then
		maxUpdateTimer = elapsedTime
		print(" -- Update: " .. tostring(maxUpdateTimer))
	end
end


local function getDrawTimer()
	local elapsedTime = playdate.getElapsedTime()
	if maxDrawTimer < elapsedTime then
		maxDrawTimer = elapsedTime
		print(" --- Draw: " .. tostring(maxDrawTimer))
	end
end


local function getMinFPS()
	local currFPS = playdate.getFPS()
	if currFPS > 0 and currFPS < minFPS then
		minFPS = currFPS
		print("minFPS: " .. minFPS)
	end

	return minFPS
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
local bulletsSprite = gfx.sprite.new(bulletsImage)
bulletsSprite:setIgnoresDrawOffset(true)
bulletsSprite:setZIndex(ZINDEX.weapon)
bulletsSprite:moveTo(200, 120)


-- Draws a specific single bullet
local function drawSingleBullet(index, offsetX, offsetY)

	local type = bulletType[index]
	if type == BULLET_TYPE.none then -- if the bullet doesn't exist, don't draw it
		do return end
	end

	local imageID = type - 1
	local x = posX[index] + offsetX
	local y = posY[index] + offsetY
	local size = scale[index]
	local angle = rotation[index]
	local outsideScreen = false

	-- if image is too far outside the screen, don't draw it and delete it
	if x < -50 or x > 450 then outsideScreen = true end
	if y < -50 or y > 290 then outsideScreen = true end
	if outsideScreen == true then
		lifeTime[index] = 0
		do return end
	end

	--IMAGE_LIST[imageID]:draw(x, y)
	--IMAGE_LIST[imageID]:drawScaled(x, y, size)
	IMAGE_LIST[imageID]:drawRotated(x, y, angle, size)
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
end


-- Global to be called after level creation, b/c level start clears the sprite list
function addBulletSpriteToList()
	bulletsSprite:add()
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

--- DEBUG TEXT ---
local debugImage = gfx.image.new(160, 150, gfx.kColorWhite)
local debugSprite = gfx.sprite.new(debugImage)
debugSprite:setIgnoresDrawOffset(true)
debugSprite:moveTo(80, 80)
debugSprite:setZIndex(ZINDEX.uidetails)
------------------


function updateBullets(dt)
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

	playdate.resetElapsedTime()	
		drawBullets()
	getDrawTimer()
	


	-- DEBUGGING
	debugImage:clear(gfx.kColorWhite)
	gfx.pushContext(debugImage)
		gfx.setColor(gfx.kColorWhite)
		gfx.drawRect(0, 0, 140, 100)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawText(" Create Timer: " .. maxCreateTimer, 0, 0)
		gfx.drawText(" Update Timer: " .. maxUpdateTimer, 0, 25)
		gfx.drawText(" Draw Timer: " .. maxCreateTimer, 0, 50)
		gfx.drawText("Max Bullets: " .. #bulletType, 0, 75)
		gfx.drawText("Active Bullets: " .. activeBullets, 0, 100)
		gfx.drawText("FPS: " .. playdate.getFPS(), 0, 125)
	gfx.popContext()
	debugSprite:setImage(debugImage)
	debugSprite:add()
	-----

end