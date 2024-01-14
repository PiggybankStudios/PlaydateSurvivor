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
		if blinking then
			lastBlink = theCurrTime + 300
			promptSprite:remove()
			blinking = false
			--print("blink..")
		else
			lastBlink = theCurrTime + 700
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
	lchars = lstrtochar("difficulty reached: " .. tostring(pstats[1]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("max level: " .. tostring(pstats[2]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("exp gained: " .. tostring(pstats[3]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("damage dealt: " .. tostring(pstats[4]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("shots fired: " .. tostring(pstats[5]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("enemies killed: " .. tostring(pstats[6]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("largest kill combo: " .. tostring(pstats[7]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("damage received: " .. tostring(pstats[8]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("items grabbed: " .. tostring(pstats[9]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("time survived: " .. tostring(pstats[10]) .. " seconds")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("*****************************")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("final score: " .. tostring(pstats[11]) .. " points")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("*****************************")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
end
