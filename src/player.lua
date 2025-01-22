

-- +--------------------------------------------------------------+
-- |                          Constants                           |
-- +--------------------------------------------------------------+

-- extensions
local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local floor 	<const> = math.floor
local max 		<const> = math.max
local min 		<const> = math.min
local sqrt 		<const> = math.sqrt
local random 	<const> = math.random

-- screen
local SCREEN_WIDTH 	<const> = pd.display.getWidth()
local SCREEN_HEIGHT <const> = pd.display.getHeight()

-- drawing
local lockFocus 	<const> = gfx.lockFocus
local unlockFocus 	<const> = gfx.unlockFocus
local setColor 		<const> = gfx.setColor
local colorBlack 	<const> = gfx.kColorBlack
local colorWhite 	<const> = gfx.kColorWhite
local colorClear 	<const> = gfx.kColorClear
local roundRect 	<const> = gfx.fillRoundRect

local GET_IMAGE		<const> = gfx.imagetable.getImage
local GET_SIZE 		<const> = gfx.image.getSize


-- globals
local dt 			<const> = getDT()


-- +--------------------------------------------------------------+
-- |               World, Sprite, Collider, Healthbar             |
-- +--------------------------------------------------------------+

-- World Reference
local world
local world_Add 	<const> = worldAdd_Fast
local world_Check 	<const> = worldCheckFast

-- Player Image
local playerImageTable = gfx.imagetable.new('Resources/Sheets/player_v3')
local IMAGE_ANGLE_DIFF 	<const> = 5

local playerWidth, playerHeight = GET_SIZE( GET_IMAGE(playerImageTable, 1) )
local PLAYER_IMAGE_WIDTH_HALF 	<const> = playerWidth * 0.5
local PLAYER_IMAGE_HEIGHT_HALF 	<const> = playerHeight * 0.5

-- Collider
local colliderSize 	<const> = 25
local halfCol 		<const> = floor(colliderSize * 0.5)
local playerRect = { x = 150, y = 150, width = colliderSize, height = colliderSize, tag = TAGS.player}
local velX, velY = 0, 0

-- Movement
local MOVE_BUMP_AMOUNT 	<const> = 50 * dt
local FRICTION 			<const> = -0.1
local DELTA 			<const> = 0.01
local inputLock = 1 

-- Healthbar
local HEALTHBAR_OFFSET_X 		<const> = 2
local HEALTHBAR_OFFSET_Y 		<const> = 20
local HEALTHBAR_MAXWIDTH 		<const> = 40
local HEALTHBAR_HEIGHT 			<const> = 4
local HEALTHBAR_CORNER_RADIUS 	<const> = 3

local maxHealth 	= 30 --10
local health 		= maxHealth
local healthPercent = 1
local healthImage 	= gfx.image.new(42, 6, colorClear)

-- Damage
local damageTimer = 0
local SET_DAMAGE_TIMER 		<const> = 300

-- Spike Damage Instance Data
local performSpikeDamage = false
local spikeX, spikeY = 0, 0
local spikeVelX, spikeVelY = 0, 0
local SPIKE_BOUNCE_SPEED 	<const> = 15



-- +--------------------------------------------------------------+
-- |                         Player Stats                         |
-- +--------------------------------------------------------------+

-- stattrack
local damageDealt = 0
local damageTaken = 0
local experienceGained = 0
local enemiesKilled = 0
local currentCombo = 0
local maxCombo = 0
local shotsFired = 0
local itemsGrabbed = 0
local weaponsGrabbedList = 0

-- difficulty
local difficulty = 1
local maxDifficulty = 15

-- Player
local playerLevel = 0
local playerSpeed = 50
local playerAttackRate = 100 --30
local playerAttackRateMin = 10 --25 --limit
local playerMagnet = 50
local playerSlots = 1
local playerGunDamage = 4 --1
local playerReflectDamage = 0
local playerLuck = 0
local playerLuckMax = 100 --limit
local playerBulletSpeed = 20 --50
local playerArmor = 5 --0
local playerDodge = 0
local playerDodgeMax = 75 --limit
local playerRunSpeed = 1
local playerVampire = 0
local playerVampireMax = 100 --limit
local playerHealBonus = 0
local playerStunChance = 0
local playerStunChanceMax = 75 --limit

