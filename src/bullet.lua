
local gfx <const> = playdate.graphics

class('bullet').extends(gfx.sprite)


function bullet:init(x, y, rotation, newLifeTime)
	bullet.super.init(self)
	self:setImage(gfx.image.new('Resources/Sprites/Bullet1'))
	self:moveTo(x, y)
	self:setRotation(rotation)
	self:setTag(TAGS.weapon)
	self:setCollideRect(0, 0, self:getSize())

	self.lifeTime = newLifeTime
end


function bullet:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.player then
		return 'overlap'
	elseif tag == TAGS.weapon then
		return 'overlap'
	elseif tag == TAGS.item then
		return 'overlap'
	elseif tag == TAGS.enemy then
		other:damage(1)
		self.lifeTime = 0
		return 'freeze'
	else --tag == walls
		self.lifeTime = 0
		return 'freeze'
	end
end


function bullet:move(speed)
	rad = math.rad(self:getRotation() - 90)
	local x = self.x + math.cos(rad) * speed * dt
	local y = self.y + math.sin(rad) * speed * dt
	self:moveWithCollisions(x, y) -- need to check collisions, find the point a collision would happen, move there, then delete
end
