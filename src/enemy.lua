local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D
local mathp <const> = playdate.math
local frame <const> = playdate.frameTimer

local halfScreenWidth <const> = playdate.display.getWidth() / 2
local halfScreenHeight <const> = playdate.display.getHeight() / 2


class('enemy').extends(gfx.sprite)

local xAxis = vec.new(1, 0)
local yAxis = vec.new(0, 1)

local healthbarOffsetY = 20
local bounceBuffer = 10
local bounceStrength = 4
local rotateSpeed = 5
local scaleHealth = 3
local scaleSpeed = 4
local scaleDamage = 5
local stunWiggleAmount = 3

ENEMY_TYPE = {
	fastBall = 1,
	normalSquare = 2,
	bat = 3,
	medic = 4,
	bulletBill = 5,
	chunkyArms = 6,
	munBag = 7
}

enemyList1 = {}
enemyList2 = {}
enemyList3 = {}
local spawnInc = 0
local currentTime = 0
local theSpawnTime = 0
local timeFromPause = 0
local pauseDiff = 0

-- +--------------------------------------------------------------+
-- |                          Creation                            |
-- +--------------------------------------------------------------+


function createEnemy(x, y, type)
	local newEnemy

	if type == ENEMY_TYPE.fastBall then
		newEnemy = fastBall(x, y)

	elseif type == ENEMY_TYPE.bat then
		newEnemy = bat(x, y)

	elseif type == ENEMY_TYPE.medic then
		newEnemy = medic(x, y)

	elseif type == ENEMY_TYPE.bulletBill then
		newEnemy = bulletBill(x, y)

	elseif type == ENEMY_TYPE.chunkyArms then
		newEnemy = chunkyArms(x, y)

	elseif type == ENEMY_TYPE.munBag then
		newEnemy = munBag(x, y)

	else --type == ENEMY_TYPE.normalSquare	-- default
		newEnemy = normalSquare(x, y)

	end

	newEnemy:add()
	-- add the enemy to the shortest list
	local first = #enemyList1
	local second = #enemyList2
	local third = #enemyList3

	if first <= second and first <= third then
		enemyList1[#enemyList1 + 1] = newEnemy

	elseif second < first and second < third then
		enemyList2[#enemyList2 + 1] = newEnemy

	else
		enemyList3[#enemyList3 + 1] = newEnemy

	end
end


-- Init shared by all enemies
function enemy:init(x, y)
	enemy.super.init(self)
	
	self.health *= (1 + math.floor(getDifficulty() / scaleHealth))
	self.damageAmount *= (1 + math.floor(getDifficulty() / scaleDamage))
	self.speed += (math.floor(getDifficulty() / scaleSpeed))
	self.fullhealth = self.health

	self.time = currentTime
	self.dead = false
	self.stunned = 0
	self.wiggleDir = 1
	self.wigglePos = vec.new(0, 0)
	
	self.AIsmarts = 1
	self:moveTo(x, y)
	self:setTag(TAGS.enemy)
	self:setZIndex(ZINDEX.enemy)
	self:setCollideRect(0, 0, self:getSize())

	self.velocity = vec.new(0, 0)
	self.directionVec = vec.new(0, 0)	
	self.previousPos = vec.new(0, 0)

	-- draw healthbar
	self.healthbar = healthbar(x, y - healthbarOffsetY, self.fullhealth)
end


-- +--------------------------------------------------------------+
-- |                         Enemy Types                          |
-- +--------------------------------------------------------------+


------------------------------------------------
				-- Fast Ball --

class('fastBall').extends(enemy)

function fastBall:init(x, y)	
	self:setImage(gfx.image.new('Resources/Sprites/enemy/Enemy1'))
	self.type = ENEMY_TYPE.fastBall
	self.health = 2
	self.speed = 5
	self.accel = 3
	self.damageAmount = 1
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.tiny
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.luck}
	self.dropPercent = { 94, 5, 1}
	self.rating = 1

	fastBall.super.init(self, x, y)		-- calling parent method needs the "." not the ":"
end

-- Just calculates the direction to move in
function fastBall:calculateMove(targetX, targetY)
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)

	fastBall.super.calculateMove(self)
end


------------------------------------------------
				-- Normal Square --

class('normalSquare').extends(enemy)

function normalSquare:init(x, y)	
	self:setImage(gfx.image.new('Resources/Sprites/enemy/Enemy2'))
	self.type = ENEMY_TYPE.normalSquare
	self.health = 5
	self.speed = 3
	self.accel = 1.5
	self.damageAmount = 5
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.medium
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.shield }
	self.dropPercent = { 85, 10, 5}
	self.rating = 1

	normalSquare.super.init(self, x, y)
end

function normalSquare:calculateMove(targetX, targetY)
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)

	normalSquare.super.calculateMove(self)
