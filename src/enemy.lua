local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D
local mathp <const> = playdate.math

class('enemy').extends(gfx.sprite)


local healthbarOffsetY = 20
local enemyAcceleration = 0.5
local maxSpeedCap = 8
local bounceBuffer = 3
local rotateSpeed = 5
local scaleHealth = 3
local scaleSpeed = 4
local scaleDamage = 5

ENEMY_TYPE = {
	fastBall = 1,
	normalSquare = 2,
	bat = 3,
	bigSquare = 4,
	bulletBill = 5,
	chunkyArms = 6
}


function createEnemy(x, y, type, theTime)
	if type == ENEMY_TYPE.fastBall then
		return fastBall(x, y, theTime)

	elseif type == ENEMY_TYPE.normalSquare then
		return normalSquare(x, y, theTime)

	elseif type == ENEMY_TYPE.bat then
		return bat(x, y, theTime)

	elseif type == ENEMY_TYPE.bigSquare then
		return bigSquare(x, y, theTime)

	elseif type == ENEMY_TYPE.bulletBill then
		return bulletBill(x, y, theTime)

	elseif type == ENEMY_TYPE.chunkyArms then
		return chunkyArms(x, y, theTime)

	end
end


-- Init shared by all enemies
function enemy:init(x, y, theTime)
	enemy.super.init(self)
	
	self.health *= (1 + math.floor(getDifficulty() / scaleHealth))
	self.damageAmount *= (1 + math.floor(getDifficulty() / scaleDamage))
	self.targetSpeed += (math.floor(getDifficulty() / scaleSpeed))
	self.fullhealth = self.health

	self.time = theTime
	
	self.AIsmarts = 1
	self:moveTo(x, y)
	self:setTag(TAGS.enemy)
	self:setZIndex(ZINDEX.enemy)
	self:setCollideRect(0, 0, self:getSize())

	self.accel = enemyAcceleration
	self.velocity = vec.new(0, 0)
	self.directionVec = vec.new(0, 0)	

	-- draw healthbar
	self.healthbar = healthbar(x, y - healthbarOffsetY, self.health)
end


-- +--------------------------------------------------------------+
-- |                         Enemy Types                          |
-- +--------------------------------------------------------------+


------------------------------------------------
				-- Fast Ball --

class('fastBall').extends(enemy)

function fastBall:init(x, y, theTime)	
	self:setImage(gfx.image.new('Resources/Sprites/Enemy1'))
	self.type = ENEMY_TYPE.fastBall
	self.health = 2
	self.speed = 0
	self.targetSpeed = 3
	self.damageAmount = 2
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.tiny
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.luck}
	self.dropPercent = { 94, 5, 1}
	self.rating = 1

	fastBall.super.init(self, x, y, theTime)
end

function fastBall:move(targetX, targetY, theTime)
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)

	fastBall.super.move(self, targetX, targetY, theTime)	-- calling parent method needs the "." not the ":"
end


------------------------------------------------
				-- Normal Square --

class('normalSquare').extends(enemy)

function normalSquare:init(x, y, theTime)	
	self:setImage(gfx.image.new('Resources/Sprites/Enemy2'))
	self.type = ENEMY_TYPE.normalSquare
	self.health = 5
	self.speed = 0
	self.targetSpeed = 2
	self.damageAmount = 3
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.medium
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.shield }
	self.dropPercent = { 75, 20, 5}
	self.rating = 1

	normalSquare.super.init(self, x, y, theTime)
end

function normalSquare:move(targetX, targetY, theTime)
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)

	normalSquare.super.move(self, targetX, targetY, theTime)
end


------------------------------------------------
					-- Bat --

class('bat').extends(enemy)

function bat:init(x, y, theTime)
	self:setImage(gfx.image.new('Resources/Sprites/Enemy3'))
	self.type = ENEMY_TYPE.bat
	self.health = 3
	self.speed = 0
	self.targetSpeed = 4
	self.damageAmount = 1
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.tiny
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.weapon, ITEM_TYPE.luck }
	self.dropPercent = { 59, 40, 1}
	self.rating = 2

	bat.super.init(self, x, y, theTime)
end

function bat:move(targetX, targetY, theTime)
	-- direction toward player
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)

	-- move towards player for some time
	if self.AIsmarts == 1 then
		if theTime >= self.time then
			self.time = theTime + 1500
			self.AIsmarts = 2
		end

	-- move away from player for some other time
	elseif self.AIsmarts == 2 then
		self.directionVec *= -1
		if theTime >= self.time then
			self.time = theTime + 1200
			self.AIsmarts = 1
		end
	end

	bat.super.move(self, targetX, targetY, theTime)
end


------------------------------------------------
				   -- Big Square --

class('bigSquare').extends(enemy)

function bigSquare:init(x, y, theTime)
	self:setImage(gfx.image.new('Resources/Sprites/Enemy4'))
	self.type = ENEMY_TYPE.bigSquare
	self.health = 20
	self.speed = 0
	self.targetSpeed = 1
	self.damageAmount = 1
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.large
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.absorbAll }
	self.dropPercent = { 60, 35, 5}
	self.rating = 3

	bigSquare.super.init(self, x, y, theTime)
end

