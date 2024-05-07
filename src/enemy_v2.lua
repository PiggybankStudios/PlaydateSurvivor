local pd <const> = playdate
local gfx <const> = pd.graphics

local SCREEN_HALF_WIDTH 	<const> = pd.display.getWidth() / 2
local SCREEN_HALF_HEIGHT 	<const> = pd.display.getHeight() / 2

local ceil 		<const> = math.ceil
local min 		<const> = math.min
local max 		<const> = math.max
local sqrt 		<const> = math.sqrt
local atan2 	<const> = math.atan2
local random 	<const> = math.random

local GET_IMAGE <const> = gfx.imagetable.getImage
local GET_SIZE 	<const> = gfx.image.getSize

local MOVE_TOWARDS	<const> = moveTowards

-- World Data
local worldRef, cellSizeRef

-- Main Data
local dt <const> = getDT()


-- Non-Enemy Data
local LOCAL_ITEM_TYPE = ITEM_TYPE
local LOCAL_TAGS = TAGS

local CAMERA_SHAKE_STRENGTH = {
	tiny = 2,
	small = 4, 
	medium = 10,
	large = 24,
	massive = 48
}

-- identical to global tags, localized for speed and readability



-- Player Values
local stunChance = 0
local difficulty = 15
local reflectDamage = 1

-- Enemy Data

---- RENDERING ----
local img_enemyFastBall = 		gfx.image.new('Resources/Sprites/enemy/Enemy1')
local img_enemyNormalSquare = 	gfx.image.new('Resources/Sprites/enemy/Enemy2')
local img_enemyBast = 			gfx.image.new('Resources/Sprites/enemy/Enemy3')
local img_enemyMedic = 			gfx.image.new('Resources/Sprites/enemy/Enemy4')
local img_enemyMunBag = 		gfx.image.new('Resources/Sprites/enemy/Enemy16')

local imgTable_bulletBill = 	gfx.imagetable.new('Resources/Sheets/Enemies/bulletBill-table-22-22')
local imgTable_chunkyArms = 	gfx.imagetable.new('Resources/Sheets/Enemies/chunkyArms-table-58-50')

local IMAGE_LIST = {
	img_enemyFastBall,
	img_enemyNormalSquare,
	img_enemyBast,
	img_enemyMedic,
	GET_IMAGE(imgTable_bulletBill, 1),
	GET_IMAGE(imgTable_chunkyArms, 1),
	img_enemyMunBag
} 

local IMAGE_WIDTH, IMAGE_HEIGHT = {}, {}
local IMAGE_WIDTH_HALF, IMAGE_HEIGHT_HALF = {}, {}
local BIGGEST_ENEMY_WIDTH, BIGGEST_ENEMY_HEIGHT = 0, 0
for i = 1, #IMAGE_LIST do
	local width, height = GET_SIZE(IMAGE_LIST[i])
	IMAGE_WIDTH[i], IMAGE_HEIGHT[i] = width, height
	IMAGE_WIDTH_HALF[i], IMAGE_HEIGHT_HALF[i] = width * 0.5, height * 0.5

	BIGGEST_ENEMY_WIDTH = BIGGEST_ENEMY_WIDTH < width and width or BIGGEST_ENEMY_WIDTH
	BIGGEST_ENEMY_HEIGHT = BIGGEST_ENEMY_HEIGHT < height and height or BIGGEST_ENEMY_HEIGHT
end

-------------------

local BASE_ACCEL				<const> = 15
local SPEED_DAMPEN 				<const> = 0.96
local GROUP_SIZE 				<const> = 5
local TIME_SET_SIZE 			<const> = 50
local GROUP_TIME_SET			<const> = GROUP_SIZE * TIME_SET_SIZE

local REPEL_FORCE 				<const> = 3
local PLAYER_COLLISION_DISTANCE <const> = 25 * 25
local BOUNCE_STRENGTH 		<const> = 6
local STUN_WIGGLE_AMOUNT 	<const> = 3
local STUN_TIMER_SET 		<const> = 100

local SCALE_HEALTH			<const> = 3
local SCALE_SPEED 			<const> = 4
local SCALE_DAMAGE 			<const> = 5

local movementParticleSpawnRate = 50


local ENEMY_TYPE = {
	fastBall = 1,
	normalSquare = 2,
	bat = 3,
	medic = 4,
	bulletBill = 5,
	chunkyArms = 6,
	munBag = 7
}