end


------------------------------------------------
					-- Bat --

class('bat').extends(enemy)

function bat:init(x, y)
	self:setImage(gfx.image.new('Resources/Sprites/enemy/Enemy3'))
	self.type = ENEMY_TYPE.bat
	self.health = 3
	self.speed = 4
	self.accel = 2
	self.damageAmount = 3
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.tiny
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.weapon, ITEM_TYPE.luck }
	self.dropPercent = { 54, 45, 1}
	self.rating = 2
	
	bat.super.init(self, x, y)
end

function bat:calculateMove(targetX, targetY)
	-- direction toward player
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)

	-- move toward player for some time
	if self.AIsmarts == 1 then
		if currentTime >= self.time then
			self.time = currentTime + 1000 --set how long in other mode
			self.AIsmarts = 2
		end

	-- move away from player for some other time
	elseif self.AIsmarts == 2 then
		self.directionVec *= -1
		if currentTime >= self.time then
			self.time = currentTime + 1500 --set how long in other mode
			self.AIsmarts = 1
		end
	end

	bat.super.calculateMove(self)
end


------------------------------------------------
				   -- Medic --

class('medic').extends(enemy)

function medic:init(x, y)
	self:setImage(gfx.image.new('Resources/Sprites/enemy/Enemy4'))
	self.type = ENEMY_TYPE.medic
	self.health = 20
	self.speed = 2
	self.accel = 4
	self.damageAmount = 2
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.large
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.absorbAll }
	self.dropPercent = { 60, 35, 5}
	self.rating = 3

	medic.super.init(self, x, y)
end

function medic:calculateMove(targetX, targetY)
	-- move toward player
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)

	-- if healing, move away from player
	if self.AIsmarts == 2 then
		self.directionVec *= -1
		if currentTime >= self.time then
			self.time = currentTime + 1000
			self:heal(2 * (1 + math.floor(getDifficulty() / scaleHealth)))
		end
		-- once finished healing, move normally again
		if self.health == self.fullhealth then self.AIsmarts = 1 end
	
	-- if moving towards the player AND when below health threshold, change move direction
	elseif self.health <= math.floor(self.fullhealth / 3) then
		self.AIsmarts = 2 
		self.velocity *= -1
	end

	medic.super.calculateMove(self)
end


------------------------------------------------
				-- Bullet Bill --

class('bulletBill').extends(enemy)

function bulletBill:init(x, y)	
	self:setImage(gfx.image.new('Resources/Sprites/enemy/Enemy5')) --the Bullet Bill
	self.type = ENEMY_TYPE.bulletBill
	self.health = 6
	self.speed = 7
	self.accel = 3
	self.damageAmount = 4
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.large
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.luck }
	self.dropPercent = { 80, 19, 1}
	self.rating = 2

	self.rotateTimerSet = 1000
	self.moveTimerSet = 2000
	self.rotation = 0
	self.savedRot = 0

	bulletBill.super.init(self, x, y)
end

function bulletBill:calculateMove(targetX, targetY)
	-- update potential pauses
	self.rotateTimerSet += pauseDiff
	self.moveTimerSet += pauseDiff

	-- don't move; find player position and rotate towards it
	if self.AIsmarts == 2 then
		self.directionVec = vec.new(targetX - self.x, targetY - self.y)
		self.velocity *= 0.05

		-- lerping to target FROM saved, so always reaches target rot at end of timer
		local targetRot = math.deg(math.atan2(self.directionVec.y, self.directionVec.x)) - 90
		targetRot = constrain(targetRot, 0, 360)
		local diff = self.rotateTimerSet - (self.time - currentTime)
		local t = clamp(diff / self.rotateTimerSet, 0, 1)
		self.rotation = mathp.lerp(self.savedRot, targetRot, t)
		self:setRotation(self.rotation)
		
		if currentTime >= self.time then
			self.time = currentTime + self.moveTimerSet
			self.AIsmarts = 1
		end

	-- move towards found player position
	elseif self.AIsmarts == 1 then
		self.savedRot = self.rotation
		if currentTime >= self.time then
			self.time = currentTime + self.rotateTimerSet
			self.AIsmarts = 2
		end
	end

	bulletBill.super.calculateMove(self)
end


------------------------------------------------
				-- Chunky Arms --

class('chunkyArms').extends(enemy)

function chunkyArms:init(x, y)	
	self:setImage(gfx.image.new('Resources/Sprites/enemy/Enemy6'))
	self.type = ENEMY_TYPE.chunkyArms
	self.health = 66
	self.speed = 1
	self.accel = 2
	self.damageAmount = 10
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.large
	self.drop = { ITEM_TYPE.exp16, ITEM_TYPE.luck }
	self.dropPercent = { 95, 5}
	self.rating = 3

	chunkyArms.super.init(self, x, y)
