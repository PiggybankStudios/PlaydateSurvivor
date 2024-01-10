-- playdate screen 400 x 240
local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D


local healthbarOffsetY <const> = 30
local setDamageTimer <const> = 200
local halfScreenWidth <const> = playdate.display.getWidth() / 2
local halfScreenHeight <const> = playdate.display.getHeight() / 2

-- Sprite
playerSheet = gfx.imagetable.new('Resources/Sheets/player')
animationLoop = gfx.animation.loop.new(16, playerSheet)
player = gfx.sprite:new()
player:setZIndex(ZINDEX.player)
player:setImage(animationLoop:image())

-- Collider
local colliderSize <const> = 24
collider = gfx.sprite:new()
collider:setTag(TAGS.player)
collider:setSize(colliderSize, colliderSize)
collider:setCollideRect(0, 0, colliderSize, colliderSize)

-- stattrack
local damageDealt = 0
local damageReceived = 0
local experienceGained = 0
local enemiesKilled = 0
local shotsFired = 0
local itemsGrabbed = 0

-- difficulty
local difficulty = 1
local maxDifficulty = 15
local spawnInc = 0

-- Player
local playerLevel = 0
local maxHealth = 15
local health = maxHealth
local playerSpeed = 50
local playerAttackRate = 100
local playerAttackRateMin = 10 --limit
local playerExp = 0
local startingExpForLevel = 5
local playerMagnet = 50
local playerSlots = 1
local playerGunDamage = 1
local playerReflectDamage = 0
local playerExpBonus = 0
local playerLuck = 0
local playerLuckMax = 100 --limit
local playerBulletSpeed = 50
local playerArmor = 0
local playerDodge = 0
local playerDodgeMax = 90 --limit
local playerRunSpeed = 1
local playerVampire = 0
local playerVampireMax = 100 --limit
local playerHealBonus = 0
local playerStunChance = 0
local playerStunChanceMax = 100
local damageTimer = 0
local playerHealthbar
local playerExpbar
local gameStartTime = 0

-- ItemAbsorber
local absorbSpeed <const> = 30
local itemAbsorberRange = playerMagnet
itemAbsorber = gfx.sprite:new()
itemAbsorber:setTag(TAGS.itemAbsorber)
itemAbsorber:setSize(playerMagnet, playerMagnet)
itemAbsorber:setCollideRect(0, 0, playerMagnet, playerMagnet)

-- Bullets
bullets = {}
theShotTimes = {0, 0, 0, 0} --how long until next shot
theGunSlots = {1, 0, 0, 0} --what gun in each slot
theGunLogic = {0, 0, 0, 0} --what special logic that slotted gun needs
theGunTier = {3, 0, 0, 0} -- what tier the gun is at

-- Particles
particles = {}

-- Enemies
enemies = {}
theSpawnTime = 0

-- Items
items = {}
invincibleTime = 0
invincible = false

--Menu
Unpaused = false

-- +--------------------------------------------------------------+
-- |            Player Sprite and Collider Interaction            |
-- +--------------------------------------------------------------+

-- Add the player sprite and collider back to the drawing list after level load - also sets starting position
function addPlayerSpritesToList()
	player:setRotation(getCrankAngle())

	player:add()
	collider:add()
	itemAbsorber:add()
	health = maxHealth
	playerHealthbar = healthbar(player.x, player.y - healthbarOffsetY, health)
	playerExpbar = expbar(startingExpForLevel)
	movePlayerWithCollider(150,150) -- move to starting location
end


-- Moves both player sprite and collider - flooring stops jittering b/c only integers
function movePlayerWithCollider(x, y)
	local floorX = math.floor(x)
	local floorY = math.floor(y)
	player:moveTo(floorX, floorY)
	collider:moveTo(floorX, floorY)
	itemAbsorber:moveTo(floorX, floorY)
	playerHealthbar:moveTo(floorX, floorY - healthbarOffsetY)
end


function heal(amount)
	playerHealthbar:heal(amount + playerHealBonus)
	health = playerHealthbar:currentHP()
end

