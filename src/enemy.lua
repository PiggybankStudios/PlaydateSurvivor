local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

class('enemy').extends(gfx.sprite)


local healthbarOffsetY = 20
local bounceSpeed = 10
local bounceOffsetDistance = 5


function enemy:init(x, y, health, damageAmount, maxSpeed, accel)
	enemy.super.init(self)
	self:setImage(gfx.image.new('Resources/Sprites/Enemy2'))
	self:moveTo(x, y)
	self:setTag(TAGS.enemy)
	self:setCollideRect(0, 0, self:getSize())

	self.health = health
	self.damageAmount = damageAmount
	self.maxSpeed = maxSpeed
	self.accel = accel
	self.velocity = vec.new(0, 0)
	--self.bounceDir = vec.new(0, 0)

	-- draw healthbar
	self.healthbar = healthbar(x, y - healthbarOffsetY, self.health)
end


function enemy:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.player then
		player:damage(self.damageAmount)
		--self.velocity = -self.velocity:normalized():scaledBy(bounceSpeed)
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
	if self.health <= 0 then self.healt = 0 end

	self.healthbar:damage(amount)
end


function enemy:move(playerX, playerY)
	-- direction to move
	local directionVec = vec.new(playerX - self.x, playerY - self.y)
	directionVec:normalize()

	-- velocity trying to get to direction
	self.velocity.x = clamp(self.velocity.x + directionVec.x * self.accel, -self.maxSpeed, self.maxSpeed)
	self.velocity.y = clamp(self.velocity.y + directionVec.y * self.accel, -self.maxSpeed, self.maxSpeed)
	local x = self.x + self.velocity.x
	local y = self.y + self.velocity.y

	-- Moving the enemy and attached UI
	_, _, collisions = self:moveWithCollisions(x, y)
	self.healthbar:moveTo(x, y - healthbarOffsetY)

	-- Bounce interactions
	for i = 1, #collisions do
		local bouncePoint = collisions[i].bounce
		if bouncePoint ~= nil then
			--print("velocity: " .. self.velocity.x .. ", " .. self.velocity.y)
			local bounceDir = vec.new(bouncePoint.x - playerX, bouncePoint.y - playerY):normalized()
			self.velocity = bounceDir * bounceSpeed

			local bounceOffset = bounceDir * bounceOffsetDistance
			self:moveTo(bounceOffset.x, bounceOffset.y)
			print("bounce: " .. bouncePoint.x .. ", " .. bouncePoint.y .. "  --  Player Pos: " .. playerX .. ", " .. playerY)
		end
	end

end