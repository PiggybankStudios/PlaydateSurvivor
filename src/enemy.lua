local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

class('enemy').extends(gfx.sprite)


local healthbarOffsetY = 20
local enemyAcceleration = 0.5
local maxSpeedCap = 8
local bounceBuffer = 3


function enemy:init(x, y, type, theTime)
	enemy.super.init(self)
	if type == 1 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy1')) --the fast one
		self.health = 2
		self.speed = 0
		self.targetSpeed = 3
		self.damageAmount = 2
		self.shakeStrength = CAMERA_SHAKE_STRENGTH.small
	elseif type == 2 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy2')) --the normal
		self.health = 5
		self.speed = 0
		self.targetSpeed = 2
		self.damageAmount = 3
		self.shakeStrength = CAMERA_SHAKE_STRENGTH.medium
	elseif type == 3 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy3')) --the dodger
		self.health = 3
		self.speed = 0
		self.targetSpeed = 4
		self.damageAmount = 1
		self.shakeStrength = CAMERA_SHAKE_STRENGTH.tiny
	elseif type == 4 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy4')) --the big boi
		self.health = 20
		self.speed = 0
		self.targetSpeed = 1
		self.damageAmount = 1
		self.shakeStrength = CAMERA_SHAKE_STRENGTH.large
	end
	self.type = type
	self.time = theTime
	self.drop = math.random(0, 100)
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