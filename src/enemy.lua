local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

class('enemy').extends(gfx.sprite)


local healthbarOffsetY = 20


function enemy:init(x, y, type, theTime)
	enemy.super.init(self)
	if type == 1 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy1')) --the fast one
		self.health = 1
		self.speed = 3
		self.damageAmount = 2
	elseif type == 2 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy2')) --the normal
		self.health = 3
		self.speed = 2
		self.damageAmount = 3
	elseif type == 3 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy3')) --the dodger
		self.health = 2
		self.speed = 4
		self.damageAmount = 1
	elseif type == 4 then
		self:setImage(gfx.image.new('Resources/Sprites/Enemy4')) --the big boi
		self.health = 10
		self.speed = 1
		self.damageAmount = 1
	end
	self.type = type
	self.time = theTime
	self.drop = math.random(0, 10)
	self.AIsmarts = 1
	self:moveTo(x, y)
	self:setTag(TAGS.enemy)
	self:setCollideRect(0, 0, self:getSize())

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
		if (theTime >= (self.time + 500)) then
			self.time = theTime
			self.health += 1
			self.healthbar:heal(1)
		end
		if (self.health == 10) then self.AIsmarts = 1 end
	else
		directionVec = vec.new(playerX - self.x, playerY - self.y)
		self.time = theTime
		if (self.type == 4 and self.health <= 4) then self.AIsmarts = 2 end
	end
	
	directionVec:normalize()

	local x = self.x + (directionVec.x * self.speed)
	local y = self.y + (directionVec.y * self.speed)

	self:moveWithCollisions(x, y)
	self.healthbar:moveTo(x, y - healthbarOffsetY)
end