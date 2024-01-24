-- playdate screen 400 x 240
local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local mathFloor <const> = math.floor

local healthbarOffsetY <const> = 30
local setDamageTimer <const> = 200

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
collider:setGroups(GROUPS.player)
collider:setCollidesWithGroups( {GROUPS.walls, GROUPS.enemy})

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

-- Player
local playerLevel = 0
local maxHealth = 15
local health = maxHealth
local playerSpeed = 50
local playerVelocity = vec.new(0, 0)
local playerAttackRate = 100
local playerAttackRateMin = 10 --limit
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
	--itemAbsorber:add()
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
	spawnParticleEffect(PARTICLE_TYPE.playerImpact, player.x, player.y, direction)
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


function getPlayerVelocity()
	return playerVelocity
end

function getPlayerPosition()
	return vec.new(player.x, player.y)
end

function getCurrTime()
	return theCurrTime
end

function getPlayerGunDamage()
	return playerGunDamage
end

function getPlayerBulletSpeed()
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

function getPlayerMagnetStat()
	return playerMagnet
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
		setDistanceCheckToPlayerMagnetStat(playerMagnet)
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
	setDistanceCheckToPlayerMagnetStat(playerMagnet)
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
	clearGunStats()
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


function changeItemAbsorbRangeBy(value)
	--itemAbsorberRange += value
	--itemAbsorber:setSize(itemAbsorberRange, itemAbsorberRange)
	--itemAbsorber:setCollideRect(0, 0, itemAbsorberRange, itemAbsorberRange)
end


function setItemAbsorbRange(value)
	--itemAbsorberRange = value
	--itemAbsorber:setSize(itemAbsorberRange, itemAbsorberRange)
	--itemAbsorber:setCollideRect(0, 0, itemAbsorberRange, itemAbsorberRange)
end


function getPlayerAttackRate()
	return playerAttackRate
end


-- +--------------------------------------------------------------+
-- |                          Movement                            |
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
	playerHealthbar:moveTo(floorX, floorY - healthbarOffsetY)
end


-- Collision response based on tags
-- Player Collider
function collider:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.weapon then
		return "overlap"
	--elseif tag == TAGS.item then
	--	other:itemGrab()
	--	return "overlap"
	elseif tag == TAGS.enemy then
		return "overlap"
	else -- Any collision that's not set is defaulted to Wall Collision
		return "slide"
	end
end


-- +--------------------------------------------------------------+
-- |                       Item Management                        |
-- +--------------------------------------------------------------+


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
	
	theLastTime = theCurrTime
	Unpaused = false
	--death
	if health == 0 then
		handleDeath()
	end
end
