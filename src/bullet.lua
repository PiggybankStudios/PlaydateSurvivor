
local gfx <const> = playdate.graphics

class('bullet').extends(gfx.sprite)


function bullet:init(x, y, rotation, newLifeTime, type)
	bullet.super.init(self)
	if type == 2 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletCannon'))
		self.speed = 400
		self.damage = 5
	elseif type == 3 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletMinigun'))
		self.speed = 100
		self.damage = 1
	elseif type == 4 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletShotgun'))
		self.speed = 150
		self.damage = 1
	else
		self:setImage(gfx.image.new('Resources/Sprites/BulletPeagun'))
		self.speed = 200
		self.damage = 2
	end
	
	self:moveTo(x, y)
	self:setRotation(rotation)
	self:setTag(TAGS.weapon)
	self:setZIndex(ZINDEX.weapon)
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
		other:damage(self.damage)
		self.lifeTime = 0
		return 'freeze'
	else --tag == walls
		self.lifeTime = 0
		return 'freeze'
	end
end


function bullet:move()
	rad = math.rad(self:getRotation() - 90)
	local x = self.x + math.cos(rad) * self.speed * dt
	local y = self.y + math.sin(rad) * self.speed * dt
	self:moveWithCollisions(x, y) -- need to check collisions, find the point a collision would happen, move there, then delete
end
