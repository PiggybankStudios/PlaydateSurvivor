-- playdate screen 400 x 240
local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local mathFloor <const> = math.floor

local healthbarOffsetY <const> = 30
local setDamageTimer <const> = 200

-- Sprite
--playerSheet = gfx.imagetable.new('Resources/Sheets/player')
--animationLoop = gfx.animation.loop.new(16, playerSheet)
local playerImage = gfx.image.new('Resources/Sprites/player')
player = gfx.sprite:new()
player:setZIndex(ZINDEX.player)
player:setImage(playerImage)

-- Collider
local colliderSize <const> = 24
collider = gfx.sprite:new()
collider:setTag(TAGS.player)
collider:setSize(colliderSize, colliderSize)
collider:setCollideRect(0, 0, colliderSize, colliderSize)

-- stattrack
local damageDealt = 0
local damageTaken = 0
local experienceGained = 0
local enemiesKilled = 0
local currentCombo = 0
local maxCombo = 0
local shotsFired = 0
local itemsGrabbed = 0

-- difficulty
local difficulty = 1
local maxDifficulty = 15

-- Player
local playerLevel = 0
local maxHealth = 15
local health = maxHealth
local playerSpeed = 50
local playerVelocity = vec.new(0, 0)
local playerAttackRate = 100
local playerAttackRateMin = 25 --limit
local playerExp = 0
local startingExpForLevel = 5
local playerMagnet = 50
local playerSlots = 1
local playerGunDamage = 0
local playerReflectDamage = 0
local playerExpBonus = 0
local playerLuck = 0
local playerLuckMax = 100 --limit
local playerBulletSpeed = 50
local playerArmor = 0
local playerDodge = 0
local playerDodgeMax = 75 --limit
local playerRunSpeed = 1
local playerVampire = 0
local playerVampireMax = 100 --limit
local playerHealBonus = 0
local playerStunChance = 0
local playerStunChanceMax = 75 --limit
local playerMun = 0
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
theGunTier = {1, 0, 0, 0} -- what tier the gun is at
theCharmSlot1 = {0, 0, 0, 0} -- what charm is in column 1 for each gun slot
theCharmSlot2 = {0, 0, 0, 0} -- what charm is in column 2 for each gun slot
theCharmSlot3 = {0, 0, 0, 0} -- what charm is in column 3 for each gun slot
theCharmSlot4 = {0, 0, 0, 0} -- what charm is in column 4 for each gun slot

-- Particles
particles = {}

-- Items
items = {}
invincibleTime = 0
invincible = false

--Menu
Unpaused = false
local theCurrTime

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


function heal(amount)
	health += (amount + playerHealBonus)
	if health > maxHealth then
		health = maxHealth
	end
	playerHealthbar:updateHealth(health)
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
	health -= amountLost
	if health < 0 then
		amountLost += health
		health = 0
	end
	playerHealthbar:updateHealth(health)
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
	if math.min(math.floor(playerLevel / 3) + 1,maxDifficulty) > difficulty then
		difficulty = math.floor(playerLevel / 3)
		if difficulty > maxDifficulty then difficulty = maxDifficulty end
	end
end

function addShot()
	shotsFired += 1
end

function addDamageDealt(amount)
	damageDealt += amount
end

function addDamageReceived(amount)
	damageTaken += amount
	currentCombo = 0
end

function addKill()
	enemiesKilled += 1
	currentCombo += 1
	if currentCombo > maxCombo then maxCombo = currentCombo end
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

function getPlayerLevel()
	return playerLevel
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

function getMun()
	return playerMun
end

function addMun(amount)
	playerMun += amount
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
		playerHealthbar:updateMaxHealth(maxHealth, health)
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
		playerHealthbar:updateMaxHealth(maxHealth, health)
		heal(1)
		print('health increased by 1 bonus')
	end
end

