local gfx <const> = playdate.graphics

class('writefunctions').extends(gfx.sprite)

-- sheet
local writings = {}
local sheetRow = 1
--numberList = gfx.animation.loop.new(10, numberSheet)
--numbers = gfx.sprite:new()
--numbers:setZIndex(ZINDEX.uidetails)
--numbers:setImage(numberList:image())

function cleanLetters()
	for wIndex,gchar in pairs(writings) do --need all graphics removed first
		writings[wIndex]:remove()
	end
	for wIndex,gchar in pairs(writings) do --need to clear the table now
		table.remove(writings,wIndex)
	end
end

function writeTextToScreen(col, row, letters, center, smallText)
	local column = col
	local space = 10
	local lchars = {}
	lchars = lstrtochar(letters)
	if smallText == true then space = 4 end
	if center then column -= math.floor(#lchars * space / 2) end
	for wIndex,letter in pairs(lchars) do
		newLetter = write((column + space * wIndex), row, letter, true, smallText)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
end

function letterSelect(letter)
	if letter == 'a' then 
		return 1, 1
	elseif letter == 'b' then 
		return 2, 1
	elseif letter == 'c' then 
		return 3, 1
	elseif letter == 'd' then 
		return 4, 1
	elseif letter == 'e' then 
		return 5, 1
	elseif letter == 'f' then 
		return 6, 1
	elseif letter == 'g' then 
		return 7, 1
	elseif letter == 'h' then 
		return 8, 1
	elseif letter == 'i' then 
		return 9, 1
	elseif letter == 'j' then 
		return 10, 1
	elseif letter == 'k' then 
		return 11, 1
	elseif letter == 'l' then 
		return 12, 1
	elseif letter == 'm' then 
		return 13, 1
	elseif letter == 'n' then 
		return 14, 1
	elseif letter == 'o' then 
		return 15, 1
	elseif letter == 'p' then 
		return 16, 1
	elseif letter == 'q' then 
		return 17, 1
	elseif letter == 'r' then 
		return 18, 1
	elseif letter == 's' then 
		return 19, 1
	elseif letter == 't' then 
		return 20, 1
	elseif letter == 'u' then 
		return 21, 1
	elseif letter == 'v' then 
		return 22, 1
	elseif letter == 'w' then 
		return 23, 1
	elseif letter == 'x' then 
		return 24, 1
	elseif letter == 'y' then 
		return 25, 1
	elseif letter == 'z' then 
		return 26, 1
	elseif letter == '1' then 
		return 1, 2
	elseif letter == '2' then 
		return 2, 2
	elseif letter == '3' then 
		return 3, 2
	elseif letter == '4' then 
		return 4, 2
	elseif letter == '5' then 
		return 5, 2
	elseif letter == '6' then 
		return 6, 2
	elseif letter == '7' then 
		return 7, 2
	elseif letter == '8' then 
		return 8, 2
	elseif letter == '9' then 
		return 9, 2
	elseif letter == '0' then 
		return 10, 2
	elseif letter == '.' then 
		return 11, 2
	elseif letter == '!' then 
		return 12, 2
	elseif letter == '?' then 
		return 13, 2
	elseif letter == '`' then 
		return 14, 2
	elseif letter == ';' then 
		return 15, 2
	elseif letter == ':' then 
		return 16, 2
	elseif letter == '+' then 
		return 17, 2
	elseif letter == '-' then 
		return 18, 2
	elseif letter == '*' then 
		return 19, 2
	elseif letter == '/' then 
		return 20, 2
	elseif letter == '%' then 
		return 21, 2
	elseif letter == '"' then 
		return 22, 2
	elseif letter == '_' then 
		return 23, 2
	elseif letter == '(' then 
		return 24, 2
	elseif letter == ')' then 
		return 25, 2
	else
		return 26, 2
	end
end

function lstrtochar(lstring)
	local lchar = {}
	local lstr = lstring
	for i = 1, #lstr do
		lchar[i] = lstr:sub(i,i)
	end
	return lchar
end
