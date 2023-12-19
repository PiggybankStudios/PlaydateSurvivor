
local gfx <const> = playdate.graphics

class("Enemy").extends()

enemySpeed = 30
enemyX = {0,230,230,230,0,-230,-230,-230}
enemyY = {150,150,0,-150,-150,-150,0,150}

function Enemy:init(theCurrTime, spritePath, posX, posY)
	rndLoc = math.random(1,8)
	self.spawnTime = theCurrTime
	self.isAlive = true
	self.sprite = gfx.sprite:new(gfx.image.new(spritePath))
	self.sprite:moveTo(posX + enemyX[rndLoc], posY + enemyY[rndLoc])
	self.sprite:setCollideRect(self.sprite:getBounds())
	self.sprite:addSprite()
end

function Enemy:remove()
	self.sprite:remove()
	self.sprite = nil
	self.isAlive = false
end

function Enemy:update(dt, playerX, playerY)
	enemyVec = playdate.geometry.vector2D.new(playerX - self.sprite.x, playerY - self.sprite.y)
	enemyVec:normalize()
	local headingAngle = ((self.sprite:getRotation() - 90) / 180) * 3.1415926
	self.sprite:moveTo(
		self.sprite.x + (enemyVec.x * enemySpeed * dt),
		self.sprite.y + (enemyVec.y * enemySpeed * dt))
end
