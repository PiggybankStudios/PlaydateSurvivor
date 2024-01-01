local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

class('enemy').extends(gfx.sprite)


local healthbarOffsetY = 20
local enemyAcceleration = 0.5
local maxSpeedCap = 8
local bounceBuffer = 3
local scaleHealth = 3
local scaleSpeed = 4
local scaleDamage = 5


function enemy:init(x, y, type, theTime)
	enemy.super.init(self)
	if type == 1 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy1')) --the fast one
		self.health = 2
		self.speed = 0
		self.targetSpeed = 3
		self.damageAmount = 2
		self.shakeStrength = CAMERA_SHAKE_STRENGTH.tiny
		self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health}
		self.dropPercent = { 95, 5}
		self.rating = 1
	elseif type == 2 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy2')) --the normal
		self.health = 5
		self.speed = 0
		self.targetSpeed = 2
		self.damageAmount = 3
		self.shakeStrength = CAMERA_SHAKE_STRENGTH.medium
		self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.shield }
		self.dropPercent = { 75, 20, 5}
		self.rating = 1
	elseif type == 3 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy3')) --the dodger
		self.health = 3
		self.speed = 0
		self.targetSpeed = 4
		self.damageAmount = 1
		self.shakeStrength = CAMERA_SHAKE_STRENGTH.tiny
		self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.weapon }
		self.dropPercent = { 60, 40}
		self.rating = 2
	elseif type == 4 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy4')) --the big boi
		self.health = 20
		self.speed = 0
		self.targetSpeed = 1
		self.damageAmount = 1
		self.shakeStrength = CAMERA_SHAKE_STRENGTH.large
		self.drop = { ITEM_TYPE.exp1, ITEM_TYPE.health, ITEM_TYPE.absorbAll }
		self.dropPercent = { 60, 35, 5}
		self.rating = 3
	end
	self.health *= (1 + math.floor(getDifficulty() / scaleHealth))
	self.damageAmount *= (1 + math.floor(getDifficulty() / scaleDamage))
	self.targetSpeed += (math.floor(getDifficulty() / scaleSpeed))
	self.type = type
	self.time = theTime	
	self.AIsmarts = 1
	self:moveTo(x, y)
	self:setTag(TAGS.enemy)
	self:setZIndex(ZINDEX.enemy)
	self:setCollideRect(0, 0, self:getSize())

	self.accel = enemyAcceleration
	self.velocity = vec.new(0, 0)

	-- draw healthbar
	self.healthbar = healthbar(x, y - healthbarOffsetY, self.health)
end


function enemy:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.player then
		player:damage(self.damageAmount, self.shakeStrength, self.x, self.y)
		self:damage(player:getPlayerReflectDamage())
		return 'bounce'
	elseif tag == TAGS.weapon then
		return 'freeze'
	elseif tag == TAGS.enemy then
		return 'overlap'
	else --tag == walls
		return 'overlap'
	end
end


function enemy:damage(amount)
	self.health -= amount
	if self.health <= 0 then self.health = 0 end

	self.healthbar:damage(amount)
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

function enemy:move(playerX, playerY, theTime)
	if (self.type == 3 and self.AIsmarts == 1) then
		directionVec = vec.new(playerX - self.x, playerY - self.y)
		if (theTime >= (self.time + 1500)) then
			self.time = theTime
			self.AIsmarts = 2
		end
	elseif (self.type == 3 and self.AIsmarts == 2) then
		directionVec = vec.new(self.x - playerX, self.y - playerY)
		if (theTime >= (self.time + 1200)) then
			self.time = theTime
			self.AIsmarts = 1
		end
	elseif (self.type == 4 and self.AIsmarts == 2) then
		directionVec = vec.new(self.x - playerX, self.y - playerY)
		if (theTime >= (self.time + 1000)) then
			self.time = theTime
			self.health += 2
			self.healthbar:heal(2)
		end
		if (self.health == 20) then self.AIsmarts = 1 end
	else
		directionVec = vec.new(playerX - self.x, playerY - self.y)
		self.time = theTime
		if (self.type == 4 and self.health <= 6) then self.AIsmarts = 2 end
	end
	
	directionVec:normalize()

	-- velocity trying to get to direction - variable speed
	self.velocity.x = clamp(self.velocity.x + directionVec.x * self.accel, -self.speed, self.speed)
	self.velocity.y = clamp(self.velocity.y + directionVec.y * self.accel, -self.speed, self.speed)
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
		local normal = collisions[i].normal
		if bouncePoint ~= nil then
			-- Setting velocity to bounce
			local bounceDir = vec.new(bouncePoint.x - playerX, bouncePoint.y - playerY):normalized()
			self.speed = maxSpeedCap
			self.velocity = bounceDir * maxSpeedCap

			-- If player is NOT moving towards enemy, don't solve warp problem - more natural movement
			local exitBounce = 0
			if normal.x == -1 and inputX == -1 then exitBounce += 1 end		-- left side, pressing left
			if normal.x == 1 and inputX == 1 then exitBounce += 1 end 		-- right side, pressing right
			if normal.y == -1 and inputY == -1 then exitBounce += 1 end 	-- top side, pressing up
			if normal.y == 1 and inputY == 1 then exitBounce += 1 end 		-- bot side, pressing down
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