local gameStartTime = 0

-- EXP
local playerExp = 0
local maxExpForLevel = 5
local playerMaxExp = maxExpForLevel
local playerExpPercent = 0.3
local playerExpBonus = 0


theCharmSlot1 = {0, 0, 0, 0} -- what charm is in column 1 for each gun slot
theCharmSlot2 = {0, 0, 0, 0} -- what charm is in column 2 for each gun slot
theCharmSlot3 = {0, 0, 0, 0} -- what charm is in column 3 for each gun slot
theCharmSlot4 = {0, 0, 0, 0} -- what charm is in column 4 for each gun slot
invincibleTime = 0
invincible = false

--Menu
--local currentTime



-- +--------------------------------------------------------------+
-- |                         Player UI                            |
-- +--------------------------------------------------------------+

--- UI Banner ---

local uiBannerImage = gfx.image.new('Resources/Sprites/UIBanner')
local UI_BANNER_WIDTH <const>, UI_BANNER_HEIGHT <const> = uiBannerImage:getSize()

function getBannerHeight()
	return UI_BANNER_HEIGHT
end


--- EXP ---

-- EXP Bar
local EXP_MAX_WIDTH <const> = SCREEN_WIDTH * 0.9
local EXP_HEIGHT <const> = 6
local EXP_RADIUS <const> = 3

-- EXP Border
local EXP_BORDER_WIDTH <const> = EXP_MAX_WIDTH + 2
local EXP_BORDER_HEIGHT <const> = EXP_HEIGHT + 2
local EXP_BORDER_RADIUS <const> = EXP_RADIUS + 2

-- Position
local EXP_BORDER_X <const> = floor((SCREEN_WIDTH - EXP_BORDER_WIDTH) / 2)
local EXP_BORDER_Y <const> = 4
local EXP_X_OFFSET <const> = floor((EXP_BORDER_WIDTH - EXP_MAX_WIDTH) / 2) + EXP_BORDER_X
local EXP_Y_OFFSET <const> = floor((EXP_BORDER_HEIGHT - EXP_HEIGHT) / 2) + EXP_BORDER_Y

-- Interaction
local EXP_GROWTH_FACTOR <const> = 3


local function drawPlayerEXPBar()

	local expbarWidth = playerExpPercent * EXP_MAX_WIDTH
	local height = EXP_HEIGHT
	local yPosOffset = EXP_Y_OFFSET
	if expbarWidth < 1 then 
		expbarWidth += 4
		height = 4
		yPosOffset += 1
	end

	-- Border -- Using lockFocus so the banner image can ignore the draw offset
	lockFocus(uiBannerImage)
		setColor(colorWhite)
		roundRect(EXP_BORDER_X, EXP_BORDER_Y, EXP_BORDER_WIDTH, EXP_BORDER_HEIGHT, EXP_BORDER_RADIUS)
		-- Fill Bar
	    setColor(colorBlack)
		roundRect(EXP_X_OFFSET, yPosOffset, expbarWidth, height, EXP_RADIUS)
	unlockFocus()
	uiBannerImage:drawIgnoringOffset(0, 0)	
end


local function resetEXPBar()
	playerExp = 0
	playerExpPercent = 0
end


-- TO DO: Need help from Devon to put level-up actions back in place
function addPlayerEXP(amount)

	playerExp += amount
	experienceGained += amount

	-- Level Up
	if playerExp >= playerMaxExp then
		playerExp = (playerExp - playerMaxExp) -- push any overfill exp into next level
		playerMaxExp += EXP_GROWTH_FACTOR + floor(playerLevel/10)
		playerLevel += 1

		--levelUpList += 1 -- What is this for?
		--updateLevel()
		--newWeaponGrabbed()
	end

	playerExpPercent = playerExp / playerMaxExp
end


--- Health ---

