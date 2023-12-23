local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

class('enemy').extends(gfx.sprite)


local healthbarOffsetY = 20


function enemy:init(x, y, health, speed, damageAmount)
	enemy.super.init(self)
	self:setImage(gfx.image.new('Resources/Sprites/Enemy2'))
	self:moveTo(x, y)
	self:setTag(TAGS.enemy)
	self:setCollideRect(0, 0, self:getSize())

	self.health = health
	self.speed = speed
	self.damageAmount = damageAmount

	-- draw healthbar
	self.healthbar = healthbar(x, y - healthbarOffsetY, self.health)
end


function enemy:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.player then
		player:damage(self.damageAmount)
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
	directionVec = vec.new(playerX - self.x, playerY - self.y)
	directionVec:normalize()

	local x = self.x + (directionVec.x * self.speed)
	local y = self.y + (directionVec.y * self.speed)

	self:moveWithCollisions(x, y)
	self.healthbar:moveTo(x, y - healthbarOffsetY)
end