local ENEMY_DROP = {
	{ LOCAL_ITEM_TYPE.exp1,		LOCAL_ITEM_TYPE.health, 	LOCAL_ITEM_TYPE.luck 		},	-- fastBall
	{ LOCAL_ITEM_TYPE.exp1,		LOCAL_ITEM_TYPE.health, 	LOCAL_ITEM_TYPE.shield 		},	-- normalSquare
	{ LOCAL_ITEM_TYPE.exp1,		LOCAL_ITEM_TYPE.weapon, 	LOCAL_ITEM_TYPE.luck 		},	-- bat
	{ LOCAL_ITEM_TYPE.exp1,		LOCAL_ITEM_TYPE.health, 	LOCAL_ITEM_TYPE.absorbAll 	},	-- medic
	{ LOCAL_ITEM_TYPE.exp1,		LOCAL_ITEM_TYPE.health, 	LOCAL_ITEM_TYPE.luck 		},	-- bulletBill
	{ LOCAL_ITEM_TYPE.exp16,	LOCAL_ITEM_TYPE.luck 									},	-- chunkyArms
	{ LOCAL_ITEM_TYPE.mun2,		LOCAL_ITEM_TYPE.mun10, 		LOCAL_ITEM_TYPE.mun50 		}	-- munBag
}

-- Percents need to total 100
-- More rare drops have their percent added to the previous percent
local ENEMY_DROP_PERCENT = {
	{ 94, 5, 1 },		-- fastBall
	{ 85, 10, 5 },		-- normalSquare
	{ 54, 45, 1 },		-- bat
	{ 60, 35, 5 },		-- medic
	{ 80, 19, 1 },		-- bulletBill
	{ 95, 5 },			-- chunkyArms
	{ 85, 10, 5}		-- munBag -- temp numbers --{ (90 - tLuck1 - tLuck2), (10 + tLuck1), tLuck2}
}

local ENEMY_RATING = {
	1, 		-- fastBall
	1, 		-- normalSquare
	2, 		-- bat
	3, 		-- medic
	2, 		-- bulletBill
	3, 		-- chunkyArms
	1  		-- munBag
}

local ENEMY_MAX_SPEEDS = {
	6,		-- fastBall
	3,		-- normalSquare
	8,		-- bat
	2,		-- medic
	10,		-- bulletBill
	2,		-- chunkyArms
	1 		-- munBag
}

local ENEMY_REPEL_FORCE = {
	2,		-- fastBall
	2,		-- normalSquare
	3,		-- bat
	4,		-- medic
	5,		-- bulletBill
	7,		-- chunkyArms
	2 		-- munBag
}

local ENEMY_HEALTH = {
	2,		-- fastBall
	5,		-- normalSquare
	3,		-- bat
	20,		-- medic
	6,		-- bulletBill
	66,		-- chunkyArms
	1 		-- munBag
}

local ENEMY_DAMAGE = {
	1,		-- fastBall
	5,		-- normalSquare
	3,		-- bat
	2,		-- medic
	4,		-- bulletBill
	10,		-- chunkyArms
	1 		-- munBag
}

local ENEMY_CAMERA_SHAKE = {
	CAMERA_SHAKE_STRENGTH.tiny,  	-- fastBall
	CAMERA_SHAKE_STRENGTH.medium,	-- normalSquare
	CAMERA_SHAKE_STRENGTH.tiny,  	-- bat
	CAMERA_SHAKE_STRENGTH.large, 	-- medic
	CAMERA_SHAKE_STRENGTH.large, 	-- bulletBill
	CAMERA_SHAKE_STRENGTH.large, 	-- chunkyArms
	CAMERA_SHAKE_STRENGTH.tiny   	-- munBag
}


-- Maxes
local maxEnemies <const> = 30
local activeEnemies = 0


-- Arrays
local enemyType = {}
local posX = {}
local posY = {}
local velX = {}
local velY = {}
local savedDirX = {}
local savedDirY = {}

local maxSpeed = {}
local spawnMoveParticle = {}
local rotation = {}

local health = {}
local fullHealth = {}
local healthPercent = {}
local stunned = {}
local wiggleDir = {}
local wigglePosX = {}

local moveCalcTimer = {}
local timer = {}
local damageAmount = {}
local shakeStrength = {}
local aiPhase = {}

local images = {}
local collisionDetails = {}



local spawnInc = 0
local theSpawnTime = 0



-- +--------------------------------------------------------------+
-- |                Init, Create, Delete, Handle                  |
-- +--------------------------------------------------------------+

