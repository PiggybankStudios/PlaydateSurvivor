local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2

local blinking = false
local lastBlink = 0

--setup main menu
local deadImage = gfx.image.new('Resources/Sprites/menu/deadMenu')
local deadSprite = gfx.sprite.new(deadImage)
deadSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
deadSprite:setZIndex(ZINDEX.ui)
deadSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup prompt
local promptImage = gfx.image.new('Resources/Sprites/menu/deadSelect')
local promptSprite = gfx.sprite.new(promptImage)
promptSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
promptSprite:setZIndex(ZINDEX.uidetails)
promptSprite:moveTo(210, 211)


function openDeadMenu()
	deadSprite:add()
	promptSprite:add()
	blinking = true
	addFinalStats()
	addTotalMun(getMun())
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
end


function addFinalStats()
	local newline = 8
	local statrow = 1
	local row = 26
	local column = 12
	local pstats = getFinalStats()
	local sentence = ("difficulty reached: " .. tostring(pstats[1]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("max level: " .. tostring(pstats[2]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("exp gained: " .. tostring(pstats[3]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("damage dealt: " .. tostring(pstats[4]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("shots fired: " .. tostring(pstats[5]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("enemies killed: " .. tostring(pstats[6]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("largest kill combo: " .. tostring(pstats[7]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("damage received: " .. tostring(pstats[8]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("items grabbed: " .. tostring(pstats[9]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("time survived: " .. tostring(pstats[10]) .. " seconds")
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("mun collected: " .. tostring(getMun()))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("*****************************")
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("final score: " .. tostring(pstats[11]) .. " points")
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("*****************************")
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
end