-- Damage player health - called via enemies
function player:damage(amount, camShakeStrength, enemyX, enemyY)
	if Unpaused then damageTimer += theLastTime end
	-- Invincibility
	if damageTimer > theCurrTime then
		return
	elseif invincible then
		return
	elseif math.random(0,99) < playerDodge then
		screenFlash()
		return
	end

	-- Damaging
	local amountLost = math.max(amount - playerArmor, 1)
	damageTimer = theCurrTime + setDamageTimer
	playerHealthbar:damage(amountLost)
	health = playerHealthbar:currentHP()
	addDamageReceived(amountLost)

	-- Camera Shake
	local playerPos = vec.new(player.x, player.y)
	local enemyPos = vec.new(enemyX, enemyY)
	local direction = (enemyPos - playerPos):normalized()
	cameraShake(camShakeStrength, direction)
	spawnParticles(PARTICLE_TYPE.impact, 5, direction)
	screenFlash()
end

function getPlayerSlots()
	return playerSlots
end

function updateSlots()
	playerSlots += 1
	if playerSlots > 4 then playerSlots = 4 
	else updateMenuWeapon(playerSlots,0)
	end
end

function updateLevel()
	playerLevel += 1
	openLevelUpMenu()
	setGameState(GAMESTATE.levelupmenu)
	if math.floor(playerLevel / 5) == playerSlots then
		updateSlots()
	end
	if math.floor(playerLevel / 3) == difficulty then
		if difficulty < maxDifficulty then difficulty += 1 end
	end
end

function addShot()
	shotsFired += 1
end

function addDamageDealt(amount)
	damageDealt += amount
end

function addDamageReceived(amount)
	damageReceived += amount
end

function addKill()
	enemiesKilled += 1
	if math.random(0,99) < playerVampire then heal(1) end
end

function addExpTotal(amount)
	experienceGained += amount
end

function addItemsGrabbed()
	itemsGrabbed += 1
end

function updateExp(currExp)
	playerExp = currExp
end

function updateExpfornextlevel(nextExp)
	startingExpForLevel = nextExp
end

-- +--------------------------------------------------------------+
-- |            Player get values section            |
-- +--------------------------------------------------------------+
function getPlayerx()
	return player.x
end

function getPlayery()
	return player.y
end

function getCurrTime()
	return theCurrTime
end

function getEquippedGun(weapon)
	return theGunSlots[weapon]
end

function getTierForGun(tier)
	return theGunTier[tier]
end

function getPlayerGunDamage()
	return playerGunDamage
end

function getPayerBulletSpeed()
	return playerBulletSpeed
end

function player:getPlayerReflectDamage()
	return playerReflectDamage
end

function getDifficulty()
	return difficulty
end

function getLuck()
	return playerLuck
end

function setRunSpeed(value)
	playerRunSpeed = value
end

function getStun()
	return playerStunChance
end

-- +--------------------------------------------------------------+
-- |            Player Stat Section            |
-- +--------------------------------------------------------------+

function upgradeStat(stat, bonus)
	if stat == 1 then
		playerArmor += bonus
		print('armor increased by ' .. tostring(bonus))
	elseif stat == 2 then
		playerAttackRate -= 5 * bonus
		if playerAttackRate < playerAttackRateMin then playerAttackRate = playerAttackRateMin end
		print('attack rate increased by ' .. tostring(5 * bonus))
	elseif stat == 3 then
		playerBulletSpeed += bonus
		print('bullet speed increased by ' .. tostring(bonus))
	elseif stat == 4 then
		playerGunDamage += bonus
		print('damage increased by ' .. tostring(bonus))
	elseif stat == 5 then
		playerDodge += 3 * bonus
		print('dodge increased by ' .. tostring(3 * bonus))
	elseif stat == 6 then
		playerExpBonus += bonus
		print('bonus exp increased by ' .. tostring(bonus))
	elseif stat == 7 then
		playerHealBonus += bonus
		print('heal increased by ' .. tostring(bonus))
	elseif stat == 8 then
		maxHealth += 2 * bonus
		playerHealthbar:updateMaxHealth(maxHealth)
		heal(2 * bonus)
		print('health increased by ' .. tostring(2 * bonus))
	elseif stat == 9 then
		playerLuck += 5 * bonus
		print('luck increased by ' .. tostring(5 * bonus))
	elseif stat == 10 then
		playerMagnet += 20 * bonus
		itemAbsorberRange = playerMagnet
		itemAbsorber:setSize(playerMagnet, playerMagnet)
		itemAbsorber:setCollideRect(0, 0, playerMagnet, playerMagnet)
		print('magnet increased by ' .. tostring(20 * bonus))
	elseif stat == 11 then
		playerReflectDamage += bonus
		print('reflect increased by ' .. tostring(bonus))
	elseif stat == 12 then
		playerSpeed += 5 * bonus
		print('speed increased by ' .. tostring(5 * bonus))
	elseif stat == 13 then
		playerVampire += 5 * bonus
		if playerVampire > playerVampireMax then playerVampire = playerVampireMax end
		print('vampire increased by ' .. tostring(5 * bonus))
	elseif stat == 14 then
		playerStunChance += 5 * bonus
		if playerStunChance > playerStunChanceMax then playerStunChance = playerStunChanceMax end
		print('vampire increased by ' .. tostring(5 * bonus))
	else
		print('error')
	end
	if math.random(0,99) < playerLuck then
		maxHealth += 1
		playerHealthbar:updateMaxHealth(maxHealth)
		heal(1)
		print('health increased by 1 bonus')
	end
