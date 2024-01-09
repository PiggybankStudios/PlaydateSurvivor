local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2

class('expbar').extends(gfx.sprite)


local expGrowthFactor <const> = 3
local currLevel = 0


function expbar:init(maxExp)
	expbar.super.init(self)
	self.maxExp = maxExp
	self.exp = 0
	self:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
	self:moveTo(halfScreenWidth, 7)
	self:updateExpbar(self.exp)
	self:add()
end

function expbar:updateExpbar(newExp)
	local maxWidth = screenWidth * 0.9
	local height = 6
	local radius = 3

	local borderWidth = maxWidth + 2
	local borderHeight = height + 2
	local borderRadius = radius + 2

	local xPosOffset = math.floor((borderWidth - maxWidth) / 2)
	local yPosOffset = math.floor((borderHeight - height) / 2)

	local expbarWidth = (newExp / self.maxExp) * maxWidth
	if expbarWidth == 0 then 
		expbarWidth += 3
		height = 4
		yPosOffset += 1
	end
	local expbarImage = gfx.image.new(borderWidth, borderHeight)
	gfx.pushContext(expbarImage)
		-- Border
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRoundRect(0, 0, borderWidth, borderHeight, borderRadius)
		-- Fill Bar
	    gfx.setColor(gfx.kColorBlack)
		gfx.fillRoundRect(xPosOffset, yPosOffset, expbarWidth, height, radius)		
	gfx.popContext()
	self:setImage(expbarImage)
	self:setZIndex(ZINDEX.ui)
end


function expbar:loseExp(amount)
	self.exp -= amount
	if self.exp <= 0 then
		self.exp = 0
	end
	self:updateExpbar(self.exp)
end


function expbar:gainExp(amount)
	self.exp += amount
	if self.exp >= self.maxExp then
		self:levelUp()
		updateExpfornextlevel(self.maxExp)
	else
		self:updateExpbar(self.exp)
	end
	updateExp(self.exp)
	addExpTotal(amount)
end


function expbar:move(drawOffsetX, drawOffsetY)
	local x = drawOffsetX - 50
	local y = drawOffsetY - 50
	self:moveTo(x, y)
end


function expbar:levelUp()
	--print("leveled up") 
	updateLevel()
	currLevel += 1
						--crit, damage, rate, bounce, pierce, velocity, bulletlife, amount, 
						--speed, hp, slot, magnet, luck, spin, armor, mod
	self.exp = math.abs(self.exp - self.maxExp) -- move overfill exp into next level
	self.maxExp += expGrowthFactor + math.floor(currLevel/10)
	self:updateExpbar(self.exp)
end



