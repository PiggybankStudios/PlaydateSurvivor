local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D
local mathp <const> = playdate.math
local frame <const> = playdate.frameTimer

local halfScreenWidth <const> = playdate.display.getWidth() / 2
local halfScreenHeight <const> = playdate.display.getHeight() / 2

local floor <const> = math.floor
local ceil <const> = math.ceil
local abs <const> = math.abs
local min <const> = math.min
local max <const> = math.max
local deg <const> = math.deg
local atan2 <const> = math.atan2
local random <const> = math.random
local newVec <const> = vec.new
local newPolar <const> = vec.newPolar
local lerp <const> = mathp.lerp

-- World Data
local worldRef, cellSizeRef


-- Non-Enemy Data
local ITEM_TYPE = {
	health = 	1,
	weapon = 	2, 
	shield = 	3,  
	absorbAll = 4, 
	exp1 = 		5, 
	exp2 = 		6,  
	exp3 = 		7,  
	exp6 = 		8,  
	exp9 = 		9,
	exp16 = 	10,
	luck = 		11,
	mun2 = 		12 ,
	mun10 = 	13 ,
	mun50 = 	14 
}

local CAMERA_SHAKE_STRENGTH = {
	tiny = 2,
	small = 4, 
	medium = 10,
	large = 24,
	massive = 48
}

-- identical to global tags, localized for speed and readability
local LOCAL_TAGS = TAGS


-- Player Values
local stunChance = 0
local difficulty = 1
local reflectDamage = 1

-- Enemy Data

---- RENDERING ----
local img_enemyFastBall = gfx.image.new('Resources/Sprites/enemy/Enemy1')
local img_enemyNormalSquare = gfx.image.new('Resources/Sprites/enemy/Enemy2')
local img_enemyBast = gfx.image.new('Resources/Sprites/enemy/Enemy3')
local img_enemyMedic = gfx.image.new('Resources/Sprites/enemy/Enemy4')
--local img_enemyBulletBill = gfx.image.new('Resources/Sprites/enemy/Enemy5')
--local img_enemyChunkyArms = gfx.image.new('Resources/Sprites/enemy/Enemy6')
local img_enemyMunBag = gfx.image.new('Resources/Sprites/enemy/Enemy16')

local imgTable_bulletBill = gfx.imagetable.new('Resources/Sheets/Enemies/bulletBill-table-22-22')
local imgTable_chunkArms = gfx.imagetable.new('Resources/Sheets/Enemies/chunkyArms-table-58-50')

local IMAGE_LIST = {
	img_enemyFastBall,
	img_enemyNormalSquare,
	img_enemyBast,
	img_enemyMedic,
	imgTable_bulletBill:getImage(1),
	imgTable_chunkArms:getImage(1),
	img_enemyMunBag
} 

local PLAYER_IMAGE_WIDTH_HALF, PLAYER_IMAGE_HEIGHT_HALF = getPlayerImageSize()
PLAYER_IMAGE_WIDTH_HALF *= 0.25
PLAYER_IMAGE_HEIGHT_HALF *= 0.25

local IMAGE_WIDTH, IMAGE_HEIGHT = {}, {}
local IMAGE_WIDTH_HALF, IMAGE_HEIGHT_HALF = {}, {}
local IMAGE_DISTANCE_X, IMAGE_DISTANCE_Y = {}, {}
for i = 1, #IMAGE_LIST do
	IMAGE_WIDTH[i], IMAGE_HEIGHT[i] = IMAGE_LIST[i]:getSize()
	IMAGE_WIDTH_HALF[i], IMAGE_HEIGHT_HALF[i] = IMAGE_WIDTH[i] * 0.5, IMAGE_HEIGHT[i] * 0.5

	local width = IMAGE_WIDTH_HALF[i] + PLAYER_IMAGE_WIDTH_HALF
	local height = IMAGE_HEIGHT_HALF[i] + PLAYER_IMAGE_HEIGHT_HALF
	IMAGE_DISTANCE_X[i] = width * width
	IMAGE_DISTANCE_Y[i] = height * height
end