function setStats()
	damageDealt = getSaveValue(SAVE_REF.run_damage_dealt)
	damageTaken = getSaveValue(SAVE_REF.run_damage_taken)
	experienceGained = getSaveValue(SAVE_REF.run_exp_total)
	enemiesKilled = getSaveValue(SAVE_REF.run_enemies_killed)
	maxCombo = getSaveValue(SAVE_REF.run_max_combo)
	shotsFired = getSaveValue(SAVE_REF.run_shots_fired)
	itemsGrabbed = getSaveValue(SAVE_REF.run_items_grabbed)
	difficulty = getSaveValue(SAVE_REF.run_difficulty)
	playerLevel = getSaveValue(SAVE_REF.run_level)
	maxHealth = getSaveValue(SAVE_REF.run_health_max)
	health = getSaveValue(SAVE_REF.run_health)
	playerSpeed = getSaveValue(SAVE_REF.run_speed)
	playerAttackRate = getSaveValue(SAVE_REF.run_att_rate)
	playerExp = getSaveValue(SAVE_REF.run_exp)
	playerMagnet = getSaveValue(SAVE_REF.run_magnet)
	playerSlots = getSaveValue(SAVE_REF.run_slots)
	playerGunDamage = getSaveValue(SAVE_REF.run_damage)
	playerReflectDamage = getSaveValue(SAVE_REF.run_reflect)
	playerExpBonus = getSaveValue(SAVE_REF.run_exp_bonus)
	playerLuck = getSaveValue(SAVE_REF.run_luck)
	playerBulletSpeed = getSaveValue(SAVE_REF.run_bullet_speed)
	playerArmor = getSaveValue(SAVE_REF.run_armor)
	playerDodge = getSaveValue(SAVE_REF.run_dodge)
	playerRunSpeed = getSaveValue(SAVE_REF.run_speed)
	playerVampire = getSaveValue(SAVE_REF.run_vampire)
	playerHealBonus = getSaveValue(SAVE_REF.run_heal_bonus)
	playerStunChance = getSaveValue(SAVE_REF.run_stun)
	playerMun = getSaveValue(SAVE_REF.mun)
	theGunSlots = {getSaveValue(SAVE_REF.run_gun_1), getSaveValue(SAVE_REF.run_gun_2), getSaveValue(SAVE_REF.run_gun_3), getSaveValue(SAVE_REF.run_gun_4)}
	theGunTier = {getSaveValue(SAVE_REF.run_gun_t1), getSaveValue(SAVE_REF.run_gun_t2), getSaveValue(SAVE_REF.run_gun_t3), getSaveValue(SAVE_REF.run_gun_t4)}
end

function clearStats()
	damageDealt = 0
	damageTaken = 0
	experienceGained = 0
	enemiesKilled = 0
	currentCombo = 0
	maxCombo = 0
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
	playerGunDamage = 0
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
	playerMun = 0
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
	stats[#stats + 1] = maxCombo
	stats[#stats + 1] = damageTaken
	stats[#stats + 1] = itemsGrabbed
	stats[#stats + 1] = survivedTime
	stats[#stats + 1] = (difficulty + playerLevel) * (experienceGained + itemsGrabbed + survivedTime + maxCombo)
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
	stats[#stats + 1] = (4 - ((playerAttackRate - 25) / 25))
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
	local extraTier = 0
	if theGunSlots[slot] == weapon then
		if theGunTier[slot] == tier then extraTier = 1 end
	end
	theGunSlots[slot] = weapon
	theGunTier[slot] = tier + extraTier
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
	playerVelocity.x = getInputX() * moveSpeed
	playerVelocity.y = getInputY() * moveSpeed
	local goalX = player.x + playerVelocity.x
	local goalY = player.y + playerVelocity.y

	-- The actual position is determined via collision response above
	local actualX, actualY, collisions = collider:checkCollisions(goalX, goalY)
	movePlayerWithCollider(actualX, actualY)
end


-- Moves both player sprite and collider - flooring stops jittering b/c only integers
function movePlayerWithCollider(x, y)
	local floorX = mathFloor(x)
	local floorY = mathFloor(y)
	player:moveTo(floorX, floorY)
	collider:moveTo(floorX, floorY)
	itemAbsorber:moveTo(floorX, floorY)
	playerHealthbar:moveTo(floorX, floorY - healthbarOffsetY)
end


function getPlayerVelocity()
	return playerVelocity
end


function getPlayerPosition()
	return vec.new(player.x, player.y)
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
				if newRotation > 360 then newRotation -= 360 
				elseif newRotation < -360 then newRotation += 360 end
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
					newBullet = bullet(player.x, player.y, newRotation + math.random(-8, 8), newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
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
					newBullet = bullet(player.x, player.y, newRotation + math.random(-10, 10), (newLifeTime + 4500), theGunSlots[sIndex], sIndex, theGunTier[sIndex])
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
						local tempVec = vec.newPolar(1,newRotation) --vec.new(math.cos(newRotation), math.sin(newRotation)) * player.y
						tempVec = (tempVec:leftNormal() * 10) + vec.new(player.x, player.y)
						newBullet = bullet(tempVec.x, tempVec.y, newRotation, newLifeTime, theGunSlots[sIndex], sIndex, theGunTier[sIndex])
						newBullet:add()
						bullets[#bullets + 1] = newBullet
					end
					if theGunTier[sIndex] > 2 then
						local tempVec = vec.newPolar(1,newRotation)
						tempVec += (tempVec:rightNormal() * 10) + vec.new(player.x, player.y)
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
		bullet:move(theCurrTime)
		
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
			elseif items[iIndex].type == ITEM_TYPE.mun2 then
				addMun(2)
			elseif items[iIndex].type == ITEM_TYPE.mun10 then
				addMun(10)
			elseif items[iIndex].type == ITEM_TYPE.mun50 then
				addMun(50)
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
	updateParticles()
	updateItems(dt)
	
	theLastTime = theCurrTime
	Unpaused = false
	--death
	if health == 0 then
		handleDeath()
	end
end
