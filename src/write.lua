local gfx <const> = playdate.graphics

class('write').extends(gfx.sprite)

-- sheet
numberSheet = gfx.imagetable.new('Resources/Sheets/writing')
local sheetRow = 1
--numberList = gfx.animation.loop.new(10, numberSheet)
--numbers = gfx.sprite:new()
--numbers:setZIndex(ZINDEX.uidetails)
--numbers:setImage(numberList:image())

function write:init(x, y, letter, offgrid)
	write.super.init(self)
	--self.writeImages = pl
	self:setImage(numberSheet:getImage(letterSelect(letter), sheetRow))
	if offgrid then self:setIgnoresDrawOffset(true) end
	self:moveTo(x, y)
	self:setZIndex(ZINDEX.uidetails)
	--print(letter)
end

function letterSelect(letter)
	if letter == 'a' then 
		sheetRow = 1
		return 1
	elseif letter == 'b' then 
		sheetRow = 1
		return 2
	elseif letter == 'c' then 
		sheetRow = 1
		return 3
	elseif letter == 'd' then 
		sheetRow = 1
		return 4
	elseif letter == 'e' then 
		sheetRow = 1
		return 5
	elseif letter == 'f' then 
		sheetRow = 1
		return 6
	elseif letter == 'g' then 
		sheetRow = 1
		return 7
	elseif letter == 'h' then 
		sheetRow = 1
		return 8
	elseif letter == 'i' then 
		sheetRow = 1
		return 9
	elseif letter == 'j' then 
		sheetRow = 1
		return 10
	elseif letter == 'k' then 
		sheetRow = 1
		return 11
	elseif letter == 'l' then 
		sheetRow = 1
		return 12
	elseif letter == 'm' then 
		sheetRow = 1
		return 13
	elseif letter == 'n' then 
		sheetRow = 1
		return 14
	elseif letter == 'o' then 
		sheetRow = 1
		return 15
	elseif letter == 'p' then 
		sheetRow = 1
		return 16
	elseif letter == 'q' then 
		sheetRow = 1
		return 17
	elseif letter == 'r' then 
		sheetRow = 1
		return 18
	elseif letter == 's' then 
		sheetRow = 1
		return 19
	elseif letter == 't' then 
		sheetRow = 1
		return 20
	elseif letter == 'u' then 
		sheetRow = 1
		return 21
	elseif letter == 'v' then 
		sheetRow = 1
		return 22
	elseif letter == 'w' then 
		sheetRow = 1
		return 23
	elseif letter == 'x' then 
		sheetRow = 1
		return 24
	elseif letter == 'y' then 
		sheetRow = 1
		return 25
	elseif letter == 'z' then 
		sheetRow = 1
		return 26
	elseif letter == '1' then 
		sheetRow = 2
		return 1
	elseif letter == '2' then 
		sheetRow = 2
		return 2
	elseif letter == '3' then 
		sheetRow = 2
		return 3
	elseif letter == '4' then 
		sheetRow = 2
		return 4
	elseif letter == '5' then 
		sheetRow = 2
		return 5
	elseif letter == '6' then 
		sheetRow = 2
		return 6
	elseif letter == '7' then 
		sheetRow = 2
		return 7
	elseif letter == '8' then 
		sheetRow = 2
		return 8
	elseif letter == '9' then 
		sheetRow = 2
		return 9
	elseif letter == '0' then 
		sheetRow = 2
		return 10
	elseif letter == '.' then 
		sheetRow = 2
		return 11
	elseif letter == '!' then 
		sheetRow = 2
		return 12
	elseif letter == '?' then 
		sheetRow = 2
		return 13
	elseif letter == '`' then 
		sheetRow = 2
		return 14
	elseif letter == '/' then 
		sheetRow = 2
		return 15
	elseif letter == ':' then 
		sheetRow = 2
		return 16
	elseif letter == '+' then 
		sheetRow = 2
		return 17
	elseif letter == '-' then 
		sheetRow = 2
		return 18
	elseif letter == '*' then 
		sheetRow = 2
		return 19
	elseif letter == '%' then 
		sheetRow = 2
		return 20
	else
		sheetRow = 2
		return 26
	end
end
