local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

class('bullet').extends(gfx.sprite)


function bullet:init(x, y, rotation, newLifeTime, type, index, tier)
	bullet.super.init(self)
	if type == 2 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletCannon'))
		self.speed = getPayerBulletSpeed() * 8
		self.damage = 4 + getPlayerGunDamage() * (1 + tier)
		self.knockback = 4
		self:setScale(tier)
	elseif type == 3 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletMinigun'))
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.ceil(getPlayerGunDamage() / 2) --round up
		self.knockback = 0
	elseif type == 4 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletShotgun'))
		self.speed = getPayerBulletSpeed() * 3
		self.damage = 1 + math.floor(getPlayerGunDamage() / 2) --round down
		self.knockback = 2
	elseif type == 5 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletBurstgun'))
		self.speed = getPayerBulletSpeed() * 3
		self.damage = 2 + getPlayerGunDamage()
		self.knockback = 3
	elseif type == 6 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletGrenade'))
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 2 + getPlayerGunDamage()
		self.knockback = 0
	elseif type == 7 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletRanggun'))
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.floor(getPlayerGunDamage() / 3)
		self.knockback = 1
		self:setScale(tier)
	elseif type == 8 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletWavegun'))
		self.speed = getPayerBulletSpeed()
		self.damage = 4 + getPlayerGunDamage()
		self.knockback = 0
	elseif type == 99 then
		self:setImage(gfx.image.new('Resources/Sprites/BulletGrenadePellet'))
		self.speed = getPayerBulletSpeed() * 2
		self.damage = 1 + math.floor(getPlayerGunDamage() / 2)
		self.knockback = 0
	else
		self:setImage(gfx.image.new('Resources/Sprites/BulletPeagun'))
		self.speed = getPayerBulletSpeed() * 4
		self.damage = 2 + getPlayerGunDamage()
		self.knockback = 1
	end
	
	self:moveTo(x, y)
	self:setRotation(rotation)
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
			local rad = math.rad(self:getRotation() - 90)
			local x = self.x + math.cos(rad) * self.speed * dt
			local y = self.y + math.sin(rad) * self.speed * dt
			self:moveWithCollisions(x, y)
			if self.lifeTime - 5000 < currTime then self.mode = 1 end
		elseif self.mode == 1 then
			self:setRotation(self:getRotation() - 25)
			local rad = math.rad(self:getRotation() - 90)
			local x = self.x + math.cos(rad) * self.speed * dt
			local y = self.y + math.sin(rad) * self.speed * dt
			self:moveWithCollisions(x, y)
			if self.lifeTime - 3000 < currTime then self.mode = 2 end
		elseif self.mode == 2 then
			local directionVec = vec.new(getPlayerx() - self.x, getPlayery() - self.y)
			local rad = math.rad(math.deg(math.atan2(directionVec.y, directionVec.x)))
			local x = self.x + math.cos(rad) * self.speed * dt
			local y = self.y + math.sin(rad) * self.speed * dt
			self:moveWithCollisions(x, y)
		end
	elseif self.type == 8 then
		if self.lifeTime - 1300 + (200 * self.mode) < currTime then 
			self.mode += 1
			if self.damage > 1 then self.damage = math.ceil(self.damage/2) end
			self:setScale(1 + self.mode/2 * self.tier, 1)
			self:setCollideRect(0, 0, self:getSize())
		end
		local rad = math.rad(self:getRotation() - 90)
		local x = self.x + math.cos(rad) * self.speed * dt
		local y = self.y + math.sin(rad) * self.speed * dt
		self:moveWithCollisions(x, y)
	else
		local rad = math.rad(self:getRotation() - 90)
		local x = self.x + math.cos(rad) * self.speed * dt
		local y = self.y + math.sin(rad) * self.speed * dt
		self:moveWithCollisions(x, y) -- need to check collisions, find the point a collision would happen, move there, then delete
	end
end
