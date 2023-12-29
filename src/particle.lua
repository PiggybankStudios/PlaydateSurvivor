local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

class('particle').extends(gfx.sprite)


local setLifeTime = 500
local ellipseWidth <const> = 2
local ellipseHeight <const> = 6


PARTICLE_TYPE = {
	impact = 1
}


function particle:init(x, y, type, currentTime, direction)
	particle.super.init(self)
	self.type = type
	self.lifeTime = currentTime + setLifeTime
	self.angle = -1 * direction:angleBetween(vec.new(0, 1)) + math.random(-30, 30)
	self.direction = vec.newPolar(1, self.angle + 180)
	self.maxSize = math.random(3, 8)
	self.size = self.maxSize
	self.speed = math.random(4, 7)

	self:moveTo(x, y)
	self:setRotation(self.angle)
	self:updateParticle()
	self:setZIndex(ZINDEX.impactparticle)
	self:add()
end


function particle:updateParticle()
	-- border size
	-- inner size
	local width = ellipseWidth * self.size
	local height = ellipseHeight * self.size

	local borderWidth = width + 4
	local borderHeight = height + 4

	local xOffset = math.floor((borderWidth - width) / 2)
	local yOffset = math.floor((borderHeight - height) / 2)

	local particleImage = gfx.image.new(borderWidth, borderHeight)
	gfx.pushContext(particleImage)
		-- border
		gfx.setColor(gfx.kColorWhite)
		gfx.fillEllipseInRect(0, 0, borderWidth, borderHeight)
		-- fill
	    gfx.setColor(gfx.kColorBlack)
		gfx.fillEllipseInRect(xOffset, yOffset, width, height)	
	gfx.popContext()
	self:setImage(particleImage)
end


function particle:move(time)
	-- decrease this particle's size
	if time == nil then time = 0 end
	local scalar = (self.lifeTime - time) / setLifeTime
	local calcSize = self.maxSize * scalar
	self.size = math.max(calcSize, 0.5)

	-- move this particle in its direction at its speed

	-- if small enough, remove self and don't update
	if self.size <= 0.5 then
		self:remove()
		do return end
	end

	local x = self.x + (self.direction.x * self.speed)
	local y = self.y + (self.direction.y * self.speed)
	self:moveTo(x, y)
	self:updateParticle(currentTime)
	
end