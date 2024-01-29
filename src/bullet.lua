local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

class('bullet').extends(gfx.sprite)

function bullet:init(x, y, rotation, newLifeTime, type, index, tier)
	bullet.super.init(self)
	local whichAngle = getBulletAngle(rotation)
	if type == 2 then
		self:setImage(whichBullet(type,whichAngle))
		self.speed = getPayerBulletSpeed() * 8
		self.damage = 4 + getPlayerGunDamage() * (1 + tier)
		self.knockback = 4
		self:setScale(tier)
	elseif type == 3 then
		self:setImage(whichBullet(type,whichAngle))
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.ceil(getPlayerGunDamage() / 2) --round up
		self.knockback = 0
	elseif type == 4 then
		self:setImage(whichBullet(type,whichAngle))
		self.speed = getPayerBulletSpeed() * 3
		self.damage = 1 + math.floor(getPlayerGunDamage() / 2) --round down
		self.knockback = 2
	elseif type == 5 then
		self:setImage(whichBullet(type,whichAngle))
		self.speed = getPayerBulletSpeed() * 3
		self.damage = 2 + getPlayerGunDamage()
		self.knockback = 3
	elseif type == 6 then
		self:setImage(whichBullet(type,whichAngle))
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 2 + getPlayerGunDamage()
		self.knockback = 0
	elseif type == 7 then
		self:setImage(whichBullet(type,whichAngle))
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.floor(getPlayerGunDamage() / 3)
		self.knockback = 1
		self:setScale(tier)
	elseif type == 8 then
		--self:setImage(gfx.image.new('Resources/Sprites/bullet/BulletWavegun'))
		self:setImage(whichBullet(type,whichAngle))
		--self:setRotation(rotation)
		if whichAngle == 2 or whichAngle == 4 or whichAngle == 6 or whichAngle == 8 then self:setRotation(45) end
		self.speed = getPayerBulletSpeed()
		self.damage = 4 + getPlayerGunDamage()
		self.knockback = 0
	elseif type == 99 then
		self:setImage(whichBullet(type,whichAngle))
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.floor(getPlayerGunDamage() / 2)
		self.knockback = 0
	else
		self:setImage(whichBullet(type,whichAngle))
		self.speed = getPayerBulletSpeed() * 4
		self.damage = 2 + getPlayerGunDamage()
		self.knockback = 1
	end
	
	self:moveTo(x, y)
	--self:setRotation(rotation)
	self.rot = rotation
	self:setTag(TAGS.weapon)
	self:setZIndex(ZINDEX.weapon)
	self:setCollideRect(0, 0, self:getSize())
	self.mode = 0
	self.type = type
	self.index = index
	self.lifeTime = newLifeTime
	self.timer = 0
	self.tier = tier
	addShot()
end

function getBulletAngle(rot)
	local angles = math.floor(rot / 22.5)
	angles = angles % 16
	if angles < 0 then angles += 16 end
	
	if angles == 0 or angles == 15 then return 1
	elseif angles == 1 or angles == 2 then return 2
	elseif angles == 3 or angles == 4 then return 3
	elseif angles == 5 or angles == 6 then return 4
	elseif angles == 7 or angles == 8 then return 5
	elseif angles == 9 or angles == 10 then return 6
	elseif angles == 11 or angles == 12 then return 7
	elseif angles == 13 or angles == 14 then return 8
	else return 1 end
end

function bullet:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.player then
		if self.type == 7 and self.mode == 2 then self.lifeTime = 0 end
		return 'overlap'
	elseif tag == TAGS.weapon then
		return 'overlap'
	elseif tag == TAGS.item then
		return 'overlap'
	elseif tag == TAGS.itemAbsorber then
		return 'overlap'
	elseif tag == TAGS.enemy then
		if self.type == 7 then
			if self.timer < playdate.getCurrentTimeMilliseconds() then -- will have a local current time when having bullet class manage itself
				other:damage(self.damage)
				other:potentialStun()
				self.timer = getCurrTime() + 50
			end
			return 'overlap'
		elseif self.type == 8 then
			if self.timer < getCurrTime() then
				other:damage(self.damage)
				other:potentialStun()
				self.timer = playdate.getCurrentTimeMilliseconds() + 50
			end
			return 'overlap'
		else
			self.lifeTime = 0 
			other:damage(self.damage)
			other:potentialStun()
			other:applyKnockback(self.knockback)
			return 'freeze'
		end
	else --tag == walls
		self.lifeTime = 0
		return 'freeze'
	end
end
		
function bullet:move(currTime)
	if self.type == 7 then
		if self.mode == 0 then
			local rad = math.rad(self.rot - 90)
			local x = self.x + math.cos(rad) * self.speed * dt
			local y = self.y + math.sin(rad) * self.speed * dt
			self:moveWithCollisions(x, y)
			if self.lifeTime - 5000 < currTime then self.mode = 1 end
		elseif self.mode == 1 then
			self.rot -= 25
			self:setImage(whichBullet(self.type,getBulletAngle(self.rot)))
			local rad = math.rad(self.rot - 90)
			local x = self.x + math.cos(rad) * self.speed * dt
			local y = self.y + math.sin(rad) * self.speed * dt
			self:moveWithCollisions(x, y)
			if self.lifeTime - 3000 < currTime then self.mode = 2 end
		elseif self.mode == 2 then
			local directionVec = vec.new(getPlayerx() - self.x, getPlayery() - self.y)
			self.rot = math.deg(math.atan2(directionVec.y, directionVec.x))
			self:setImage(whichBullet(self.type,getBulletAngle(self.rot + 90)))
			local rad = math.rad(self.rot)
			local x = self.x + math.cos(rad) * self.speed * dt
			local y = self.y + math.sin(rad) * self.speed * dt
			self:moveWithCollisions(x, y)
		end
	elseif self.type == 8 then
		if self.lifeTime - 1300 + (200 * self.mode) < currTime then 
			self.mode += 1
			if self.damage > 1 then self.damage = math.ceil(self.damage/2) end
			local rota = getBulletAngle(self.rot)
			if rota == 1 or rota == 2 or rota == 5 or rota == 6 then self:setScale(1 + self.mode/2 * self.tier, 1)
			elseif rota == 3 or rota == 4 or rota == 7 or rota == 8 then self:setScale(1, 1 + self.mode/2 * self.tier)
			else self:setScale(1 + self.mode/2 * self.tier, 1) end
			self:setCollideRect(0, 0, self:getSize())
		end
		--local rad = math.rad(self:getRotation() - 90)
		local rad = math.rad(self.rot - 90)
		local x = self.x + math.cos(rad) * self.speed * dt
		local y = self.y + math.sin(rad) * self.speed * dt
		self:moveWithCollisions(x, y)
	else
		local rad = math.rad(self.rot - 90)
		local x = self.x + math.cos(rad) * self.speed * dt
		local y = self.y + math.sin(rad) * self.speed * dt
		self:moveWithCollisions(x, y) -- need to check collisions, find the point a collision would happen, move there, then delete
	end
end
