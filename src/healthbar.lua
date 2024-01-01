local gfx <const> = playdate.graphics

class('healthbar').extends(gfx.sprite)


function healthbar:init(x, y, maxHealth)
	healthbar.super.init(self)
	self.maxHealth = maxHealth
	self.health = maxHealth
	self:moveTo(x, y)
	self:updateHealth(maxHealth)
	self:add()
end

function healthbar:updateMaxHealth(amount)
	self.maxHealth = amount
	self:updateHealth(self.health)
end


function healthbar:updateHealth(newHealth)
	local maxWidth = 40
	local height = 4
	local radius = 3

	local borderWidth = maxWidth + 2
	local borderHeight = height + 2
	local borderRadius = radius + 2

	local xPosOffset = math.floor((borderWidth - maxWidth) / 2)
	local yPosOffset = math.floor((borderHeight - height) / 2)

	local healthbarWidth = (newHealth / self.maxHealth) * maxWidth
	local healthbarImage = gfx.image.new(borderWidth, borderHeight)
	gfx.pushContext(healthbarImage)
		gfx.setColor(gfx.kColorBlack)
		gfx.fillRoundRect(0, 0, borderWidth, borderHeight, borderRadius)
	    gfx.setColor(gfx.kColorWhite)
		gfx.fillRoundRect(xPosOffset, yPosOffset, healthbarWidth, height, radius)		
	gfx.popContext()
	self:setImage(healthbarImage)
	self:setZIndex(ZINDEX.healthbar)
end


function healthbar:damage(amount)
	self.health -= amount
	if self.health <= 0 then
		self.health = 0
		self:remove()
	end
	self:updateHealth(self.health)
end


function healthbar:heal(amount)
	self.health += amount
	if self.health >= self.maxHealth then
		self.health = self.maxHealth
	end
	self:updateHealth(self.health)
end