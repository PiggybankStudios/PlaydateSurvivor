
local gfx <const> = playdate.graphics

class("Bullet").extends()

bulletSpeed = 200
bulletDespawnTime = 1000

function Bullet:init(theCurrTime, spritePath, posX, posY, rotation)
	self.spawnTime = theCurrTime
	self.isAlive = true
	self.sprite = gfx.sprite:new(gfx.image.new(spritePath))
	self.sprite:moveTo(posX, posY)
	self.sprite:setRotation(rotation)
	self.sprite:setCollideRect(self.sprite:getBounds())
	self.sprite:addSprite()
end

function Bullet:remove()
	self.sprite:remove()
	self.sprite = nil
	self.isAlive = false
end

function Bullet:update(dt, theCurrTime)
	local headingAngle = ((self.sprite:getRotation() - 90) / 180) * 3.1415926
	self.sprite:moveTo(
		self.sprite.x + (math.cos(headingAngle)) * bulletSpeed * dt,
		self.sprite.y + (math.sin(headingAngle)) * bulletSpeed * dt)
	if theCurrTime >= self.spawnTime + bulletDespawnTime then
		self.isAlive = false
	end
end
