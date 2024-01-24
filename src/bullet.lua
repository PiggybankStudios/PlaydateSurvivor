--[[
local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local theCurrTime = 0

-- Bullet Sprites
local spr_bulletCannon = gfx.image.new('Resources/Sprites/BulletCannon')
local spr_bulletMinigun = gfx.image.new('Resources/Sprites/BulletMinigun')
local spr_bulletPeagun = gfx.image.new('Resources/Sprites/BulletPeagun')
local spr_bulletShotgun = gfx.image.new('Resources/Sprites/BulletShotgun')
local spr_bulletBurstGun = gfx.image.new('Resources/Sprites/BulletBurstgun')
local spr_bulletGrenade = gfx.image.new('Resources/Sprites/BulletGrenade')
local spr_bulletRanggun = gfx.image.new('Resources/Sprites/BulletRanggun')
local spr_bulletWavegun = gfx.image.new('Resources/Sprites/BulletWavegun')
local spr_bulletGrenadePellet = gfx.image.new('Resources/Sprites/BulletGrenadePellet')

class('bullet').extends(gfx.sprite)

-- Bullet Types
local BULLET_TYPE = {
	none = 0,
	peagun = 1,
	cannon = 2,
	minigun = 3,
	shotgun = 4,
	burstgun = 5,
	grenade = 6,
	ranggun = 7,
	wavegun = 8,
	grenadePellet = 9
}

local maxTimer = 0
local minFPS = 100

-- Bullets
local maxBullets <const> = 400 -- max that can exist in the world at one time
local activeBullets = 0
local calculateInterval <const> = 3 -- number of frames to skip for each movement calc
local calculateOffset = 0 -- 0, 1, or 2. Determines which bullets from the interval that will be updated
local calculateBullet = 1
local bullets = {}

--setmetatable(bullets, {__mode = "k"})	-- Sets a weak link to values, indicating a "weak table." 
										-- Once these objects lose their connections, then they'll be collected for garbage.

local theShotTimes = {0, 0, 0, 0} --how long until next shot
local theGunSlots = {BULLET_TYPE.minigun, BULLET_TYPE.minigun, BULLET_TYPE.minigun, BULLET_TYPE.minigun} --what gun in each slot
local theGunLogic = {0, 0, 0, 0} --what special logic that slotted gun needs
local theGunTier = {3, 3, 3, 3} -- what tier the gun is at


-- +--------------------------------------------------------------+
-- |                    Create, Delete, Set                       |
-- +--------------------------------------------------------------+


-- Creates an empty bullet template
function bullet:init()
	bullet.super.init(self)

	self.type = BULLET_TYPE.none

	self:setTag(TAGS.weapon)
	self:setGroups(GROUPS.weapon)
	self:setCollidesWithGroups(GROUPS.walls)
	self:setZIndex(ZINDEX.weapon)

	self.speed = 0
	self.damage = 0
	self.knockback = 0

	self.mode = 0
	self.index = 0
	self.lifeTime = 0
	self.timer = 0
	self.tier = 1
end


local function createBullet(pos, rotation, newLifeTime, type, index, tier)
	if activeBullets == maxBullets then
		--print(" -- max bullets reached - cannot create new bullet.")
		do return end
	end

	-- increase active bullets and see if this new last is nil or an existing template
	activeBullets += 1

	-- if nil, create a template
	if bullets[activeBullets] == nil then
		bullets[activeBullets] = bullet()
	end

	-- set the template with new data
	bullets[activeBullets]:set(pos.x, pos.y, rotation, newLifeTime, type, index, tier)
end


-- Set an existing bullet with new data
function bullet:set(x, y, rotation, newLifeTime, type, index, tier)
	bullet.super.init(self)
	self:setScale(1) -- reset the sprite scale from the previous bullet

	if type == BULLET_TYPE.cannon then
		self:setImage(spr_bulletCannon:copy())
		self.speed = getPayerBulletSpeed() * 8
		self.damage = 3 + getPlayerGunDamage() * (1 + tier)
		self.knockback = 4
		self:setScale(tier)

	elseif type == BULLET_TYPE.minigun then
		self:setImage(spr_bulletMinigun:copy())
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.ceil(getPlayerGunDamage() / 2) --round up
		self.knockback = 0

	elseif type == BULLET_TYPE.shotgun then
		self:setImage(spr_bulletShotgun:copy())
		self.speed = getPayerBulletSpeed() * 3
		self.damage = 1 + math.floor(getPlayerGunDamage() / 2) --round down
		self.knockback = 2

	elseif type == BULLET_TYPE.burstgun then
		self:setImage(spr_bulletBurstGun:copy())
		self.speed = getPayerBulletSpeed() * 3
		self.damage = 1 + getPlayerGunDamage()
		self.knockback = 3

	elseif type == BULLET_TYPE.grenade then
		self:setImage(spr_bulletGrenade:copy())
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 2 + getPlayerGunDamage()
		self.knockback = 0

	elseif type == BULLET_TYPE.ranggun then
		self:setImage(spr_bulletRanggun:copy())
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.floor(getPlayerGunDamage() / 3)
		self.knockback = 1
		self:setScale(tier)

	elseif type == BULLET_TYPE.wavegun then
		self:setImage(spr_bulletWavegun:copy())
		self.speed = getPayerBulletSpeed()
		self.damage = 4 + getPlayerGunDamage()
		self.knockback = 0

	elseif type == BULLET_TYPE.grenadePellet then
		self:setImage(spr_bulletGrenadePellet:copy())
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.floor(getPlayerGunDamage() / 2)
		self.knockback = 0

	else
		self:setImage(spr_bulletPeagun:copy())
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


-- +--------------------------------------------------------------+
-- |                           Movement                           |
-- +--------------------------------------------------------------+


function bullet:collisionResponse(other)
	self.lifeTime = 0
	return 'overlap'
	--
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
	--
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


function bullet:move(dt)
	playdate.resetElapsedTime()

	local x = self.x + self.direction.x * self.speed * dt
	local y = self.y + self.direction.y * self.speed * dt
	self:moveWithCollisions(x, y) -- need to check collisions, find the point a collision would happen, move there, then delete
	--self:moveTo(x, y)

	getTimerMax()
end


-- +--------------------------------------------------------------+
-- |                           Management                         |
-- +--------------------------------------------------------------+


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


-- Swaps the given bullet with the last in the list, indicates it to be reused, and removes it from the sprite list. 
-- NOTE: The bullet still exists in the bullets list. We're recycling it this way.
function bulletSwapRemove(index)
	-- save the last bullet in the list
	local tempBullet = bullets[activeBullets]

	-- swap the to-be-deleted bullet with the bullet at the end
	bullets[activeBullets] = bullets[index]
	bullets[activeBullets].type = BULLET_TYPE.none 	-- lets us know we can recycle this bullet in the future
	bullets[activeBullets]:remove()					-- remove the bullet from the sprite list
	bullets[index] = tempBullet

	-- decrease the active bullet count
	activeBullets -= 1
end


function clearBullets()
	for i = 1, #bullets do
		bullets[i].type = BULLET_TYPE.none
		bullets[i]:remove()
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


function getBulletsListLength()
	return #bullets
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


function clearGunStats()
	theShotTimes = {0, 0, 0, 0}
	theGunSlots = {1, 0, 0, 0}
	theGunLogic = {0, 0, 0, 0}
	theGunTier = {1, 0, 0, 0}
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


local debugImage = gfx.image.new(140, 100, gfx.kColorWhite)
local debugSprite = gfx.sprite.new(deadImage)
debugSprite:setIgnoresDrawOffset(true)
debugSprite:moveTo(80, 80)
debugSprite:setZIndex(ZINDEX.uidetails)


function updateBullets(dt, frame)
	theCurrTime = playdate.getCurrentTimeMilliseconds()

	spawnBullets()
	updateBulletsList(dt, frame)

	
	debugImage:clear(gfx.kColorWhite)
	gfx.pushContext(debugImage)
		gfx.setColor(gfx.kColorWhite)
		gfx.drawRect(0, 0, 140, 100)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawText("timer: " .. maxTimer, 0, 0)
		gfx.drawText("list size: " .. #bullets, 0, 25)
		gfx.drawText("cur fps: " .. playdate.getFPS(), 0, 50)
		gfx.drawText("min fps: " .. getMinFPS(), 0, 75)
	gfx.popContext()
	debugSprite:setImage(debugImage)
	debugSprite:add()
	
end

]]--