local function drawPlayerHealthBar()
	local borderWidth = HEALTHBAR_MAXWIDTH + 2
	local borderHeight = HEALTHBAR_HEIGHT + 2
	local borderRadius = HEALTHBAR_CORNER_RADIUS + 2

	local xPosOffset = floor((borderWidth - HEALTHBAR_MAXWIDTH) / 2)
	local yPosOffset = floor((borderHeight - HEALTHBAR_HEIGHT) / 2)
	local healthbarWidth = healthPercent * HEALTHBAR_MAXWIDTH

	local x = playerRect.x + halfCol - PLAYER_IMAGE_WIDTH_HALF - HEALTHBAR_OFFSET_X
	local y = playerRect.y + halfCol - PLAYER_IMAGE_HEIGHT_HALF - HEALTHBAR_OFFSET_Y

	-- Border
	setColor(colorBlack)
	roundRect(x, y, borderWidth, borderHeight, borderRadius)
	-- Fill Bar
	setColor(colorWhite)
	roundRect(x + xPosOffset, y + yPosOffset, healthbarWidth, HEALTHBAR_HEIGHT, HEALTHBAR_CORNER_RADIUS)
end


local function updateHealthBar()
	healthPercent = health / maxHealth
end


--- Draw All Player-Based UI ---

function drawPlayerUI()
	drawPlayerHealthBar()
	drawPlayerEXPBar()
end

--------------------------------

-- +--------------------------------------------------------------+
-- |            Player Sprite and Collider Interaction            |
-- +--------------------------------------------------------------+


local function teleportPlayer(x, y)
	if world == nil then return end

	local floorX = floor(x)
	local floorY = floor(y)

	playerRect.x, playerRect.y = floorX, floorY
	snapCamera(floorX, floorY)
end


function initPlayerInNewWorld(gameSceneWorld, x, y)

	-- setup new world collisions
	world = gameSceneWorld
	world_Add(world, playerRect, 0, 0, colliderSize, colliderSize)

	-- teleport player to position
	teleportPlayer(x, y)

	-- init player variables
	health = maxHealth
	updateHealthBar()
	resetEXPBar()
end


function addSaveStatsToPlayer()
	maxHealth = getSaveValue("health")
	playerGunDamage = getSaveValue("damage")
	playerExpBonus = getSaveValue("exp_bonus")
	playerSpeed = getSaveValue("speed")
end


--- Heal and Damage ---

function healPlayer(amount)
	health += (amount + playerHealBonus)
	if health > maxHealth then
		health = maxHealth
	end
	updateHealthBar()
end

function damagePlayer(time, amount, camShakeStrength, enemyX, enemyY)

	-- Invincibility
	if damageTimer > time then
		return
	elseif invincible then
		return
	elseif random(0,99) < playerDodge then
		--screenFlash()
		print("dodged damage!")
		return
	end


	-- Damaging
	local amountLost = max(amount - playerArmor, 1)
	damageTimer = time + SET_DAMAGE_TIMER
	health = health - amountLost
	if health < 0 then
		--print("health below 0")
		amountLost = amountLost + health
		health = 0
		--handleDeath()
		return
	end
	updateHealthBar()
	addDamageReceived(amountLost)

	
	-- Camera Shake
	local playerX, playerY = playerRect.x, playerRect.y
	local xDir, yDir = enemyX - playerX, enemyY - playerY
	local mag = sqrt(xDir * xDir + yDir * yDir)
	xDir, yDir = xDir / mag, yDir / mag
	cameraShake(camShakeStrength, xDir, yDir)
	screenFlash()

	-- Particles
	--spawnParticleEffect(PARTICLE_TYPE.playerImpact, playerX, playerY, direction)
end

----------------------

--[[
function getPlayerSlots()
	return playerSlots
end

function updateSlots()
	playerSlots += 1
	if playerSlots > 4 then playerSlots = 4 
	else updateMenuWeapon(playerSlots,0)
	end
end
]]

function updateLevel()
	playerLevel += 1
	setGameState(GAMESTATE.levelupmenu)
	if math.floor(playerLevel / 5) == playerSlots then
		updateSlots()
	end
	--if min(math.floor(playerLevel / 3) + 1,maxDifficulty) > difficulty then
	--	difficulty = math.floor(playerLevel / 3)
		if difficulty > maxDifficulty then 
			difficulty = maxDifficulty 
			setEnemyDifficulty(difficulty)
		end
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
	if random(0,99) < playerVampire then heal(5) end
end


-- +--------------------------------------------------------------+
-- |                  Player get values section                   |
-- +--------------------------------------------------------------+


