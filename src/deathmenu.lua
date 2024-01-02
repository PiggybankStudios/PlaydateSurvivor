local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2

local blinking = false
local lastBlink = 0

local writings = {}

--setup main menu
local deadImage = gfx.image.new('Resources/Sprites/deadMenu')
local deadSprite = gfx.sprite.new(deadImage)
deadSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
deadSprite:setZIndex(ZINDEX.ui)
deadSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup prompt
local promptImage = gfx.image.new('Resources/Sprites/deadSelect')
local promptSprite = gfx.sprite.new(promptImage)
promptSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
promptSprite:setZIndex(ZINDEX.uidetails)
promptSprite:moveTo(210, 211)


function openDeadMenu()
	deadSprite:add()
	promptSprite:add()
	blinking = true
	addFinalStats()
	--print("dead!")
end

function updateDeadManu()
	local theCurrTime = playdate.getCurrentTimeMilliseconds()
	if theCurrTime > lastBlink then
		lastBlink = theCurrTime + 500
		if blinking then
			promptSprite:remove()
			blinking = false
			--print("blink..")
		else
			promptSprite:add()
			blinking = true
		end
	end
end

function closeDeadMenu()
	deadSprite:remove()
	if blinking == true then promptSprite:remove() end
	for gIndex,gchar in pairs(writings) do --need all graphics removed first
		writings[gIndex]:remove()
	end
	for gIndex,gchar in pairs(writings) do --need to clear the table now
		table.remove(writings,gIndex)
	end
	--print("unpaused")
end


function addFinalStats()
	local spacing = 4
	local newline = 8
	local statrow = 1
	local row = 26
	local column = 12
	local pstats = getFinalStats()
	local lchars = {}
	lchars = dstrtochar("difficulty reached: " .. tostring(pstats[1]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("max level: " .. tostring(pstats[2]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("exp gained: " .. tostring(pstats[3]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("damage dealt: " .. tostring(pstats[4]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("shots fired: " .. tostring(pstats[5]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("enemies killed: " .. tostring(pstats[6]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("damage received: " .. tostring(pstats[7]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("items grabbed: " .. tostring(pstats[8]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("time survived: " .. tostring(pstats[9]) .. " seconds")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("*****************************")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("final score: " .. tostring(pstats[10]) .. " points")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = dstrtochar("*****************************")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
end

function dstrtochar(lstring)
	local lchar = {}
	local lstr = lstring
	for i = 1, #lstr do
		lchar[i] = lstr:sub(i,i)
	end
	return lchar
end