for i = 1, maxEnemies do
	enemyType[i] = 0
	posX[i] = 0
	posY[i] = 0
	velX[i] = 0
	velY[i] = 0
	savedDirX[i] = 0
	savedDirY[i] = 0

	maxSpeed[i] = 0
	spawnMoveParticle[i] = 0
	rotation[i] = 0

	health[i] = 0
	fullHealth[i] = 0
	healthPercent[i] = 0
	stunned[i] = 0
	wiggleDir[i] = 0
	wigglePosX[i] = 0

	moveCalcTimer[i] = 0
	timer[i] = 0
	damageAmount[i] = 0
	aiPhase[i] = 0

	images[i] = 0
	collisionDetails[i] = { tag = TAGS.enemy, 
							index = 0, 
							cellRange = {0, 0, 0, 0}
							}
end


local ADD_ENEMY <const> = worldAdd_Fast
local function createEnemy(type, spawnX, spawnY)

	local total = activeEnemies + 1
	if total > maxEnemies then return end 	-- if too many enemies exist, don't create another enemy
	activeEnemies = total


	-- Arrays
	enemyType[total] = type
	posX[total] = spawnX
	posY[total] = spawnY
	velX[total] = 0
	velY[total] = 0
	savedDirX[total] = 0
	savedDirY[total] = 0

	maxSpeed[total] = difficulty // SCALE_SPEED + ENEMY_MAX_SPEEDS[type]
	spawnMoveParticle[total] = 0
	rotation[total] = 0

	health[total] = ceil(difficulty / SCALE_HEALTH) * ENEMY_HEALTH[type]
	fullHealth[total] = health[total]
	healthPercent[total] = 1
	stunned[total] = 0
	wiggleDir[total] = 0
	wigglePosX[total] = 0

	moveCalcTimer[total] = 0
	timer[total] = 0
	damageAmount[total] = ceil(difficulty / SCALE_DAMAGE) * ENEMY_DAMAGE[type]
	aiPhase[total] = 0

	-- Image
	images[total] = IMAGE_LIST[type]

	-- Collider
	collisionDetails[total] = { tag = TAGS.enemy, 
								index = total, 
								cellRange = {0, 0, 0, 0}
								}
	ADD_ENEMY(worldRef, collisionDetails[total], spawnX, spawnY, IMAGE_WIDTH[type], IMAGE_HEIGHT[type])
end


-- Deleted enemy data is overwitten with enemy at the ends of all lists
local REMOVE_ENEMY <const> = worldRemoveEnemy
local function deleteEnemy(i, total)
	enemyType[i] = enemyType[total]
	posX[i] = posX[total]
	posY[i] = posY[total]
	velX[i] = velX[total]
	velY[i] = velY[total]
	savedDirX[i] = savedDirX[total]
	savedDirY[i] = savedDirY[total]

	maxSpeed[i] = maxSpeed[total]
	spawnMoveParticle[i] = spawnMoveParticle[total]
	rotation[i] = rotation[total]

	health[i] = health[total]
	fullHealth[i] = fullHealth[total]
	healthPercent[i] = healthPercent[total]
	stunned[i] = stunned[total]
	wiggleDir[i] = wiggleDir[total]
	wigglePosX[i] = wigglePosX[total]

	moveCalcTimer[i] = moveCalcTimer[total]
	timer[i] = timer[total]
	damageAmount[i] = damageAmount[total]
	aiPhase[i] = aiPhase[total]

	images[i] = images[total]

	REMOVE_ENEMY(worldRef, collisionDetails[i])
	collisionDetails[i] = collisionDetails[total]
	collisionDetails[i].index = i
end



-- +--------------------------------------------------------------+
-- |                         Interaction                          |
-- +--------------------------------------------------------------+


local function healEnemy(i, amount)
	health[i] = min(health[i] + amount, fullHealth[i])
	healthPercent[i] = health[i] / fullHealth[i]
end


local trackDamageDealt <const> = addDamageDealt

-- Must be global, called from bullets
function bulletEnemyCollision(i, damage, knockback, playerX, playerY, time)
	
	-- Damage
	local h = health[i] - damage
	health[i] = h
	healthPercent[i] = h / fullHealth[i]
	if h < 0 then damage = damage + h end -- adjusts damage to only track what brought health to 0
	trackDamageDealt(damage)

	-- Stun
	if stunChance > 0 then 
		if random(0, 99) < stunChance then 
			stunned[i] = time + STUN_TIMER_SET
			wiggleDir[i] = 1
		end
	end

	-- Knockback
	if knockback ~= 0 then
		local xDiff, yDiff = posX[i] - playerX, posY[i] - playerY
		local scaledMagnitude = knockback / sqrt(xDiff * xDiff + yDiff * yDiff)
		velX[i] = xDiff * scaledMagnitude + velX[i]
		velY[i] = yDiff * scaledMagnitude + velY[i]
	end