function getPlayerLevel()
	return playerLevel
end

function getPlayerGunDamage()
	return playerGunDamage
end

function getPlayerBulletSpeed()
	return playerBulletSpeed
end

function getPlayerAttackRate()
	return playerAttackRate
end

function getPlayerReflectDamage()
	return playerReflectDamage
end

function getDifficulty()
	return difficulty
end

function setDifficulty(amount)
	difficulty = min(amount,maxDifficulty)
end

function getMaxDifficulty()
	return maxDifficulty
end

function getLuck()
	return playerLuck
end

--[[
function setRunSpeed(value)
	playerRunSpeed = value
end
]]

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
		setPlayerAttackRateInBullets(playerAttackRate)
		print('attack rate increased by ' .. tostring(5 * bonus))

	elseif stat == 3 then
		playerBulletSpeed += bonus
		setPlayerBulletSpeedInBullets(playerBulletSpeed)
		print('bullet speed increased by ' .. tostring(bonus))

	elseif stat == 4 then
		playerGunDamage += bonus
		setPlayerGunDamageInBullets(playerGunDamage)
		print('damage increased by ' .. tostring(2 * bonus))

	elseif stat == 5 then
		playerDodge += 3 * bonus
		print('dodge increased by ' .. tostring(3 * bonus))

	elseif stat == 6 then
		playerExpBonus += bonus
		print('bonus exp increased by ' .. tostring(bonus))

	elseif stat == 7 then
		playerHealBonus += 2 * bonus
		print('heal increased by ' .. tostring(4 * bonus))

	elseif stat == 8 then
		maxHealth += 8 * bonus
		heal(8 * bonus)
		print('health increased by ' .. tostring(8 * bonus))

	elseif stat == 9 then
		playerLuck += 5 * bonus
		print('luck increased by ' .. tostring(5 * bonus))

	elseif stat == 10 then
		playerMagnet += 20 * bonus
		setDistanceCheckToPlayerMagnetStat(playerMagnet)
		print('magnet increased by ' .. tostring(20 * bonus))

	elseif stat == 11 then
		playerReflectDamage += 2 * bonus
		setEnemyReflectDamage(playerReflectDamage)
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
		setEnemyStunChance(playerStunChance)
		print('stun chance increased by ' .. tostring(5 * bonus))

	else
		print('error')
	end
	if random(0,99) < playerLuck then
		maxHealth += 5		
		heal(5)
		print('health increased by 5 bonus')
	end
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
	setEnemyDifficulty(1)
	maxDifficulty = 15
	spawnInc = 0
	playerLevel = 0
	playerAttackRate = 100
	playerExp = 0
	maxExpForLevel = 5
	playerMagnet = 50
	setDistanceCheckToPlayerMagnetStat(playerMagnet)
	playerSlots = 1
	playerReflectDamage = 0
	setEnemyReflectDamage(0)
	playerLuck = 0
	playerBulletSpeed = 50
	playerArmor = 0
	playerDodge = 0
	playerRunSpeed = 1
	playerVampire = 0
	playerHealBonus = 0
	playerStunChance = 0
	setEnemyStunChance(0)
	damageTimer = 0
	clearGunStats()
	invincibleTime = 0
	invincible = false
	setUnpaused(false)
	addMun(-getMun())
end

