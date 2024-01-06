local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2
local menuSpot = 1
local levelBonus = 1
local bonusStat = 0
local blinking = false
local lastBlink = 0
local statOptions = {0,0,0,0}
local writings = {}

--setup main menu
local levelUpImage = gfx.image.new('Resources/Sprites/levelUpMenu')
local levelUpSprite = gfx.sprite.new(levelUpImage)
levelUpSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
levelUpSprite:setZIndex(ZINDEX.ui)
levelUpSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup selector
local selectImage = gfx.image.new('Resources/Sprites/levelUpselect')
local selectSprite = gfx.sprite.new(selectImage)
selectSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
selectSprite:setZIndex(ZINDEX.uidetails)
selectSprite:moveTo(114, 132)

--setup guns
local statxImage = gfx.image.new('Resources/Sprites/gLocked')
local stat0Image = gfx.image.new('Resources/Sprites/lSlot')
local stat1Image = gfx.image.new('Resources/Sprites/lArmor')
local stat2Image = gfx.image.new('Resources/Sprites/lAttRate')
local stat3Image = gfx.image.new('Resources/Sprites/lBullSpeed')
local stat4Image = gfx.image.new('Resources/Sprites/lDamage')
local stat5Image = gfx.image.new('Resources/Sprites/lDodge')
local stat6Image = gfx.image.new('Resources/Sprites/lExp')
local stat7Image = gfx.image.new('Resources/Sprites/lHeal')
local stat8Image = gfx.image.new('Resources/Sprites/lHealth')
local stat9Image = gfx.image.new('Resources/Sprites/lLuck')
local stat10Image = gfx.image.new('Resources/Sprites/lMagnet')
local stat11Image = gfx.image.new('Resources/Sprites/lReflect')
local stat12Image = gfx.image.new('Resources/Sprites/lSpeed')
local stat13Image = gfx.image.new('Resources/Sprites/lVampire')
local level1Sprite = gfx.sprite.new(statxImage)
local level2Sprite = gfx.sprite.new(statxImage)
local level3Sprite = gfx.sprite.new(statxImage)
local level4Sprite = gfx.sprite.new(statxImage)
level1Sprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
level2Sprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
level3Sprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
level4Sprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
level1Sprite:setZIndex(ZINDEX.uidetails)
level2Sprite:setZIndex(ZINDEX.uidetails)
level3Sprite:setZIndex(ZINDEX.uidetails)
level4Sprite:setZIndex(ZINDEX.uidetails)
level1Sprite:moveTo(114, 132)
level2Sprite:moveTo(174, 132)
level3Sprite:moveTo(234, 132)
level4Sprite:moveTo(294, 132)

function openLevelUpMenu()
	levelUpSprite:add()
	selectSprite:add()
	level1Sprite:add()
	level2Sprite:add()
	level3Sprite:add()
	level4Sprite:add()
	blinking = true
	addStatOptions()
	addLevelOptions()
	--print("paused")
end

function closeLevelUpMenu()
	levelUpSprite:remove()
	if blinking == true then selectSprite:remove() end
	level1Sprite:remove()
	level2Sprite:remove()
	level3Sprite:remove()
	level4Sprite:remove()
	selectSprite:moveTo(114, 132)
	menuSpot = 1
	for gIndex,gchar in pairs(writings) do --need all graphics removed first
		writings[gIndex]:remove()
	end
	for gIndex,gchar in pairs(writings) do --need to clear the table now
		table.remove(writings,gIndex)
	end
	--print("unpaused")
end

function updateLevelUpManu()
	local theCurrTime = playdate.getCurrentTimeMilliseconds()
	if theCurrTime > lastBlink then
		lastBlink = theCurrTime + 500
		if blinking == true then
			selectSprite:remove()
			blinking = false
			--print("blink..")
		else
			selectSprite:add()
			blinking = true
		end
	end
end

function pauseLevelUpMoveR()
	if menuSpot == 1 then 
		selectSprite:moveTo(174, 132)
		menuSpot = 2
	elseif menuSpot == 2 then 
		selectSprite:moveTo(234, 132)
		menuSpot = 3
	elseif menuSpot == 3 then 
		if bonusStat == 1 then
			selectSprite:moveTo(294, 132)
			menuSpot = 4
		else
			selectSprite:moveTo(114, 132)
			menuSpot = 1
		end
	elseif menuSpot == 4 then 
		selectSprite:moveTo(114, 132)
		menuSpot = 1
	end
end

function pauseLevelUpMoveL()
	if menuSpot == 1 then 
		if bonusStat == 1 then
			selectSprite:moveTo(294, 132)
			menuSpot = 4
		else
			selectSprite:moveTo(234, 132)
			menuSpot = 3
		end
	elseif menuSpot == 2 then 
		selectSprite:moveTo(114, 132)
		menuSpot = 1
	elseif menuSpot == 3 then 
		selectSprite:moveTo(174, 132)
		menuSpot = 2
	elseif menuSpot == 4 then 
		selectSprite:moveTo(234, 132)
		menuSpot = 3
	end
end