end


local CREATE_ITEM <const> = createItem

-- Create an instance of an item at the enemy's position -- called on enemy death.
-- Items are created via percent, 1 - 100
local function createDroppedItem(enemyIndex, type)
	local itemIndex = 1
	local total = 0
	local percent = random(1, 100)
	local dropPercentList = ENEMY_DROP_PERCENT[type]

	for i = 1, #dropPercentList do
		total += dropPercentList[i]
		if percent < total then 
			itemIndex = i
			break
		end
	end
	
	local droppedItem = ENEMY_DROP[type][itemIndex]
	--if droppedItem == LOCAL_ITEM_TYPE.exp1 then 
	--	droppedItem = expModifier(ENEMY_RATING[type])
	--end

	CREATE_ITEM(	droppedItem, 
					posX[enemyIndex] + IMAGE_WIDTH_HALF[type], 
					posY[enemyIndex] + IMAGE_HEIGHT_HALF[type]
					)
end


-- Modifies EXP dropped depending on enemy rating
local function expModifier(rating)
	-- TO DO
end


--[[
function expDropped(rate)
	local index = 1
	local total = 0
	
	local luck = getLuck()
	local e2 = math.floor(luck / 2) --max 50
	local e3 = math.floor(luck / 5) --max 20
	local e6 = math.floor(luck / 5) --max 20
	local e9 = math.floor(luck / 10) --max 10
	local e16 = math.floor(luck / 20) --max 5
	local expPercent = {100,0,0,0,0,0}
	if rate == 2 then
		expPercent = { 30 - e9*2 - e16*2, 40 - e3, 20, 9 + e6, 1 + e9*2, e16*2}
	elseif rate == 3 then
		expPercent = { 15 - e16*3, 30 - e9*3, 35 - e6, 15 + e6, 5 + e9*3, e16*3}
	else
		expPercent = { 70 - e2 - e3, 20 + e2 - e6 - e9 - e16, 10 + e3, e6, e9, e16}
	end
	local expDrop = { 	LOCAL_ITEM_TYPE.exp1, 
						LOCAL_ITEM_TYPE.exp2, 
						LOCAL_ITEM_TYPE.exp3, 
						LOCAL_ITEM_TYPE.exp6, 
						LOCAL_ITEM_TYPE.exp9, 
						LOCAL_ITEM_TYPE.exp16 }
	
	local percent = math.random(1, 100)
	for i = 1, #expDrop do
		total += expPercent[i]
		if percent <= total then
			if expPercent[i] > 0 then index = i end
			break
		end
	end
	return expDrop[index]
end
]]



-- +--------------------------------------------------------------+
-- |                   Movement for Enemy Types                   |
-- +--------------------------------------------------------------+

-- Movement Calc Constants
local BAT_PHASE_MOVE_TOWARD 			<const> = 2500
local BAT_PHASE_MOVE_AWAY 				<const> = 2000

local MEDIC_HEAL_TIMER_SET 				<const> = 1000
local MEDIC_HEALTH_THRESHOLD			<const> = 0.3

local BULLETBILL_ROTATE_TIMER_SET 		<const> = 1000
local BULLETBILL_MOVE_TIMER_SET 		<const> = 2000
local BULLET_ROTATE_SPEED 				<const> = 30
local M_180_PI 							<const> = 57.295779
local BULLET_BILL_MAX_SPEED 			<const> = ENEMY_MAX_SPEEDS[ENEMY_TYPE.bulletBill]

local CHUNKYARMS_HEALTH_THRESHOLD 		<const> = 0.5
local CHUNKYARMS_NEW_DAMAGEAMOUNT 		<const> = 10
local CHUNKYARMS_HEALING_TIMER 			<const> = 1500
--local CHUNKYARMS_HEALING_RATE 		<const> = 0.1 -- 1/10th

local MUNBAG_TIMER_SET 					<const> = 1000
local MUNBAG_HEALTH_THRESHOLD 			<const> = 0.5


