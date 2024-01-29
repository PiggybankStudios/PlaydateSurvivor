local gfx <const> = playdate.graphics

class('write').extends(gfx.sprite)

-- sheet
local smallSheet = gfx.imagetable.new('Resources/Sheets/lettersS')
local largeSheet = gfx.imagetable.new('Resources/Sheets/lettersL')
--numberList = gfx.animation.loop.new(10, numberSheet)
--numbers = gfx.sprite:new()
--numbers:setZIndex(ZINDEX.uidetails)
--numbers:setImage(numberList:image())

function write:init(x, y, letter, offgrid, small)
	write.super.init(self)
	--self.writeImages = pl
	local col, row = letterSelect(letter)
	if small == true then 
		self:setImage(smallSheet:getImage(col, row))
	else 
		self:setImage(largeSheet:getImage(col, row))
	end
	if offgrid then self:setIgnoresDrawOffset(true) end
	self:moveTo(x, y)
	self:setZIndex(ZINDEX.uidetails)
	--print(letter)
end