end

function chunkyArms:calculateMove(targetX, targetY)
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)
	if currentTime >= self.time then
		self.time = currentTime + 500
		if self.health < (self.fullhealth / 2) then self.speed += 0.3 end
		if self.speed > (3 + math.floor(getDifficulty() / scaleDamage)) then self.speed = (3 + math.floor(getDifficulty() / scaleDamage)) end
		if self.health < self.fullhealth then 
			self:heal(1 + math.floor(getDifficulty() / scaleHealth))
		end
	end

	chunkyArms.super.calculateMove(self)
end

------------------------------------------------
				-- Mun Bag --

class('munBag').extends(enemy)

function munBag:init(x, y)	
	self:setImage(gfx.image.new('Resources/Sprites/enemy/Enemy16'))
	self.type = ENEMY_TYPE.munBag
	self.health = 1 + math.floor(getMun() / 10)
	self.speed = 1
	self.accel = 1
	self.damageAmount = 1
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.tiny
	self.drop = { ITEM_TYPE.mun2, ITEM_TYPE.mun10, ITEM_TYPE.mun50 }
	local tLuck1 = math.floor(getLuck()/4)
	local tLuck2 = math.floor(getLuck()/20)
	self.dropPercent = { (90 - tLuck1 - tLuck2), (10 + tLuck1), tLuck2}
	self.rating = 1

	munBag.super.init(self, x, y)
end

function munBag:calculateMove(targetX, targetY)
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)
	if currentTime >= self.time then
		self.time = currentTime + 500
		if self.health < (self.fullhealth / 2) then self.speed += 0.3 end
		if self.speed > (3 + math.floor(getDifficulty() / scaleDamage)) then self.speed = (3 + math.floor(getDifficulty() / scaleDamage)) end
		if self.health < self.fullhealth then 
			self:heal(1 + math.floor(getDifficulty() / scaleHealth))
		end
	end

	munBag.super.calculateMove(self)
end


-- +--------------------------------------------------------------+
-- |                         Interaction                          |
-- +--------------------------------------------------------------+


function enemy:potentialStun()
	if math.random(0,99) < getStun() then 
		self.stunned = currentTime + 100
		self.wigglePos = vec.new(self.x, self.y)
		self.velocity = vec.new(0, 0)
	end
end


function enemy:applyKnockback(force)
	if force == 0 then do return end end

	local impactDir = (vec.new(self.x, self.y) - getPlayerPosition()):normalized()
	self.velocity += impactDir * force
end


function enemy:heal(amount)
	self.health += amount
	if self.health > self.fullhealth then
		self.health = self.fullhealth
	end
	self.healthbar:updateHealth(self.health)
end


function enemy:damage(amount)
	self.health -= amount
	if self.health <= 0 then 
		amount += self.health 	-- adjusts damage dealt to only track the amount it took to bring health to 0
		self.health = 0
		self.dead = true
	end
	self.healthbar:updateHealth(self.health)
	addDamageDealt(amount)
end


-- Gets an item drop from this enemy's list of items from the given percent chances
function enemy:getDrop()
	local index = 1
	local total = 0

	local percent = math.random(1, 100)
	for i = 1, #self.drop do
		total += self.dropPercent[i]
		if percent <= total then
			index = i
			break
		end
	end
	tmpItem = self.drop[index]
	if tmpItem == ITEM_TYPE.exp1 then
		tmpItem = expDropped(self.rating)
	end
	return tmpItem
end


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


-- +--------------------------------------------------------------+
-- |                           Movement                           |
-- +--------------------------------------------------------------+


function enemy:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.player then
		player:damage(self.damageAmount, self.shakeStrength, self.x, self.y)
		self:damage(player:getPlayerReflectDamage())
		return 'bounce'
	else
		return 'overlap'
	end
end


-- Movement calculation shared by all enemies
function enemy:calculateMove()

	-- Stun - stops enemy from moving itself
	if self.stunned > 0 then
		do return end
	end

	-- Normal movement
	self.directionVec:normalize()	-- Normalize the direction now that velocity is being calculated

	local maxSpeedChange = self.accel * dt * 3 -- mul by 3 b/c this is only done once every 3 frames
	local currentX = self.velocity:dotProduct(xAxis)
	local currentY = self.velocity:dotProduct(yAxis)
	local newX = moveTowards(currentX, self.directionVec.x * self.speed, maxSpeedChange)
	local newY = moveTowards(currentY, self.directionVec.y * self.speed, maxSpeedChange)

	self.velocity += (xAxis * (newX - currentX)) + (yAxis * (newY - currentY))
end