-- Movement Calc Table
-- Having functions written out in this table is faster than having a table of local functions, b/c of local scope
local ENEMY_MOVE_CALC = {

	--- FastBall ---
	function(i, enemyX, enemyY, targetX, targetY)
		return 	targetX - enemyX, 
				targetY - enemyY
	end
	,


	--- Normal Square ---
	function(i, enemyX, enemyY, targetX, targetY)
		return 	targetX - enemyX, 
				targetY - enemyY
	end
	,


	--- Bat ---
	function(i, enemyX, enemyY, targetX, targetY, time)
		-- move toward player for some time
		if aiPhase[i] == 0 then 
			if timer[i] < time then 
				timer[i] = time + BAT_PHASE_MOVE_AWAY
				aiPhase[i] = 1
			end
			return 	targetX - enemyX,
					targetY - enemyY
		end

		-- move away from player for some time
		local randX, randY = 0, 0
		if timer[i] < time then 
			timer[i] = time + BAT_PHASE_MOVE_TOWARD
			aiPhase[i] = 0
			randX, randY = random(1, 12), random(1, 12)
		end
		return 	enemyX - targetX + randX,
				enemyY - targetY + randY
	end
	,


	--- Medic ---
	function(i, enemyX, enemyY, targetX, targetY, time)
		-- move toward player
		if aiPhase[i] < 1 then 
			if healthPercent[i] < MEDIC_HEALTH_THRESHOLD then
				aiPhase[i] = 1
				velX[i] = 0
				velY[i] = 0
			end
			return 	targetX - enemyX,
					targetY - enemyY	
		end

		-- move away from player and heal
		if timer[i] < time then 
			timer[i] = time + MEDIC_HEAL_TIMER_SET
			healEnemy(i, ((difficulty // SCALE_HEALTH) + 1) * 2)
			if health[i] >= fullHealth[i] then 
				aiPhase[i] = 0
			end
		end
		return 	enemyX - targetX,
				enemyY - targetY
	end
	,


	--- Bullet Bill ---
	function(i, enemyX, enemyY, targetX, targetY, time)
		-- Smoothly rotate image towards player
		if aiPhase[i] < 1 then 			
			local calcRot = M_180_PI * atan2(enemyY - targetY, enemyX - targetX) + 180
			local newRot = MOVE_TOWARDS(rotation[i], calcRot, BULLET_ROTATE_SPEED)
			rotation[i] = newRot
			local imageIndex = ceil(newRot / 30)
			if savedDirX[i] ~= imageIndex then
				savedDirX[i] = imageIndex
				images[i] = GET_IMAGE(imgTable_bulletBill, imageIndex)
			end

			-- Update timer for movement phase
			if timer[i] < time then 
				aiPhase[i] = 1
				timer[i] = time + BULLETBILL_MOVE_TIMER_SET
			end

			return 1, 1 	-- Returning 1's prevents movement and avoids div by 0.

		-- Set Precise Rotation
		elseif aiPhase[i] < 2 then

			-- Set image towards player
			local calcRot = M_180_PI * atan2(enemyY - targetY, enemyX - targetX) + 180
			rotation[i] = calcRot
			images[i] = GET_IMAGE(imgTable_bulletBill, calcRot // 30 + 1 )

			-- Set rotation towards player
			aiPhase[i] = 2
			local xDiff = targetX - enemyX
			local yDiff = targetY - enemyY
			savedDirX[i] = xDiff
			savedDirY[i] = yDiff
			maxSpeed[i] = BULLET_BILL_MAX_SPEED

			return xDiff, yDiff
		end
		
		-- Stop bullet to find new rotation
		if timer[i] < time then 
			aiPhase[i] = 0
			timer[i] = time + BULLETBILL_ROTATE_TIMER_SET
			velX[i] = 0 
			velY[i] = 0
			maxSpeed[i] = 0 -- Setting velocity and maxSpeed to 0 stops this enemy from moving.
			return 1, 1		-- Returning 1's prevents movement and avoids div by 0.
		end

		-- Move Bullet in saved direction
		return savedDirX[i], savedDirY[i]
	end
	,


	--- Chunky Arms ---
	function(i, enemyX, enemyY, targetX, targetY, time)
		-- Healing, if upgraded
		if aiPhase[i] > 0 then 
			if timer[i] < time then 
				timer[i] = time + CHUNKYARMS_HEALING_TIMER
				local healAmount = difficulty // SCALE_HEALTH + GROUP_SIZE -- healing includes move-calc group size bc of time delay
				healEnemy(i, healAmount)
			end

		-- Standard mode until health threshold -> Upgraded Mode: healing, moves faster, hits harder
		elseif healthPercent[i] < CHUNKYARMS_HEALTH_THRESHOLD then 
			aiPhase[i] = 1
			maxSpeed[i] = difficulty // SCALE_DAMAGE + 3
			damageAmount[i] = CHUNKYARMS_NEW_DAMAGEAMOUNT
			images[i] = GET_IMAGE(imgTable_chunkyArms, 2)	
		end

		-- always move towards the player
		return 	targetX - enemyX,
				targetY - enemyY		
	end
	,


	--- Mun Bag ---
	function(i, enemyX, enemyY, targetX, targetY, time)
		-- If below health threshold, increase speed and heal
		if timer[i] < time then
			timer[i] = time + MUNBAG_TIMER_SET
			if healthPercent[i] < MUNBAG_HEALTH_THRESHOLD then 
				--local maxedMaxSpeed = 
				--if maxSpeed[i] < maxedMaxSpeed then 
				--	maxSpeed[i] += 0.3 
				--end 
				maxSpeed[i] = min(maxSpeed[i] + 0.3, (difficulty // SCALE_DAMAGE) + 3)
			end

			-- Always heal
			local healAmount = (difficulty // SCALE_HEALTH) + 1
			healEnemy(i, healAmount)
		end

		-- Move away from the player
		return 	enemyX - targetX,
				enemyY - targetY
	end
}


-- +--------------------------------------------------------------+
-- |                       General Movement                       |
-- +--------------------------------------------------------------+


-- Pushes this enemy away from any enemies that are inside the its current cells.
local NEXT <const> = next

local function repelFromEnemies(i, type, centerX, centerY, thisVelX, thisVelY)

	-- If there are no cells to check, then don't calculate anything. Safe to abort here.
	local cellRange = collisionDetails[i].cellRange
	if cellRange[1] < 1 then 
		return thisVelX, thisVelY
	end 
								-- cellY							  -- cellX
	local cell = worldRef.rows[ random(cellRange[3], cellRange[4]) ][ random(cellRange[1], cellRange[2]) ]

	-- If there are any enemies within this cell, OTHER THAN THIS ONE, then apply a repulsion force to both velocities
	if cell.itemCount > 0 then 	
		for item, _ in NEXT, cell.items do

			local enemyIndex = item.index						
			if enemyIndex ~= nil and enemyIndex ~= i  then

				local otherType = enemyType[enemyIndex]

				local xDiff = centerX - posX[enemyIndex] + IMAGE_WIDTH_HALF[otherType]
				local yDiff = centerY - posY[enemyIndex] + IMAGE_HEIGHT_HALF[otherType]		

				local thisMagnitude = ENEMY_REPEL_FORCE[type] / sqrt(xDiff * xDiff + yDiff * yDiff)
				local otherMagnitude = ENEMY_REPEL_FORCE[otherType] / sqrt(xDiff * xDiff + yDiff * yDiff)

				velX[enemyIndex] = velX[enemyIndex] - (xDiff * thisMagnitude)
				velY[enemyIndex] = velY[enemyIndex] - (yDiff * thisMagnitude)

				-- return this enemy's new velocity
				return 	thisVelX + (xDiff * otherMagnitude),
						thisVelY + (yDiff * otherMagnitude)
			end

		end
	end
		
	-- if no repel force, just return the original velocity
	return thisVelX, thisVelY
end


-- Movement shared by all enemies
local UPDATE_ENEMY 		<const> = worldUpdateEnemy
local DAMAGE_PLAYER 	<const> = damagePlayer

local function moveSingleEnemy(i, type, time, playerX, playerY)

	local startX, startY = posX[i], posY[i]

	--- Stun ---
	if stunned[i] > 0 then 
		-- currently stunned
		if stunned[i] > time then
			wiggleDir[i] = -wiggleDir[i]
			wigglePosX[i] = startX + wiggleDir[i] * STUN_WIGGLE_AMOUNT
			return wigglePosX[i], startY

		else
			stunned[i], velX[i], velY[i] = 0, 0, 0

		end
	end


	--- Collide With Player - Bounce, Deal Damage, Take Damage ---
	local centerX, centerY = startX + IMAGE_WIDTH_HALF[type], startY + IMAGE_HEIGHT_HALF[type]

	local xDiffBounce, yDiffBounce = centerX - playerX, centerY - playerY
	local collideDist = xDiffBounce * xDiffBounce + yDiffBounce * yDiffBounce

	if collideDist < PLAYER_COLLISION_DISTANCE then

		-- bounce
		local scaledMagnitude = BOUNCE_STRENGTH / sqrt(collideDist)
		local bounceX = xDiffBounce * scaledMagnitude
		local bounceY = yDiffBounce * scaledMagnitude

		-- assignments
		local pX = startX + bounceX
		local pY = startY + bounceY
		velX[i] = bounceX
		velY[i] = bounceY
		posX[i] = pX
		posY[i] = pY

		-- collision interaction
		DAMAGE_PLAYER(damageAmount[i], ENEMY_CAMERA_SHAKE[type], pX, pY)

		-- Moving the enemy and attached UI
		UPDATE_ENEMY(worldRef, collisionDetails[i], pX, pY)

		return pX, pY
	end
	

	--- MOVE - No player collision ---
	local vX, vY

	-- wait to calc new movement until timer elapsed
	if moveCalcTimer[i] > time then 
		vX, vY = velX[i] * SPEED_DAMPEN, velY[i] * SPEED_DAMPEN
	else
		-- reset timer
		local timeGroupOffset = i % GROUP_SIZE * TIME_SET_SIZE
		local nextTimeGroup = time // GROUP_TIME_SET + 1
		moveCalcTimer[i] = nextTimeGroup * GROUP_TIME_SET + timeGroupOffset

		-- apply repel forces from other enemies to this velocity	
		vX, vY = repelFromEnemies(i, type, centerX, centerY, velX[i], velY[i])

		-- calculate new movement velocity for this enemy
		local xDiff, yDiff = ENEMY_MOVE_CALC[type](i, centerX, centerY, playerX, playerY, time)	

		local scaledMagnitude = maxSpeed[i] / sqrt(xDiff * xDiff + yDiff * yDiff)
		local maxSpeedChange = BASE_ACCEL * dt	
		vX = MOVE_TOWARDS(vX, xDiff * scaledMagnitude, maxSpeedChange)
		vY = MOVE_TOWARDS(vY, yDiff * scaledMagnitude, maxSpeedChange)
	end

	local pX = startX + vX 
	local pY = startY + vY
	velX[i] = vX
	velY[i] = vY
	posX[i] = pX
	posY[i] = pY

	-- spawn movement particles
	-- TO DO --

	-- Moving the enemy and attached UI
	UPDATE_ENEMY(worldRef, collisionDetails[i], pX, pY)

	return pX, pY
end


--[[
function enemy:updateVFX()

	-- Spawn movement particle
	if self.spawnMoveParticle <= currentTime then
		self.spawnMoveParticle = currentTime + movementParticleSpawnRate
		spawnParticleEffect(PARTICLE_TYPE.enemyTrail, self.x, self.y)
	end
end
]]


-- +--------------------------------------------------------------+
-- |                           Globals                            |
-- +--------------------------------------------------------------+


function getEnemyPosition(i)
	return posX[i], posY[i]
end


function setEnemyStunChance(value)
	stunChance = value
end

function setEnemyReflectDamage(value)
	reflectDamage = value
end


function setEnemyDifficulty(value)
	difficulty = value
end


function clearEnemies()
	activeEnemies = 0
end


-- To be called at the end of the pause animation.
function getPauseTime_Enemies(pauseTime)
	
	theSpawnTime = theSpawnTime + pauseTime

	for i = 1, activeEnemies do
		moveCalcTimer[i] 	= moveCalcTimer[i] + pauseTime
		timer[i] 			= timer[i] + pauseTime
		stunned[i]			= stunned[i] + pauseTime
	end
end


-- To be called after level creation, so enemies have access to world collision cells
function sendWorldCollidersToEnemies(gameSceneWorld)
	worldRef = gameSceneWorld
	cellSizeRef = worldRef.cellSize
end





local typeMax = 5
local debugEnemyType = typeMax
function debugSpawnMassAllEnemies()
	for i = 1, maxEnemies do
		debugEnemyType += 1
		if debugEnemyType > typeMax then debugEnemyType = 1 end
		x = random(200, 800)
		y = random(200, 800)
		createEnemy(debugEnemyType, x, y)
	end
end


function debugSpawnMassEnemy()
	local x, y
	local randomType
	for i = 1, maxEnemies do 
		x = random(100, 300)
		y = random(100, 300)
		randomType = random(6, 6)
		createEnemy(randomType, x, y)
	end
end


-- +--------------------------------------------------------------+
-- |                          Management                          |
-- +--------------------------------------------------------------+


local function spawnMonsters(cameraX, cameraY, time)
	if time >= theSpawnTime then

		theSpawnTime = time + 3200 - 200 * difficulty

		local enemyX = cameraX + random(-250, 250)
		local enemyY = cameraY + random(-145, 145)

		local type = random(1, 5)
		createEnemy(type, enemyX, enemyY)

		-- Sometimes create a second enemy, possibly with higher difficulty
		spawnInc += random(1, difficulty)
		if spawnInc > 5 then
			spawnInc = 0
			type = random(1, 7)
			createEnemy(type, enemyX, -enemyY)
		end
	end
end


--[[
-- ASK ABOUT:
	-- Do we want healthbars for enemies? Takes up a lot of space on screen, and healing can be shown through particles
	-- What about a "damaged" sprite for each enemy?

-- Constants for speed
local setColor <const> = gfx.setColor
local colorBlack <const> = gfx.kColorBlack
local colorWhite <const> = gfx.kColorWhite
local roundRect <const> = gfx.fillRoundRect


-- Draw enemy healthbars
local HEALTHBAR_OFFSET_Y 			<const> = 10
local HEALTHBAR_MAXWIDTH 			<const> = 40
local HEALTHBAR_HEIGHT 				<const> = 4
local HEALTHBAR_CORNER_RADIUS 		<const> = 3

local HEALTHBAR_BORDER_WIDTH 		<const> = HEALTHBAR_MAXWIDTH + 2
local HEALTHBAR_BORDER_WIDTH_HALF	<const> = HEALTHBAR_BORDER_WIDTH * 0.5
local HEALTHBAR_BORDER_HEIGHT		<const> = HEALTHBAR_HEIGHT + 2
local HEALTHBAR_BORDER_RADIUS		<const> = HEALTHBAR_CORNER_RADIUS + 2
	
local HEALTHBAR_XPOS_OFFSET			<const> = floor((HEALTHBAR_BORDER_WIDTH - HEALTHBAR_MAXWIDTH) / 2)
local HEALTHBAR_YPOS_OFFSET			<const> = floor((HEALTHBAR_BORDER_HEIGHT - HEALTHBAR_HEIGHT) / 2)

local function drawHealthBar(i, type, x, y)
	local healthbarWidth = healthPercent[i] * HEALTHBAR_MAXWIDTH
	x = x + IMAGE_WIDTH_HALF[type] - HEALTHBAR_BORDER_WIDTH_HALF
	y = y - HEALTHBAR_OFFSET_Y

	setColor(colorBlack)
	roundRect(x, y, HEALTHBAR_BORDER_WIDTH, HEALTHBAR_BORDER_HEIGHT, HEALTHBAR_BORDER_RADIUS)
	setColor(colorWhite)
	roundRect(x + HEALTHBAR_XPOS_OFFSET, y + HEALTHBAR_YPOS_OFFSET, healthbarWidth, HEALTHBAR_HEIGHT, HEALTHBAR_CORNER_RADIUS)
end
]]


local SCREEN_MIN_X 			<const> = -BIGGEST_ENEMY_WIDTH
local SCREEN_MAX_X 			<const> = 400
local SCREEN_MIN_Y 			<const> = getBannerHeight() - BIGGEST_ENEMY_HEIGHT
local SCREEN_MAX_Y 			<const> = 240

local FAST_DRAW <const> = gfx.image.draw

-- Update enemy movement, destruction, item drops, etc.
local function updateEnemiesLists(time, playerX, playerY, screenOffsetX, screenOffsetY)

	local i = 1
	local currentActiveEnemies = activeEnemies
	while i <= currentActiveEnemies do	

		local type = enemyType[i]

		-- draw - only need to increment loop if the enemy was NOT deleted
		if health[i] > 0 then	
			local x, y = moveSingleEnemy(i, type, time, playerX, playerY)			

			-- Checking to draw if inside screen space saves enough time in all cases, rather than always drawing at all times
			local drawX = x + screenOffsetX
			local drawY = y + screenOffsetY
			if 	SCREEN_MIN_X < drawX and drawX < SCREEN_MAX_X and 
				SCREEN_MIN_Y < drawY and drawY < SCREEN_MAX_Y then
					FAST_DRAW(images[i], x, y)
			end

			--drawHealthBar(i, type, x, y)  
			i = i + 1
		
		-- delete - do NOT need to increment loop here
		else 
			createDroppedItem(i, type)
			deleteEnemy(i, currentActiveEnemies)				
			currentActiveEnemies = currentActiveEnemies - 1
			
		end		
	end

	activeEnemies = currentActiveEnemies
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


function updateEnemies(time, playerX, playerY, cameraPosX, cameraPosY, screenOffsetX, screenOffsetY)

	spawnMonsters(cameraPosX, cameraPosY, time)
	updateEnemiesLists(time, playerX, playerY, screenOffsetX, screenOffsetY)

end