local enemiesImage = gfx.image.new(400, 240) -- screen size draw
local enemiesSprite = gfx.sprite.new(enemiesImage)	-- drawing image w/ sprite so we can draw via zIndex order
enemiesSprite:setIgnoresDrawOffset(true)			
enemiesSprite:setZIndex(ZINDEX.enemy)
enemiesSprite:moveTo(200, 120)

-------------------

local HEALTHBAR_OFFSET_Y <const> = 10
local HEALTHBAR_MAXWIDTH <const> = 40
local HEALTHBAR_HEIGHT <const> = 4
local HEALTHBAR_CORNER_RADIUS <const> = 3

local REPEL_FORCE <const> = 0.25
local BOUNCE_STRENGTH <const> = 4
local STUN_WIGGLE_AMOUNT <const> = 3
local STUN_TIMER_SET <const> = 100

local SCALE_HEALTH <const> = 3
local SCALE_SPEED <const> = 4
local SCALE_DAMAGE <const> = 5

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
	{ ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.luck },		-- fastBall
	{ ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.shield },		-- normalSquare
	{ ITEM_TYPE.exp1, ITEM_TYPE.weapon, ITEM_TYPE.luck },		-- bat
	{ ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.absorbAll },	-- medic
	{ ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.luck },		-- bulletBill
	{ ITEM_TYPE.exp16, ITEM_TYPE.luck },						-- chunkyArms
	{ ITEM_TYPE.mun2, ITEM_TYPE.mun10, ITEM_TYPE.mun50 }		-- munBag
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
	5,		-- fastBall
	3,		-- normalSquare
	4,		-- bat
	2,		-- medic
	7,		-- bulletBill
	1,		-- chunkyArms
	1 		-- munBag
}