-- Movement shared by all enemies
function enemy:move()

	-- Moving the enemy and attached UI
	local x = self.x + self.velocity.x
	local y = self.y + self.velocity.y
	_, _, collisions = self:moveWithCollisions(x, y)
	self.healthbar:moveTo(x, y - healthbarOffsetY)

	-- Bounce interactions
	for i = 1, #collisions do
		local bouncePoint = collisions[i].bounce		
		
		-- If a bounce was found, the perform necessary steps
		if bouncePoint ~= nil then			
			-- Get player position
			local playerSprite = collisions[i].other
			local playerDirToEnemy = vec.new(playerSprite.x - self.previousPos.x, playerSprite.y - self.previousPos.y)			

			-- Determine if player is moving towards this enemy -- need to use prev pos b/c current pos is displaced from 'moveWithCollisions'
			local velocityDot = getPlayerVelocity():dotProduct(playerDirToEnemy)

			-- If player is NOT moving towards enemy, then perform normal bounce - dot product is positive when moving away
			local bounceDir
			if velocityDot >= 0 then
				bounceDir = vec.new(bouncePoint.x - playerSprite.x, bouncePoint.y - playerSprite.y):normalized()				

			-- else player is moving TOWARDS enemy (negative dot), so teleport enemy to a point in front of player's next position, FROM prev pos
			else
				bounceDir = vec.new(self.previousPos.x - playerSprite.x, self.previousPos.y - playerSprite.y):normalized()

				local bounceOffset = vec.new(self:getSize())				
				bounceOffset.x = ((bounceOffset.x * 0.5) * bounceDir.x) + self.previousPos.x
				bounceOffset.y = ((bounceOffset.y * 0.5) * bounceDir.y) + self.previousPos.y

				self:moveTo(bounceOffset.x, bounceOffset.y)
				self.healthbar:moveTo(bounceOffset.x, bounceOffset.y - healthbarOffsetY)	
			end	

			-- After finding bounce, apply force to enemy velocity
			self.velocity = bounceDir * bounceStrength 		
		end
	end

	-- After movement and possible bounces are finished, then update previous position
	self.previousPos = vec.new(self.x, self.y)

end


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

end

-- +--------------------------------------------------------------+
-- |                          Management                          |
-- +--------------------------------------------------------------+

function spawnMonsters()
	-- 
	if Unpaused then theSpawnTime += (currentTime - timeFromPause) end

	if currentTime >= theSpawnTime then
		local difficulty = getDifficulty()
		rndLoc = math.random(1,8)
		theSpawnTime = currentTime + 3200 - 200 * difficulty

		-- either -1 or 1
		flip = {
			x = (math.random(0,1) * 2) - 1,
			y = (math.random(0,1) * 2) - 1
		}

		-- random on unit circle - protects against randomly getting 0
		direction = vec.new(0, 0)
		direction.x = math.max(0.01, math.random()) * flip.x
		direction.y = math.max(0.01, math.random()) * flip.y
		direction:normalize()

		-- elliptical perimeter of spawn region
		distance = { 	
			x = halfScreenWidth * 1.5,
			y = halfScreenHeight * 1.5
		}		

		local screenCenter = getCameraPosition()
		enemyX = screenCenter.x + (direction.x * distance.x)
		enemyY = screenCenter.y + (direction.y * distance.y)

		local eType = math.random(1, 5)
		createEnemy(enemyX, enemyY, eType)

		spawnInc += math.random(1, difficulty)
		if spawnInc > 5 then
			spawnInc = 0
			eType = math.random(1, 7)
			createEnemy(-enemyX, -enemyY, eType)
		end
	end
end


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
			if enemyList[i].dead == true then
				newItem = item(enemyList[i].x, enemyList[i].y, enemyList[i]:getDrop())
				newItem:add()
				items[#items + 1] = newItem
				enemyList[i]:remove()
				--print("removed enemy")
				table.remove(enemyList, i)
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


function clearEnemies()
	local function clearList(list)
		for i = 1, #list do		
			list[1]:remove()
			table.remove(list, 1)			
		end
	end

	clearList(enemyList1)
	clearList(enemyList2)
	clearList(enemyList3)

	theSpawnTime = 0
	spawnInc = 0
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


function updateEnemies(dt, frame)
	currentTime = playdate.getCurrentTimeMilliseconds()

	-- PAUSED - need to save the time
	if Unpaused == false then
		if timeFromPause == 0 then timeFromPause = currentTime end

	-- NOT PAUSED - save the time difference from how long we were paused
	else 
		if pauseDiff == 0 then pauseDiff = currentTime - timeFromPause end
	end

	spawnMonsters()
	updateEnemyLists(frame)
	moveEnemies(dt)

	-- NOT paused and finished with reset
	if Unpaused == true and pauseDiff ~= 0 then
		pauseDiff = 0
		timeFromPause = 0
	end
end