function getFinalStats()
	local stats = {}
	local survivedTime = math.floor((theLastTime - gameStartTime) / 1000)
	stats[#stats + 1] = getWave()
	stats[#stats + 1] = playerLevel
	stats[#stats + 1] = experienceGained
	stats[#stats + 1] = damageDealt
	stats[#stats + 1] = shotsFired
	stats[#stats + 1] = enemiesKilled
	stats[#stats + 1] = maxCombo
	stats[#stats + 1] = damageTaken
	stats[#stats + 1] = itemsGrabbed
	stats[#stats + 1] = survivedTime
	stats[#stats + 1] = (getWave() + playerLevel) * (experienceGained + itemsGrabbed + survivedTime + maxCombo)
	return stats
end

--[[
function getPlayerStats()
	local stats = {}
	stats[#stats + 1] = playerLevel
	stats[#stats + 1] = playerExp
	stats[#stats + 1] = maxExpForLevel
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
]]

function getPlayerStats()
	local stats = {}
	stats[#stats + 1] = playerLevel
	stats[#stats + 1] = playerSpeed
	stats[#stats + 1] = playerMagnet
	stats[#stats + 1] = playerReflectDamage
	stats[#stats + 1] = playerExpBonus
	stats[#stats + 1] = playerLuck
	stats[#stats + 1] = playerArmor
	stats[#stats + 1] = playerDodge
	stats[#stats + 1] = playerHealBonus
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

function addPlayerLuck()
	playerLuck += 5
	print('luck increased by 5')
	if playerLuck > playerLuckMax then 
		playerLuck = playerLuckMax
	end
end

function shieldPlayer(amount)
	invincibleTime = amount
	invincible = true
end

function newWeaponGrabbed()
	incWeaponsGrabbedList(1)
	--setGameState(GAMESTATE.newweaponmenu)
end

function getWeaponsGrabbedList()
	return weaponsGrabbedList
end

function incWeaponsGrabbedList(amount)
	weaponsGrabbedList += amount
end

function getPlayerAttackRate()
	return playerAttackRate
end


-- +--------------------------------------------------------------+
-- |                          Movement                            |
-- +--------------------------------------------------------------+


function damageBouncePlayer(otherX, otherY, xDiff, yDiff)

	if performSpikeDamage then return end 	-- if a damage instance already exists, then abort.

	local mag = SPIKE_BOUNCE_SPEED / sqrt(xDiff * xDiff + yDiff * yDiff)
	spikeVelX, spikeVelY = xDiff * mag, yDiff * mag
	spikeX, spikeY = otherX, otherY
	performSpikeDamage = true
end


local function wallSpikeDamagePlayer()

	if performSpikeDamage then return end 	-- if a damage instance already exists, then abort.

	-- Bounce player in opposite velocity; doesn't matter position of tile now.
	local vX, vY = -velX, -velY
	local mag = SPIKE_BOUNCE_SPEED / sqrt(vX * vX + vY * vY)
	spikeVelX, spikeVelY = vX * mag, vY * mag
	spikeX, spikeY = playerRect.x + vX, playerRect.y + vY

	performSpikeDamage = true
end


local TAG_WALLS		<const> = TAGS.walls 
local TAG_DAMAGE 	<const> = TAGS.damage

local playerFilter = function(item, other)
	local tag = other.tag
	if 		tag == TAG_WALLS then return 'slide'
	elseif  tag == TAG_DAMAGE then
		wallSpikeDamagePlayer()
		return 'slide'
	end
	-- else return nil
end


--------------------- MOVEMENT --------------------- 

local UP 		<const> = pd.kButtonUp
local DOWN 		<const> = pd.kButtonDown
local LEFT 		<const> = pd.kButtonLeft
local RIGHT 	<const> = pd.kButtonRight
local BUTTON_JUST_PRESSED 	<const> = pd.buttonJustPressed


function player_LockInput(value)
	if value == true then 	inputLock = 0
	else 					inputLock = 1
	end
end


local function movePlayer_NEW()

	-- button input added to velocity
	local vX, vY = velX, velY
	if BUTTON_JUST_PRESSED(LEFT) then 	vX -= MOVE_BUMP_AMOUNT * inputLock end
	if BUTTON_JUST_PRESSED(RIGHT) then 	vX += MOVE_BUMP_AMOUNT * inputLock end
	if BUTTON_JUST_PRESSED(UP) then 	vY -= MOVE_BUMP_AMOUNT * inputLock end
	if BUTTON_JUST_PRESSED(DOWN) then 	vY += MOVE_BUMP_AMOUNT * inputLock end

	-- friction added to velocity
	if (vX * vX) > DELTA then vX = vX + (vX * FRICTION)
	else vX = 0 
	end
	if (vY * vY) > DELTA then vY = vY + (vY * FRICTION)
	else vY = 0 
	end

	-- checking for player's collision 
	velX, velY = vX, vY 
	local goalX, goalY = vX + playerRect.x, vY + playerRect.y
	local actualX, actualY = world_Check(world, playerRect, goalX, goalY, playerFilter)
	playerRect.x, playerRect.y = actualX, actualY

	-- returning position that's the center of the player's collision box
	return actualX + halfCol, actualY + halfCol
end



-- +--------------------------------------------------------------+
-- |                       Item Management                        |
-- +--------------------------------------------------------------+


-- To be called at the end of the pause animation.
function getPauseTime_Player(pauseTime)
	--currentTime = currentTime + pauseTime
	damageTimer = damageTimer + pauseTime
	invincibleTime = invincibleTime + pauseTime
end


function decideWeaponTier()
	local rndTier = random(1,100)
	local newTier = 1
	if rndTier > (95 - floor(playerLuck / 5)) then
		newTier = 3
	elseif rndTier > (50 - floor(playerLuck / 4)) then
		newTier = 2
	end
	return newTier
end
		

-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


local FAST_DRAW 		<const> = gfx.image.draw
local UNFLIPPED 		<const> = gfx.kImageUnflipped
local FLIP_XY 			<const> = gfx.kImageFlippedXY

local SET_DRAW_MODE 	<const> = gfx.setImageDrawMode
local INVERTED 			<const> = gfx.kDrawModeInverted
local COPY 				<const> = gfx.kDrawModeCopy

local DAMAGE_PLAYER 		<const> = damagePlayer
local CAMERA_SHAKE_MEDIUM 	<const> = CAMERA_SHAKE_STRENGTH.medium


local function drawInvincible(time, image, x, y, flipState)
	if invincibleTime > time then
		if time % 500 > 250 then
			SET_DRAW_MODE(INVERTED)
			FAST_DRAW(image, x, y, flipState)
			SET_DRAW_MODE(COPY)

		else 
			FAST_DRAW(image, x, y, flipState)
		end
	else
		invincible = false
		FAST_DRAW(image, x, y, flipState)
	end
end


function updatePlayer(time, crank, newShots, newItems)
	
	--currentTime = time

	-- Update data tracking
	shotsFired = shotsFired + newShots
	itemsGrabbed = itemsGrabbed + newItems

	-- Damage Instances
	if performSpikeDamage then 				-- bool check makes sure first damage instance is caught
		if damageTimer < time then 	-- timer check makes sure future damage instances are ignored			
			velX, velY = spikeVelX, spikeVelY
			DAMAGE_PLAYER(time, difficulty, CAMERA_SHAKE_MEDIUM, spikeX, spikeY)
		end
		performSpikeDamage = false  		-- always set to false, will ignore future damage instances
	end
	
	--local playerX, playerY = movePlayer(inputX, inputY, inputButtonB)
	local playerX, playerY = movePlayer_NEW()

	local imageIndex = crank % 180 // IMAGE_ANGLE_DIFF + 1 	-- 1 to 40
	local flipState = crank < 180 and UNFLIPPED or FLIP_XY	-- same as   a ? b : c
	local image = GET_IMAGE(playerImageTable, imageIndex)

	if invincible then 
		drawInvincible(	time, 
						image,
						playerX - PLAYER_IMAGE_WIDTH_HALF, 
						playerY - PLAYER_IMAGE_HEIGHT_HALF, 
						flipState)
	else
		FAST_DRAW(	image, 
					playerX - PLAYER_IMAGE_WIDTH_HALF, 
					playerY - PLAYER_IMAGE_HEIGHT_HALF, 
					flipState)
	end


	return playerX, playerY
end



-- used for the post-pause screen countdown to redraw the screen
function redrawPlayer(time, crank)

	local playerX, playerY = playerRect.x + halfCol, playerRect.y + halfCol

	local imageIndex = crank % 180 // IMAGE_ANGLE_DIFF + 1 	-- 1 to 40
	local flipState = crank < 180 and UNFLIPPED or FLIP_XY	-- same as   a ? b : c
	local image = GET_IMAGE(playerImageTable, imageIndex)

	if invincible then 
		drawInvincible(	time, 
						image,
						playerX - PLAYER_IMAGE_WIDTH_HALF, 
						playerY - PLAYER_IMAGE_HEIGHT_HALF, 
						flipState)
	else
		FAST_DRAW(	image, 
					playerX - PLAYER_IMAGE_WIDTH_HALF, 
					playerY - PLAYER_IMAGE_HEIGHT_HALF, 
					flipState)
	end

	return playerX, playerY
end	