local ENEMY_ACCEL = {
	3,		-- fastBall
	1.5,	-- normalSquare
	2,		-- bat
	4,		-- medic
	3,		-- bulletBill
	2,		-- chunkyArms
	1 		-- munBag
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
	1, --10,		-- chunkyArms
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
local maxEnemies <const> = 50
local activeEnemies = 0


-- Arrays
local enemyType = {}
local posX = {}
local posY = {}
local prevPosX = {}
local prevPosY = {}
local velX = {}
local velY = {}
local maxSpeed = {}
local accel = {}
local rotation = {}
local savedRotation = {}
local spawnMoveParticle = {}

local health = {}
local fullHealth = {}
local healthPercent = {}
local stunned = {}
local wiggleDir = {}
local wigglePosX = {}

local timer = {}
local damageAmount = {}
local shakeStrength = {}
local aiPhase = {}

local images = {}
local rects = {}



local spawnInc = 0
local currentTime = 0
local theSpawnTime = 0
local timeFromPause = 0
local pauseDiff = 0


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
-- |                        Timers & Misc                         |
-- +--------------------------------------------------------------+


local function getCreateTimer()
	currentCreateTimer = playdate.getElapsedTime()
	if maxCreateTimer < currentCreateTimer then 
		maxCreateTimer = currentCreateTimer
		print("ENEMY - Create: " .. 1000*maxCreateTimer)
	end
end


local function getUpdateTimer()
	currentUpdateTimer = playdate.getElapsedTime()
	if maxUpdateTimer < currentUpdateTimer then
		maxUpdateTimer = currentUpdateTimer
		print("ENEMY -- Update: " .. 1000*maxUpdateTimer)
	end
end


local function getDrawTimer()
	currentDrawTimer = playdate.getElapsedTime()
	if maxDrawTimer < currentDrawTimer then
		maxDrawTimer = currentDrawTimer
		print("ENEMY --- Draw: " .. 1000*maxDrawTimer)
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


local function clamp(value, min, max)
	if value > max then
		return max
	elseif value < min then 
		return min
	else
		return value
	end
end


local function constrain(value, min, max)
	if value > max then 
		return value - max
	elseif value < min then
		return value + max
	else
		return value
	end
end


-- +--------------------------------------------------------------+
-- |                Init, Create, Delete, Handle                  |
-- +--------------------------------------------------------------+

for i = 1, maxEnemies do
	enemyType[i] = 0
	posX[i] = 0
	posY[i] = 0
	prevPosX[i] = 0
	prevPosY[i] = 0
	velX[i] = 0
	velY[i] = 0
	maxSpeed[i] = 0
	accel[i] = 0
	rotation[i] = 0
	savedRotation[i] = 0
	spawnMoveParticle[i] = 0

	health[i] = 0
	fullHealth[i] = 0
	healthPercent[i] = 0
	stunned[i] = 0
	wiggleDir[i] = 0
	wigglePosX[i] = 0

	timer[i] = 0
	damageAmount[i] = 0
	aiPhase[i] = 0

	images[i] = 0
	rects[i] = { x = 0, y = 0, width = 0, height = 0, tag = 0, index = 0, cellsWide = { 0, 0 }, cellsHigh = { 0, 0 } }
end


local function createEnemy(type, spawnX, spawnY)

	if activeEnemies >= maxEnemies then return end 	-- if too many enemies exist, don't create another enemy

	activeEnemies += 1
	local total = activeEnemies


	-- Arrays
	enemyType[total] = type
	posX[total] = spawnX
	posY[total] = spawnY
	prevPosX[total] = spawnX
	prevPosY[total] = spawnY
	velX[total] = 0
	velY[total] = 0
	maxSpeed[total] = ENEMY_MAX_SPEEDS[type] + (floor(difficulty / SCALE_SPEED))
	accel[total] = ENEMY_ACCEL[type]
	rotation[total] = 0
	savedRotation[total] = 0
	spawnMoveParticle[total] = 0

	health[total] = ENEMY_HEALTH[type] * (1 + floor(difficulty / SCALE_HEALTH))
	fullHealth[total] = health[total]
	healthPercent[total] = 1
	stunned[total] = 0
	wiggleDir[total] = 0
	wigglePosX[total] = 0

	timer[total] = 0
	damageAmount[total] = ENEMY_DAMAGE[type] * (1 + floor(difficulty / SCALE_DAMAGE))
	aiPhase[total] = 1

	-- Image
	images[total] = IMAGE_LIST[type]

	-- Collider
	local r = { x = spawnX, 
				y = spawnY, 
				width = IMAGE_WIDTH[type], 
				height = IMAGE_HEIGHT[type], 
				tag = TAGS.enemy, 
				index = total,
				cellsWide = { 0, 0 },
				cellsHigh = { 0, 0 }
	}
	rects[total] = r
	worldRef:add(rects[total], r.x, r.y, r.width, r.height)
	worldRef:updateEnemy(rects[total], posX[total], posY[total]) -- setup for enemy repulsion
end


-- Deleted enemy data is overwitten with enemy at the ends of all lists
local function deleteEnemy(i, total)
	enemyType[i] = enemyType[total]
	posX[i] = posX[total]
	posY[i] = posY[total]
	prevPosX[i] = prevPosX[total]
	prevPosY[i] = prevPosY[total]
	velX[i] = velX[total]
	velY[i] = velY[total]
	maxSpeed[i] = maxSpeed[total]
	accel[i] = accel[total]
	rotation[i] = rotation[total]
	savedRotation[i] = savedRotation[total]
	spawnMoveParticle[i] = spawnMoveParticle[total]

	health[i] = health[total]
	fullHealth[i] = fullHealth[total]
	healthPercent[i] = healthPercent[total]
	stunned[i] = stunned[total]
	wiggleDir[i] = wiggleDir[total]
	wigglePosX[i] = wigglePosX[total]

	timer[i] = timer[total]
	damageAmount[i] = damageAmount[total]
	aiPhase[i] = aiPhase[total]

	images[i] = images[total]

	worldRef:remove(rects[i])
	rects[i] = rects[total]
	rects[i].index = i
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
function bulletEnemyCollision(i, damage, knockback, playerPosRef, localCurrentTime)
	
	-- Damage
	health[i] -= damage
	local h = health[i]
	healthPercent[i] = h / fullHealth[i]
	if h < 0 then damage += h end -- adjusts damage to only track what brought health to 0
	trackDamageDealt(damage)

	-- Stun
	if stunChance > 0 then 
		if random(0, 99) < stunChance then 
			stunned[i] = localCurrentTime + STUN_TIMER_SET
			wiggleDir[i] = 1
		end
	end

	-- Knockback
	if knockback ~= 0 then
		local impactForce = newVec(posX[i] - playerPosRef.x, posY[i] - playerPosRef.y):normalized()
		impactForce *= knockback
		velX[i] += impactForce.x
		velY[i] += impactForce.y
	end
end


local createItemInstance <const> = spawnItem

-- Create an instance of an item at the enemy's position -- called on enemy death.
-- Items are created via percent: 1 - 100
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
	--if droppedItem == ITEM_TYPE.exp1 then 
	--	droppedItem = expModifier(ENEMY_RATING[type])
	--end

	createItemInstance(	droppedItem, 
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
	local expDrop = { ITEM_TYPE.exp1, ITEM_TYPE.exp2, ITEM_TYPE.exp3, ITEM_TYPE.exp6, ITEM_TYPE.exp9, ITEM_TYPE.exp16 }
	
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

------------------------------------------------
				-- Fast Ball --

-- Just calculates the direction to move in
local function fastBall_calculateMove(i, targetX, targetY)
	return newVec(	targetX - posX[i], 
					targetY - posY[i]
					)
end


------------------------------------------------
				-- Normal Square --

local function normalSquare_calculateMove(i, targetX, targetY)
	return newVec(	targetX - posX[i], 
					targetY - posY[i]
					)
end


------------------------------------------------
					-- Bat --

local BAT_PHASE_MOVE_TOWARD <const> = 1500 
local BAT_PHASE_MOVE_AWAY <const> = 1000
local function bat_calculateMove(i, targetX, targetY, localCurrentTime)
	
	-- move toward player for some time
	if aiPhase[i] == 0 then 
		if timer[i] < localCurrentTime then 
			timer[i] = localCurrentTime + BAT_PHASE_MOVE_AWAY
			aiPhase[i] = 1
		end
		return newVec(	targetX - posX[i],
						targetY - posY[i]
						)
	end

	-- move away from player for some time
	if timer[i] < localCurrentTime then 
		timer[i] = localCurrentTime + BAT_PHASE_MOVE_TOWARD
		aiPhase[i] = 0
	end
	return newVec(	posX[i] - targetX,
					posY[i] - targetY
					)
end


------------------------------------------------
				   -- Medic --

local MEDIC_HEAL_TIMER_SET <const> = 1000
local function medic_calculateMove(i, targetX, targetY, localCurrentTime)

	-- move toward player
	if aiPhase[i] == 0 then 

		-- if below health threshold, change aiPhase
		if health[i] < floor(fullHealth[i] / 3) then 
			aiPhase[i] = 1
			velX[i] = 0
			velY[i] = 0
		end
		return newVec(	targetX - posX[i],
						targetY - posY[i]
						)
	end

	-- move away from player and heal
	if timer[i] < localCurrentTime then 
		timer[i] = localCurrentTime + MEDIC_HEAL_TIMER_SET
		local healAmount = 2 * (1 + floor(difficulty / SCALE_HEALTH))
		healEnemy(i, healAmount)
		if health[i] >= fullHealth[i] then 
			aiPhase[i] = 0
		end
	end
	return newVec(	posX[i] - targetX,
					posY[i] - targetY
					)
end


------------------------------------------------
				-- Bullet Bill --

local BULLETBILL_ROTATE_TIMER_SET <const> = 1000
local BULLETBILL_MOVE_TIMER_SET <const> = 2000
local function bulletBill_calculateMove(i, targetX, targetY, localCurrentTime)

	---  Only rotation ---
	if aiPhase[i] == 0 then 

		-- Rotate the enemy towards the player
		local targetDir = newVec(	posX[i] - targetX + IMAGE_WIDTH_HALF[ENEMY_TYPE.bulletBill], 
									posY[i] - targetY + IMAGE_HEIGHT_HALF[ENEMY_TYPE.bulletBill])
		local targetRot = deg(atan2(targetDir.y, targetDir.x)) - 90
		targetRot = constrain(targetRot, 0, 360)
		local timeDifference = BULLETBILL_ROTATE_TIMER_SET - (timer[i] - localCurrentTime)
		local t = clamp(timeDifference / BULLETBILL_ROTATE_TIMER_SET, 0, 1)
		rotation[i] = lerp(savedRotation[i], targetRot, t)

		-- Update image
		local imageIndex = max(ceil(rotation[i] / 30), 1)
		images[i] = imgTable_bulletBill:getImage(imageIndex)

		-- Update timer for movement phase
		if timer[i] < localCurrentTime then 
			timer[i] = localCurrentTime + BULLETBILL_MOVE_TIMER_SET
			aiPhase[i] = 1
		end

		-- Setting velocity to 0 and returning 0 stops this enemy from moving.
		velX[i] = 0
		velY[i] = 0
		return newVec(0, 0)

	end

	--- Only Movement ---

	-- Update timer for rotation phase
	if timer[i] < localCurrentTime then 
		timer[i] = localCurrentTime + BULLETBILL_ROTATE_TIMER_SET
		aiPhase[i] = 0
	end

	-- Save this rotation as the starting point for the next rotation lerp
	savedRotation[i] = rotation[i]

	-- Move in the saved direction
	return newPolar(1, rotation[i])

end


------------------------------------------------
				-- Chunky Arms --

local CHUNKYARMS_HEALTH_THRESHOLD <const> = 0.5
local CHUNKYARMS_NEW_DAMAGEAMOUNT <const> = 10
local CHUNKYARMS_HEALING_TIMER <const> = 1500
--local CHUNKYARMS_HEALING_RATE <const> = 0.1 -- 1/10th
local function chunkyArms_calculateMove(i, targetX, targetY, localCurrentTime)
	
	-- If health is below a threshold, then activate the second phase: healing, moves faster, hits harder.
	if (health[i] / fullHealth[i]) < CHUNKYARMS_HEALTH_THRESHOLD then 
		aiPhase[i] = 2
		maxSpeed[i] = 3 + floo(difficulty / SCALE_DAMAGE)
		damageAmount[i] = CHUNKYARMS_NEW_DAMAGEAMOUNT
		images[i] = imgTable_chunkArms:getImage(2)	
	end

	-- Healing
	if aiPhase[i] == 2 then 
		if timer[i] < localCurrentTime then 
			timer[i] = localCurrentTime + CHUNKYARMS_HEALING_TIMER
			--local healAmount = floor(fullHealth[i] / CHUNKYARMS_HEALING_RATE)
			local healAmount = 1 + floor(difficulty / SCALE_HEALTH)
			healEnemy(i, healAmount)
		end
	end

	-- always move towards the player
	return newVec(	targetX - posX[i],
					targetY - posY[i]
					)
end

--[[
local function chunkyArms_calculateMove(targetX, targetY)
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)
	if currentTime >= self.time then
		self.time = currentTime + 500
		if self.health < (self.fullhealth / 2) then self.speed += 0.3 end
		if self.speed > (3 + math.floor(getDifficulty() / SCALE_DAMAGE)) then self.speed = (3 + math.floor(getDifficulty() / SCALE_DAMAGE)) end
		if self.health < self.fullhealth then 
			self:heal(1 + math.floor(getDifficulty() / SCALE_HEALTH))
		end
	end
end
]]
------------------------------------------------
				-- Mun Bag --

--local tLuck1 = math.floor(getLuck()/4)
--local tLuck2 = math.floor(getLuck()/20)
--self.dropPercent = { (90 - tLuck1 - tLuck2), (10 + tLuck1), tLuck2}

local MUNBAG_TIMER_SET <const> = 1000
local MUNBAG_HEALTH_THRESHOLD <const> = 0.5
local function munBag_calculateMove(i, targetX, targetY, localCurrentTime)

	-- If below health threshold, increase speed and heal
	if timer[i] < localCurrentTime then

		timer[i] = localCurrentTime + MUNBAG_TIMER_SET

		-- If below health threshold, increase speed
		if (health[i] / fullHealth[i]) < MUNBAG_HEALTH_THRESHOLD then 
			local maxedMaxSpeed = 3 + floor(difficulty / SCALE_DAMAGE)
			if maxSpeed[i] < maxedMaxSpeed then 
				maxSpeed[i] += 0.3 
			end 
		end

		-- Always heal
		local healAmount = 1 + floor(difficulty / SCALE_HEALTH)
		healEnemy(i, healAmount)
	end

	-- Move away from the player
	return newVec(	posX[i] - targetX,
					posY[i] - targetY
					)
end


------------------------------------------------
			   -- Movement Array --

local ENEMY_MOVE_CALCS = {
	function(i, x, y) return fastBall_calculateMove(i, x, y) end,
	function(i, x, y) return normalSquare_calculateMove(i, x, y) end,
	function(i, x, y, time) return bat_calculateMove(i, x, y, time) end,
	function(i, x, y, time) return medic_calculateMove(i, x, y, time) end,
	function(i, x, y, time) return bulletBill_calculateMove(i, x, y, time) end,
	function(i, x, y, time) return chunkyArms_calculateMove(i, x, y, time) end,
	function(i, x, y, time) return munBag_calculateMove(i, x, y, time) end
}


-- +--------------------------------------------------------------+
-- |                           Movement                           |
-- +--------------------------------------------------------------+


local function sign(x)
	if x > 0 then 	return 1
	else 			return -1
	end
end

local function moveTowards(current, target, maxDelta)
	if abs(target - current) <= maxDelta then
		return target
	else
		return current + sign(target - current) * maxDelta
	end
end


-- Pushes this enemy away from any enemies that are inside the its current cells.
local function repelFromEnemies(i, type)

	local cLeft, cRight = rects[i].cellsWide[1], rects[i].cellsWide[1]
	local cTop, cBot = rects[i].cellsHigh[1], rects[i].cellsHigh[2]

	-- If there are no cells to check, then don't calculate anything. Safe to abort here.
	if cLeft == 0 then return end

	local maxRepels, currentRepels = 5, 0

	for cy = cTop, cBot do
		local row = worldRef.rows[cy]
		for cx = cLeft, cRight do
			local cell = row[cx]
			if cell.itemCount > 1 then 

				-- If there are any enemies within this cell, OTHER THAN THIS ONE, then apply a repulsion force to both velocities
				for item,_ in pairs(cell.items) do					
					if item.tag == LOCAL_TAGS.enemy then 			
						local enemyIndex = item.index
						if enemyIndex ~= i then

							local otherType = enemyType[enemyIndex]
							local thisPos = newVec(posX[i] + IMAGE_WIDTH_HALF[type], posY[i] + IMAGE_HEIGHT_HALF[type])
							local otherPos = newVec(posX[enemyIndex] + IMAGE_WIDTH_HALF[otherType], posY[enemyIndex] + IMAGE_HEIGHT_HALF[otherType])
							local force = (thisPos - otherPos):normalized() * REPEL_FORCE
							velX[i] += force.x
							velY[i] += force.y
							velX[enemyIndex] -= force.x
							velY[enemyIndex] -= force.y

							currentRepels += 1
							if currentRepels >= maxRepels then return end
						end
					end
				end
			end
		end
	end

end


-- Movement shared by all enemies
local function moveSingleEnemy(dt, i, type, mainLoopTime, offsetX, offsetY, playerX, playerY)

	--- stun ---
	if stunned[i] > 0 then 
		-- currently stunned
		if stunned[i] > mainLoopTime then
			wiggleDir[i] *= -1 
			wigglePosX[i] = posX[i] + wiggleDir[i] * STUN_WIGGLE_AMOUNT
			return wigglePosX[i], posY[i]

		else
			stunned[i] = 0
			velX[i], velY[i] = 0, 0
		end
	end


	--- Distance to Player Calc---
	local halfWidth = IMAGE_WIDTH_HALF[type]
	local halfHeight = IMAGE_HEIGHT_HALF[type]
	local vecToPlayer = newVec(	posX[i] + halfWidth - playerX,
								posY[i] + halfHeight - playerY)
	local distance = vecToPlayer:magnitudeSquared()

	--- No player collision ---
	if distance > IMAGE_DISTANCE_X[type] and distance > IMAGE_DISTANCE_Y[type] then

		-- apply repel forces from other enemies to this velocity
		repelFromEnemies(i, type)

		-- calculate new movement velocity for this enemy
		local enemyMoveVec = ENEMY_MOVE_CALCS[type](i, playerX, playerY, mainLoopTime)
		local dir = enemyMoveVec:normalized()
		local maxSpeedChange = accel[i] * dt
		local oldX, oldY = velX[i], velY[i]
		local newX = moveTowards(oldX, dir.x * maxSpeed[i], maxSpeedChange)
		local newY = moveTowards(oldY, dir.y * maxSpeed[i], maxSpeedChange)

		-- apply new velocity to position
		velX[i] += newX - oldX
		velY[i] += newY - oldY
		posX[i] += velX[i]
		posY[i] += velY[i]
		local x = posX[i]
		local y = posY[i]

		-- spawn movement particles
		-- TO DO --

		-- Moving the enemy and attached UI
		rects[i].x, rects[i].y = x, y
		worldRef:updateEnemy(rects[i], x, y)

		return x, y
	end


	--- Collide With Player - Bounce, Deal Damage, Take Damage ---
	local bounceNormal = vecToPlayer:normalized()

	-- bounce
	velX[i] = (bounceNormal.x * BOUNCE_STRENGTH)
	velY[i] = (bounceNormal.y * BOUNCE_STRENGTH)
	posX[i] += velX[i] + (halfWidth * bounceNormal.x)
	posY[i] += velY[i] + (halfHeight * bounceNormal.y)
	local x = posX[i]
	local y = posY[i]

	-- collision interaction
	--damagePlayer(damageAmount[i], ENEMY_CAMERA_SHAKE[type], x, y)

	-- Moving the enemy and attached UI
	rects[i].x, rects[i].y = x, y
	worldRef:updateEnemy(rects[i], x, y)

	return x, y
end


--[[
-- Enemy-run vfx that's requires per-frame updates
function enemy:updateVFX()

	-- Stun - wiggle sprite
	if self.stunned > currentTime then
		self.wiggleDir *= -1
		local newX = self.wigglePos.x + (self.wiggleDir * stunWiggleAmount)
		self:moveTo(newX, self.y)

	elseif self.stunned > 0 then -- only sets a single time, once stun is finished
		self.stunned = 0 									-- set to 0 to indicate stun is over
		self:moveTo(self.previousPos.x, self.previousPos.y)	-- return sprite to original position
	end

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


function setSpawnTime(value)
	theSpawnTime = value
end


-- To be called after level creation, b/c level start clears the sprite list
function addEnemiesSpriteToList(gameSceneWorld)
	worldRef = gameSceneWorld
	cellSizeRef = worldRef.cellSize
	enemiesSprite:add()
end


function clearEnemies()
	activeEnemies = 0
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
	for i = 1, maxEnemies do 
		x = random(200, 800)
		y = random(200, 800)
		createEnemy(2, x, y)
	end
end


-- +--------------------------------------------------------------+
-- |                          Management                          |
-- +--------------------------------------------------------------+


local function spawnMonsters()
	-- 
	--if Unpaused then theSpawnTime += (currentTime - timeFromPause) end

	if currentTime >= theSpawnTime then
		rndLoc = random(1,8)
		theSpawnTime = currentTime + 3200 - 200 * difficulty

		-- either -1 or 1
		flip = {
			x = (math.random(0,1) * 2) - 1,
			y = (math.random(0,1) * 2) - 1
		}

		-- random on unit circle - protects against randomly getting 0
		direction = newVec(0, 0)
		direction.x = max(0.01, random()) * flip.x
		direction.y = max(0.01, random()) * flip.y
		direction:normalize()

		-- elliptical perimeter of spawn region
		distance = { 	
			x = halfScreenWidth * 1.5,
			y = halfScreenHeight * 1.5
		}		

		local screenCenter = getCameraPosition()
		enemyX = screenCenter.x + (direction.x * distance.x)
		enemyY = screenCenter.y + (direction.y * distance.y)

		local type = random(1, 5)
		createEnemy(type, enemyX, enemyY)

		spawnInc += random(1, difficulty)
		if spawnInc > 5 then
			spawnInc = 0
			type = random(1, 7)
			createEnemy(type, enemyX, -enemyY)
		end
	end
end


--[[
-- Move all enemies every frame
local function moveEnemies(dt)
	local function moveInList(list)
		for i, enemy in pairs(list) do
			-- update timers with potential pauses
			enemy.time += pauseDiff 
			enemy.stunned += pauseDiff

			-- do per-frame updates
			enemy:move()
			enemy:updateVFX()
		end
	end

	moveInList(enemyList1)
	moveInList(enemyList2)
	moveInList(enemyList3)
end


-- Calculate changes in movement for each enemy in the current frame group: 1, 2, or 3
local function updateEnemyLists(frame)
	local function updateList(enemyList)
		for i, enemy in pairs(enemyList) do
			local playerPos = getPlayerPosition()
			enemy:calculateMove(playerPos.x, playerPos.y)

			-- destroying
			if enemyList[i].dead == true then
				spawnItem(enemyList[i]:getDrop(), enemyList[i].x, enemyList[i].y)
				enemyList[i]:remove()
				tableSwapRemove(enemyList, i)
				addKill()
			end
		end
	end

	-- Update the passed lists
	local updateFrame = frame % 3 	-- 0, 1, 2	
	if updateFrame == 0 then 
		updateList(enemyList1)
	elseif updateFrame == 1 then
		updateList(enemyList2)
	else
		updateList(enemyList3)
	end
end
]]



-- Constants for speed
local lockFocus <const> = gfx.lockFocus
local unlockFocus <const> = gfx.unlockFocus
local setColor <const> = gfx.setColor
local colorBlack <const> = gfx.kColorBlack
local colorWhite <const> = gfx.kColorWhite
local colorClear <const> = gfx.kColorClear
local roundRect <const> = gfx.fillRoundRect
local drawOffset <const> = gfx.getDrawOffset
local delete <const> = deleteEnemy


-- Draw enemy healthbars
local function drawHealthBar(i, type, x, y)

	local borderWidth = HEALTHBAR_MAXWIDTH + 2
	local borderHeight = HEALTHBAR_HEIGHT + 2
	local borderRadius = HEALTHBAR_CORNER_RADIUS + 2

	local xPosOffset = floor((borderWidth - HEALTHBAR_MAXWIDTH) / 2)
	local yPosOffset = floor((borderHeight - HEALTHBAR_HEIGHT) / 2)
	local healthbarWidth = healthPercent[i] * HEALTHBAR_MAXWIDTH

	x += IMAGE_WIDTH_HALF[type] - (borderWidth * 0.5)
	y -= HEALTHBAR_OFFSET_Y

	setColor(colorBlack)
	roundRect(x, y, borderWidth, borderHeight, borderRadius)
	setColor(colorWhite)
	roundRect(x + xPosOffset, y + yPosOffset, healthbarWidth, HEALTHBAR_HEIGHT, HEALTHBAR_CORNER_RADIUS)
end


-- Update enemy movement, destruction, item drops, etc.
local function updateEnemiesLists(dt, mainLoopTime, playerPos)
	local localCurrentTime = mainLoopTime
	local offsetX, offsetY = drawOffset()
	local playerX, playerY = playerPos.x, playerPos.y


	enemiesImage:clear(colorClear)	
	lockFocus(enemiesImage)

		-- set details
		setColor(colorBlack)

		-- LOOP
		local i = 1
		local currentActiveEnemies = activeEnemies
		while i <= currentActiveEnemies do	

			-- move
			local type = enemyType[i]
			local x, y = moveSingleEnemy(dt, i, type, mainLoopTime, offsetX, offsetY, playerX, playerY)
			x, y = x + offsetX, y + offsetY

			-- delete
			if health[i] < 1 then			
				createDroppedItem(i, type)
				delete(i, currentActiveEnemies)				
				currentActiveEnemies -= 1
				i -= 1	
			
			-- draw, if not deleted
			else 
				images[i]:draw(x, y)
				drawHealthBar(i, type, x, y)
			end

			-- increment
			i += 1		
		end

	unlockFocus()
	activeEnemies = currentActiveEnemies
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



function updateEnemies(dt, mainTimePassed, mainLoopTime)
	local playerPos = getPlayerPosition()
	currentTime = mainLoopTime

	spawnMonsters()
	playdate.resetElapsedTime()
		updateEnemiesLists(dt, mainLoopTime, playerPos)
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
		gfx.drawText("Max Enemies: " .. maxEnemies, 0, 75)
		gfx.drawText("Active Enemies: " .. activeEnemies, 0, 100)
		gfx.drawText("FPS: " .. playdate.getFPS(), 0, 125)
		gfx.drawText("Main Time:" .. mainTimePassed, 0, 150)
	gfx.popContext()
	debugSprite:setImage(debugImage)
	debugSprite:add()
	-----
	]]
end