function bigSquare:move(targetX, targetY, theTime)
	-- move toward player
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)

	-- if healing, move away from player
	if self.AIsmarts == 2 then
		self.directionVec *= -1
		if theTime >= self.time then
			self.time = theTime + 1000
			self.health += 2
			self.healthbar:heal(2)
		end
		-- once finished healing, move normally again
		if self.health == self.fullhealth then self.AIsmarts = 1 end
	
	-- if moving towards the playere AND when below health threshold, change move direction
	elseif self.health <= math.floor(self.fullhealth / 3) then
		self.AIsmarts = 2 
	end

	bigSquare.super.move(self, targetX, targetY, theTime)	
end


------------------------------------------------
				-- Bullet Bill --

class('bulletBill').extends(enemy)

function bulletBill:init(x, y, theTime)	
	self:setImage(gfx.image.new('Resources/Sprites/Enemy5')) --the Bullet Bill
	self.type = ENEMY_TYPE.bulletBill
	self.health = 6
	self.speed = 0
	self.targetSpeed = 5
	self.damageAmount = 2
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.large
	self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.luck }
	self.dropPercent = { 60, 39, 1}
	self.rating = 2

	self.rotateTimerSet = 1000
	self.moveTimerSet = 2000
	self.rotation = 0
	self.savedRot = 0

	bulletBill.super.init(self, x, y, theTime)
end

function bulletBill:move(targetX, targetY, theTime)
	-- don't move; find player position and rotate towards it
	if self.AIsmarts == 1 then
		self.velocity = vec.new(0, 0)
		self.directionVec = vec.new(targetX - self.x, targetY - self.y)

		-- lerping to target FROM saved, so always reaches target rot at end of timer
		local targetRot = math.deg(math.atan2(self.directionVec.y, self.directionVec.x)) - 90
		targetRot = constrain(targetRot, 0, 360)
		local diff = self.rotateTimerSet - (self.time - theTime)
		local t = clamp(diff / self.rotateTimerSet, 0, 1)
		self.rotation = mathp.lerp(self.savedRot, targetRot, t)
		self:setRotation(self.rotation)
		
		if theTime >= self.time then
			self.time = theTime + self.moveTimerSet
			self.AIsmarts = 2
		end

	-- move towards found player position
	elseif self.AIsmarts == 2 then
		self.savedRot = self.rotation
		if theTime >= self.time then
			self.time = theTime + self.rotateTimerSet
			self.AIsmarts = 1
		end
	end

	bulletBill.super.move(self, targetX, targetY, theTime)
end


------------------------------------------------
				-- Chunky Arms --

class('chunkyArms').extends(enemy)

function chunkyArms:init(x, y, theTime)	
	self:setImage(gfx.image.new('Resources/Sprites/Enemy6'))
	self.type = ENEMY_TYPE.chunkyArms
	self.health = 66
	self.speed = 0
	self.targetSpeed = 0.5
	self.damageAmount = 5
	self.shakeStrength = CAMERA_SHAKE_STRENGTH.large
	self.drop = { ITEM_TYPE.exp16, ITEM_TYPE.luck }
	self.dropPercent = { 95, 5}
	self.rating = 3

	chunkyArms.super.init(self, x, y, theTime)
end

function chunkyArms:move(targetX, targetY, theTime)
	self.directionVec = vec.new(targetX - self.x, targetY - self.y)
	if theTime >= self.time then
		self.time = theTime + 500
		if self.health < (self.fullhealth / 3) then self.targetSpeed += 0.3 end
		if self.targetSpeed > 4 then self.targetSpeed = 4 end
		if self.health < self.fullhealth then 
			self.health += 1
			self.healthbar:heal(1)
		end
	end

	chunkyArms.super.move(self, targetX, targetY)
end


-- +--------------------------------------------------------------+
-- |                             Misc                             |
-- +--------------------------------------------------------------+


function enemy:damage(amount)
	self.health -= amount
	if self.health <= 0 then self.health = 0 end

	self.healthbar:damage(amount)
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


-- Movement shared by all enemies
function enemy:move(playerX, playerY)

	-- Normalize the direction now that velocity is being calculated
	self.directionVec:normalize()
	
	-- velocity trying to get to direction - variable speed, mainly for bounce
	self.velocity.x = clamp(self.velocity.x + self.directionVec.x * self.accel, -self.speed, self.speed)
	self.velocity.y = clamp(self.velocity.y + self.directionVec.y * self.accel, -self.speed, self.speed)
	if self.speed ~= self.targetSpeed then
		self.speed = moveTowards(self.speed, self.targetSpeed, self.accel)
	end

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

			-- Setting velocity to bounce
			local bounceDir = vec.new(bouncePoint.x - playerX, bouncePoint.y - playerY):normalized()
			self.speed = maxSpeedCap
			self.velocity = bounceDir * maxSpeedCap

			-- If player is NOT moving towards enemy, don't solve warp problem - more natural movement
			local normal = collisions[i].normal
			local exitBounce = 0
			if normal.x == inputX then exitBounce += 1 end		-- horizontal sides
			if normal.y == inputY then exitBounce += 1 end 		-- vertical sides
			if exitBounce == 0 then return end

			-- Teleport the enemy a little bit away from the player on the bounce - solves warping issue during bounce when player moves towards enemy	
			local bounceOffset = vec.new(self:getSize())
			bounceOffset.x = (((bounceOffset.x * 0.5) + bounceBuffer) * bounceDir.x) + self.x
			bounceOffset.y = (((bounceOffset.y * 0.5) + bounceBuffer) * bounceDir.y) + self.y
			self:moveTo(bounceOffset.x, bounceOffset.y)
			self.healthbar:moveTo(bounceOffset.x, bounceOffset.y - healthbarOffsetY)
		end
	end
end