end

function clearStats()
	damageDealt = 0
	damageReceived = 0
	experienceGained = 0
	enemiesKilled = 0
	shotsFired = 0
	itemsGrabbed = 0
	difficulty = 1
	maxDifficulty = 15
	spawnInc = 0
	playerLevel = 0
	maxHealth = 15
	health = maxHealth
	playerSpeed = 50
	playerAttackRate = 100
	playerExp = 0
	startingExpForLevel = 5
	playerMagnet = 50
	playerSlots = 1
	playerGunDamage = 1
	playerReflectDamage = 0
	playerExpBonus = 0
	playerLuck = 0
	playerBulletSpeed = 50
	playerArmor = 0
	playerDodge = 0
	playerRunSpeed = 1
	playerVampire = 0
	playerHealBonus = 0
	playerStunChance = 0
	damageTimer = 0
	theShotTimes = {0, 0, 0, 0}
	theGunSlots = {1, 0, 0, 0}
	theGunLogic = {0, 0, 0, 0}
	theGunTier = {1, 0, 0, 0}
	theSpawnTime = 0
	invincibleTime = 0
	invincible = false
	Unpaused = false
end

function getFinalStats()
	local stats = {}
	local survivedTime = math.floor((theLastTime - gameStartTime) / 1000)
	stats[#stats + 1] = difficulty
	stats[#stats + 1] = playerLevel
	stats[#stats + 1] = experienceGained
	stats[#stats + 1] = damageDealt
	stats[#stats + 1] = shotsFired
	stats[#stats + 1] = enemiesKilled
	stats[#stats + 1] = damageReceived
	stats[#stats + 1] = itemsGrabbed
	stats[#stats + 1] = survivedTime
	stats[#stats + 1] = (difficulty + playerLevel) * (experienceGained + itemsGrabbed + survivedTime)
	return stats
end

function getPlayerStats()
	local stats = {}
	stats[#stats + 1] = playerLevel
	stats[#stats + 1] = playerExp
	stats[#stats + 1] = startingExpForLevel
	stats[#stats + 1] = health
	stats[#stats + 1] = maxHealth
	stats[#stats + 1] = playerSpeed
	stats[#stats + 1] = playerAttackRate
	stats[#stats + 1] = playerMagnet
	stats[#stats + 1] = playerSlots
	stats[#stats + 1] = playerGunDamage
	stats[#stats + 1] = playerReflectDamage
	stats[#stats + 1] = playerExpBonus
	stats[#stats + 1] = playerLuck
	stats[#stats + 1] = playerBulletSpeed
	stats[#stats + 1] = playerArmor
	stats[#stats + 1] = playerDodge
	stats[#stats + 1] = playerHealBonus
	stats[#stats + 1] = playerVampire
	stats[#stats + 1] = playerStunChance
	return stats
end

function getAvailLevelUpStats()
	local stats = {}
	stats[#stats + 1] = "armor" --1 playerArmor
	if playerAttackRate > playerAttackRateMin then stats[#stats + 1] = "attrate" end --2 playerAttackRate
	stats[#stats + 1] = "bullspeed" --3 playerBulletSpeed
	stats[#stats + 1] = "damage" --4 playerGunDamage
	if playerDodge < playerDodgeMax then stats[#stats + 1] = "dodge" end --5 playerDodge
	stats[#stats + 1] = "exp" --6 playerExpBonus
	stats[#stats + 1] = "heal" --7 playerHealBonus
	stats[#stats + 1] = "health" --8 maxHealth
	if playerLuck < playerLuckMax then stats[#stats + 1] = "luck"	end --9 playerLuck
	stats[#stats + 1] = "magnet" --10 playerMagnet
	stats[#stats + 1] = "reflect" --11 playerReflectDamage
	stats[#stats + 1] = "speed" --12 playerSpeed
	if playerVampire < playerVampireMax then stats[#stats + 1] = "vampire" end --13 playerVampire
	if playerStunChance < playerStunChanceMax then stats[#stats + 1] = "stun" end --14 playerVampire
	return stats
end

function addEXP(amount)
	playerExpbar:gainExp(amount + playerExpBonus)
end

function incLuck()
	playerLuck += 5
	print('luck increased by 5')
	if playerLuck > playerLuckMax then 
		playerLuck = playerLuckMax
	end
end

function shield(amount)
	invincibleTime = theCurrTime + amount
	invincible = true
end


function newWeaponGrabbed(weapon, tier)
	setGameState(GAMESTATE.newweaponmenu)
	openWeaponMenu(weapon, tier)
end

function newWeaponChosen(weapon, slot, tier)
	theGunSlots[slot] = weapon
	theGunTier[slot] = tier
	updateMenuWeapon(slot, weapon)
end


function changeItemAbsorbRangeBy(value)
	itemAbsorberRange += value
	itemAbsorber:setSize(itemAbsorberRange, itemAbsorberRange)
	itemAbsorber:setCollideRect(0, 0, itemAbsorberRange, itemAbsorberRange)
end


function setItemAbsorbRange(value)
	itemAbsorberRange = value
	itemAbsorber:setSize(itemAbsorberRange, itemAbsorberRange)
	itemAbsorber:setCollideRect(0, 0, itemAbsorberRange, itemAbsorberRange)
end


-- Collision response based on tags
-- Player Collider
function collider:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.weapon then
		return "overlap"
	elseif tag == TAGS.item then
		other:itemGrab()
		return "overlap"
	elseif tag == TAGS.itemAbsorber then
		return "overlap"
	elseif tag == TAGS.enemy then
		return "overlap"
	else -- Any collision that's not set is defaulted to Wall Collision
		return "slide"
	end
end


-- Item Absorber Collider
function itemAbsorber:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.item then
		-- if already being mass attracted, skip this absorb movement
		if other:getMassAttraction() == true then
			return "overlap"
		end

		-- if not within a circular range of the player, skip
		local distance = vec.new(player.x, player.y) - vec.new(other.x, other.y)
		if distance:magnitude() > (itemAbsorberRange / 2) then
			return "overlap"
		end

		-- okay to apply absorb movement
		local dt = 1/20
		local dir = distance:normalized()
		local x = other.x + dir.x * absorbSpeed * dt
		local y = other.y + dir.y * absorbSpeed * dt
		other:moveTo(x, y)
		return "overlap"
	else 
		return "overlap"	-- only looking for item collisions, all others don't matter.
	end
end

-- +--------------------------------------------------------------+
-- |                            Input                             |
-- +--------------------------------------------------------------+
function movePlayer(dt)
	if collider == nil then return end	-- If the collider doesn't exist, then don't look for collisions

	-- Reset input to 0 if nothing is held
	if playdate.getButtonState() == 0 then resetInputXY() end

	local moveSpeed = playerSpeed * playerRunSpeed * dt
	local goalX = player.x + getInputX() * moveSpeed
	local goalY = player.y + getInputY() * moveSpeed

	-- The actual position is determined via collision response above
	local actualX, actualY, collisions = collider:checkCollisions(goalX, goalY)
	movePlayerWithCollider(actualX, actualY)
end


-- Checking for collisions with items to move them towards the player
function itemAbsorberCollisions()
	if itemAbsorber == nil then return end
	itemAbsorber:checkCollisions(player.x, player.y)
end


-- +--------------------------------------------------------------+
-- |                     Paraticle Management                     |
-- +--------------------------------------------------------------+


function spawnParticles(type, amount, direction)
	for i = 1, amount do
		newParticle = particle(player.x, player.y, type, theCurrTime, direction)
		particles[#particles + 1] = newParticle
	end
end


-- update function for moving particles and removing from particle list
local function updateParticles()
	for index, particle in pairs(particles) do
		particle:move(theCurrTime)
		if theCurrTime >= particle.lifeTime then
			particle:remove()
			table.remove(particles, index)
		end
	end
end

-- +--------------------------------------------------------------+
-- |                       Bullet Management                      |
-- +--------------------------------------------------------------+
function spawnGrenadePellets(grenadex, grenadey, tier)
	local newLifeTime = theCurrTime + 1500
	local amount = 4 + (4 * tier)
	local degree = math.floor(360/amount)
	for i = amount,1,-1 do
		local newRotation = math.random(degree * (i - 1),degree * i)
		newBullet = bullet(grenadex, grenadey, newRotation, newLifeTime, 99, 0)
		newBullet:add()
		bullets[#bullets + 1] = newBullet
	end
end

function spawnBullets()
	for sIndex,theShotTime in pairs(theShotTimes) do
		if theGunSlots[sIndex] > 0 then
			if Unpaused then theShotTimes[sIndex] += theLastTime end
			if theCurrTime >= theShotTime then
				local newRotation = player:getRotation() + (90 * sIndex)
				local newLifeTime = theCurrTime + 1500
				
				if theGunSlots[sIndex] == 2 then --cannon
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 5
					newBullet = bullet(player.x, player.y, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					newBullet:add()
					bullets[#bullets + 1] = newBullet 
				elseif theGunSlots[sIndex] == 3 then -- minigun
					theShotTimes[sIndex] = theCurrTime + playerAttackRate
					newBullet = bullet(player.x, player.y, newRotation + math.random(-8, 8), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					newBullet:add()
					bullets[#bullets + 1] = newBullet
					if theGunTier[sIndex] > 1 then
						newBullet = bullet(player.x, player.y, newRotation + math.random(9, 16), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
					end
					if theGunTier[sIndex] > 2 then
						newBullet = bullet(player.x, player.y, newRotation - math.random(9, 16), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
					end
				elseif theGunSlots[sIndex] == 4 then -- shotgun
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 3
					newBullet = bullet(player.x, player.y, newRotation+ math.random(-8, 8), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					newBullet:add()
					bullets[#bullets + 1] = newBullet
					newBullet = bullet(player.x, player.y, newRotation + math.random(16, 25), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					newBullet:add()
					bullets[#bullets + 1] = newBullet
					newBullet = bullet(player.x, player.y, newRotation - math.random(16, 25), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					newBullet:add()
					bullets[#bullets + 1] = newBullet
					if theGunTier[sIndex] > 1 then
						newBullet = bullet(player.x, player.y, newRotation + math.random(26, 35), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
						newBullet = bullet(player.x, player.y, newRotation - math.random(26, 35), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
					end
					if theGunTier[sIndex] > 2 then
						newBullet = bullet(player.x, player.y, newRotation + math.random(9, 15), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
						newBullet = bullet(player.x, player.y, newRotation - math.random(9, 15), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
					end
				elseif theGunSlots[sIndex] == 5 then -- rifle
					if theGunLogic[sIndex] < 3 then
						theShotTimes[sIndex] = theCurrTime + playerAttackRate
						newBullet = bullet(player.x, player.y, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
						theGunLogic[sIndex] += 1
						if theGunTier[sIndex] > 1 then
							newBullet = bullet(player.x, player.y, newRotation + 7, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
							newBullet:add()
							bullets[#bullets + 1] = newBullet
						end
						if theGunTier[sIndex] > 2 then
							newBullet = bullet(player.x, player.y, newRotation - 7, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
							newBullet:add()
							bullets[#bullets + 1] = newBullet
						end
					else
						theShotTimes[sIndex] = theCurrTime + playerAttackRate * 3
						theGunLogic[sIndex] = 0
					end
				elseif theGunSlots[sIndex] == 6 then -- grenade
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 7
					newBullet = bullet(player.x, player.y, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					newBullet:add()
					bullets[#bullets + 1] = newBullet
				elseif theGunSlots[sIndex] == 7 then -- Rang
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 6
					newBullet = bullet(player.x, player.y, newRotation, (newLifeTime + 4500), theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					newBullet:add()
					bullets[#bullets + 1] = newBullet
				elseif theGunSlots[sIndex] == 8 then -- wave
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 3
					newBullet = bullet(player.x, player.y, newRotation, (newLifeTime), theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					newBullet:add()
					bullets[#bullets + 1] = newBullet
				else --peagun
					theShotTimes[sIndex] = theCurrTime + playerAttackRate * 2
					newBullet = bullet(player.x, player.y, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
					newBullet:add()
					bullets[#bullets + 1] = newBullet 
					if theGunTier[sIndex] > 1 then
						local tempVec = vec.new(math.sin(newRotation),-math.cos(newRotation)) * 10 + vec.new(player.x,player.y) --vec.new(math.cos(newRotation), math.sin(newRotation)) * player.y
						newBullet = bullet(tempVec.x, tempVec.y, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
					end
					if theGunTier[sIndex] > 2 then
						local tempVec = vec.new(math.sin(newRotation),-math.cos(newRotation)) * -10 + vec.new(player.x,player.y)
						newBullet = bullet(tempVec.x, tempVec.y, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
					end
				end
			end
		end
	end
end


-- Bullet movement and spawning
function updateBullets()
	-- Movement
	for bIndex,bullet in pairs(bullets) do
		bullet:move()
		
		if Unpaused then bullets[bIndex].lifeTime += theLastTime end
		if theCurrTime >= bullets[bIndex].lifeTime then
			if bullets[bIndex].type == 6 then spawnGrenadePellets(bullets[bIndex].x, bullets[bIndex].y, bullets[bIndex].tier) end
			bullets[bIndex]:remove()
			table.remove(bullets, bIndex)
		end
	end
	-- Spawning
	spawnBullets()
end

function clearBullets()
	for bIndex,bullet in pairs(bullets) do
		bullets[bIndex]:remove()
	end
	for bIndex,bullet in pairs(bullets) do
		table.remove(bullets, bIndex)
	end
end

-- +--------------------------------------------------------------+
-- |                       Monster Management                     |
-- +--------------------------------------------------------------+


function spawnMonsters()
	-- Movement
	if Unpaused then theSpawnTime += theLastTime end
	if theCurrTime >= theSpawnTime then
		rndLoc = math.random(1,8)
		theSpawnTime = theCurrTime + 3200 - 200 * difficulty

		direction = { 	x = math.random(-1,1), 
						y = math.random(-1,1)}		        -- either -1, 0, 1
		if (direction.x == 0 and direction.y == 0) then
			direction.x = (math.random(0,1) * 2) - 1 
			direction.y = (math.random(0,1) * 2) - 1		-- either -1 or 1
		end
		distance = { 	x = math.random(), 
						y = math.random() }					-- between 0 to 1
		enemyX = player.x + (halfScreenWidth + (halfScreenWidth * distance.x)) * direction.x
		enemyY = player.y + (halfScreenHeight + (halfScreenHeight * distance.y)) * direction.y

		local eType = math.random(1, 5)
		local eAccel = 0.5
		
		--newEnemy = enemy(enemyX, enemyY, eType, theCurrTime)
		newEnemy = createEnemy(enemyX, enemyY, eType, theCurrTime)
		newEnemy:add()	
		enemies[#enemies + 1] = newEnemy

		spawnInc += math.random(1, difficulty)
		if spawnInc > 5 then
			spawnInc = 0
			eType = math.random(1, 6)
			--newEnemy = enemy(-enemyX, -enemyY, eType, theCurrTime)
			newEnemy = createEnemy(-enemyX, -enemyY, eType, theCurrTime)
			newEnemy:add()
			
			enemies[#enemies + 1] = newEnemy
		end
	end
end


function updateMonsters()
	for eIndex,enemy in pairs(enemies) do		
		if Unpaused then enemies[eIndex].time += theLastTime end
		enemy:move(player.x, player.y, theCurrTime)
		if enemies[eIndex].health <= 0 then
			newItem = item(enemies[eIndex].x, enemies[eIndex].y, enemies[eIndex]:getDrop())
			newItem:add()
			items[#items + 1] = newItem
			enemies[eIndex]:remove()
			table.remove(enemies,eIndex)
			addKill()
		end
	end

	spawnMonsters()
end

function clearMonsters()
	for eIndex,enemy in pairs(enemies) do		
		enemies[eIndex]:remove()
	end
	for eIndex,enemy in pairs(enemies) do	
		table.remove(enemies,eIndex)
	end
end


-- +--------------------------------------------------------------+
-- |                       Item Management                        |
-- +--------------------------------------------------------------+


function attractAllItems()
	print("attracting items")
	for iIndex,item in pairs(items) do	
		item:startMassAttraction()
	end
end

function decideWeaponTier()
	local rndTier = math.random(1,100)
	local newTier = 1
	if rndTier > (95 - math.floor(playerLuck / 5)) then
		newTier = 3
	elseif rndTier > (50 - math.floor(playerLuck / 4)) then
		newTier = 2
	end
	return newTier
end

function updateItems(dt)
	for iIndex,item in pairs(items) do	

		-- Moving all items if being attracted
		if item:getMassAttraction() == true then
			local dir = (vec.new(player.x, player.y) - vec.new(item.x, item.y)):normalized()
			local x = item.x + dir.x * absorbSpeed * dt * 3
			local y = item.y + dir.y * absorbSpeed * dt * 3
			item:moveTo(x, y)
		end

		-- Item effect when picked up	
		if items[iIndex].pickedUp == 1 then
			if items[iIndex].type == ITEM_TYPE.health then
				heal(3)
				addItemsGrabbed()
			elseif items[iIndex].type == ITEM_TYPE.weapon then
				newWeaponGrabbed(math.random(1, 8), decideWeaponTier())
				addItemsGrabbed()
			elseif items[iIndex].type == ITEM_TYPE.shield then
				shield(10000)
				addItemsGrabbed()
			elseif items[iIndex].type == ITEM_TYPE.absorbAll then 
				attractAllItems()
				addItemsGrabbed()
			elseif items[iIndex].type == ITEM_TYPE.luck then
				incLuck()
			elseif items[iIndex].type == ITEM_TYPE.exp1 then
				addEXP(1)
			elseif items[iIndex].type == ITEM_TYPE.exp2 then
				addEXP(2)
			elseif items[iIndex].type == ITEM_TYPE.exp3 then
				addEXP(3)
			elseif items[iIndex].type == ITEM_TYPE.exp6 then
				addEXP(6)
			elseif items[iIndex].type == ITEM_TYPE.exp9 then
				addEXP(9)
			elseif items[iIndex].type == ITEM_TYPE.exp16 then
				addEXP(16)
			else
				addEXP(1)	-- default is exp1
			end
			
			items[iIndex]:remove()
			table.remove(items,iIndex)
		end
	end
end

function clearItems()
	for iIndex,item in pairs(items) do	
		items[iIndex]:remove()
	end
	for iIndex,item in pairs(items) do	
		table.remove(items,iIndex)
	end
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function setUnpaused(value)
	Unpaused = value
end

function updatePlayer(dt)
	theCurrTime = playdate.getCurrentTimeMilliseconds()
	
	if Unpaused then 
		theLastTime = theCurrTime - theLastTime 
		invincibleTime += theLastTime
		gameStartTime += theLastTime
	end
	
	if invincibleTime > theCurrTime then
		if ((theCurrTime % 500) >= 250 ) then
			player:setImageDrawMode(gfx.kDrawModeInverted)
		else
			player:setImageDrawMode(gfx.kDrawModeCopy)
		end
	else
		if invincible then
			invincible = false
			player:setImageDrawMode(gfx.kDrawModeCopy)
		end
	end
	
	movePlayer(dt)
	player:setRotation(getCrankAngle())
	itemAbsorberCollisions()

	updateBullets()
	updateMonsters()
	updateParticles()
	updateItems(dt)
	
	theLastTime = theCurrTime
	Unpaused = false
	--death
	if health == 0 then
		handleDeath()
	end
end