function levelUpSelection()
	return statOptions[menuSpot]
end

function levelUpBonus()
	return levelBonus
end

function addStatDetails(theString, slot)
	local spacing = 4
	local row = 154
	local column = 37 + (60 * slot)
	local lchars = {}
	lchars = lstrtochar(theString)
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
end

function addStatOptions()
	local spacing = 4
	local newline = 8
	local statrow = 1
	local row = 26
	local column = 12
	local pstats = getPlayerStats()
	local lchars = {}
	lchars = lstrtochar("level: " .. tostring(pstats[1]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("exp: " .. tostring(pstats[2]) .. "/" .. tostring(pstats[3]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("health: " .. tostring(pstats[4]) .. "/" .. tostring(pstats[5]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("speed: " .. tostring(pstats[6]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("att rate: " .. tostring(pstats[7]) .. " msec")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("magnet: " .. tostring(pstats[8]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("slots: " .. tostring(pstats[9]) .. "/4")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("damage: " .. tostring(pstats[10]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("reflect: " .. tostring(pstats[11]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("bonus exp: " .. tostring(pstats[12]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("luck: " .. tostring(pstats[13]) .. "%")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("bullet spd: " .. tostring(pstats[14]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("armor: " .. tostring(pstats[15]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("dodge: " .. tostring(pstats[16]) .. "%")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
end

function addLevelOptions()
	levelBonus = math.random(1, 2 + math.floor(getLuck()/20))
	bonusStat = 0
	if math.random(0,99) < getLuck() then bonusStat = 1 end
	local astats = getAvailLevelUpStats()
	
	local randStat = math.random(1, #astats)
	local stat1 = astats[randStat]
	table.remove(astats,randStat)
	
	local randStat = math.random(1, #astats)
	local stat2 = astats[randStat]
	table.remove(astats,randStat)
	
	local randStat = math.random(1, #astats)
	local stat3 = astats[randStat]
	table.remove(astats,randStat)
	if bonusStat == 1 then 
		local randStat = math.random(1, #astats)
		local stat4 = astats[randStat]
		table.remove(astats,randStat)
	else
		local stat4 = "empty"
	end
	level1Sprite:setImage(whatStatSprite(stat1,1))
	level2Sprite:setImage(whatStatSprite(stat2,2))
	level3Sprite:setImage(whatStatSprite(stat3,3))
	level4Sprite:setImage(whatStatSprite(stat4,4))
end

function whatStatSprite(sel,slot)
	local theStat = 0
	local theImage = statxImage
	if sel == "empty" then
		theStat = 0
		theImage = statxImage
		addStatDetails("need more luck", slot)
	elseif sel == "armor" then
		theStat = 1
		theImage = stat1Image
		addStatDetails("armor +" .. tostring(levelBonus), slot)
	elseif sel == "attrate" then
		theStat = 2
		theImage = stat2Image
		addStatDetails("att. rate -" .. tostring(5 * levelBonus), slot)
	elseif sel == "bullspeed" then
		theStat = 3
		theImage = stat3Image
		addStatDetails("bullet spd +" .. tostring(levelBonus), slot)
	elseif sel == "damage" then
		theStat = 4
		theImage = stat4Image
		addStatDetails("damage +" .. tostring(levelBonus), slot)
	elseif sel == "dodge" then
		theStat = 5
		theImage = stat5Image
		addStatDetails("dodge % +" .. tostring(3 * levelBonus), slot)
	elseif sel == "exp" then
		theStat = 6
		theImage = stat6Image
		addStatDetails("bonus exp +" .. tostring(3 * levelBonus), slot)
	elseif sel == "heal" then
		theStat = 7
		theImage = stat7Image
		addStatDetails("bonus heal +" .. tostring(levelBonus), slot)
	elseif sel == "health" then
		theStat = 8
		theImage = stat8Image
		addStatDetails("max health +" .. tostring(2 * levelBonus), slot)
	elseif sel == "luck" then
		theStat = 9
		theImage = stat9Image
		addStatDetails("luck +" .. tostring(5 * levelBonus), slot)
	elseif sel == "magnet" then
		theStat = 10
		theImage = stat10Image
		addStatDetails("magnet +" .. tostring(20 * levelBonus), slot)
	elseif sel == "reflect" then
		theStat = 11
		theImage = stat11Image
		addStatDetails("reflect +" .. tostring(levelBonus), slot)
	elseif sel == "speed" then
		theStat = 12
		theImage = stat12Image
		addStatDetails("speed +" .. tostring(5 * levelBonus), slot)
	elseif sel == "vampire" then
		theStat = 13
		theImage = stat13Image
		addStatDetails("vampire % +" .. tostring(5 * levelBonus), slot)
	else
		theStat = 0
		theImage = statxImage
		addStatDetails("need more luck", slot)
	end
	
	statOptions[slot] = theStat
	
	return theImage
end

function clearLevelUpMenu()
	level1Sprite:setImage(statxImage)
	level2Sprite:setImage(statxImage)
	level3Sprite:setImage(statxImage)
	level4Sprite:setImage(statxImage)
end