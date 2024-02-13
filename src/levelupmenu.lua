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

--setup main menu
local levelUpImage = gfx.image.new('Resources/Sprites/menu/levelUpMenu')
local levelUpSprite = gfx.sprite.new(levelUpImage)
levelUpSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
levelUpSprite:setZIndex(ZINDEX.ui)
levelUpSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup selector
local selectImage = gfx.image.new('Resources/Sprites/menu/levelUpselect')
local selectSprite = gfx.sprite.new(selectImage)
selectSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
selectSprite:setZIndex(ZINDEX.uidetails)
selectSprite:moveTo(114, 132)

--setup guns
local statxImage = gfx.image.new('Resources/Sprites/icon/gLocked')
local stat0Image = gfx.image.new('Resources/Sprites/icon/lSlot')
local stat1Image = gfx.image.new('Resources/Sprites/icon/lArmor')
local stat2Image = gfx.image.new('Resources/Sprites/icon/lAttRate')
local stat3Image = gfx.image.new('Resources/Sprites/icon/lBullSpeed')
local stat4Image = gfx.image.new('Resources/Sprites/icon/lDamage')
local stat5Image = gfx.image.new('Resources/Sprites/icon/lDodge')
local stat6Image = gfx.image.new('Resources/Sprites/icon/lExp')
local stat7Image = gfx.image.new('Resources/Sprites/icon/lHeal')
local stat8Image = gfx.image.new('Resources/Sprites/icon/lHealth')
local stat9Image = gfx.image.new('Resources/Sprites/icon/lLuck')
local stat10Image = gfx.image.new('Resources/Sprites/icon/lMagnet')
local stat11Image = gfx.image.new('Resources/Sprites/icon/lReflect')
local stat12Image = gfx.image.new('Resources/Sprites/icon/lSpeed')
local stat13Image = gfx.image.new('Resources/Sprites/icon/lVampire')
local stat14Image = gfx.image.new('Resources/Sprites/icon/lStun')
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
end

function updateLevelUpMenu()
	local theCurrTime = getRunTime()
	if theCurrTime > lastBlink then
		if blinking == true then
			lastBlink = theCurrTime + 300
			selectSprite:remove()
			blinking = false
			--print("blink..")
		else
			lastBlink = theCurrTime + 700
			selectSprite:add()
			blinking = true
		end
	end
end

function pauseLevelUpMoveR()
	menuSpot += 1
	if menuSpot > (3 + bonusStat) then menuSpot = 1 end
	local selectSpot = 54 + (60 * menuSpot)
	selectSprite:moveTo(selectSpot, 132)
end

function pauseLevelUpMoveL()
	menuSpot -= 1
	if menuSpot < 1 then menuSpot = (3 + bonusStat) end
	local selectSpot = 54 + (60 * menuSpot)
	selectSprite:moveTo(selectSpot, 132)
end

function levelUpSelection()
	return statOptions[menuSpot]
end

function levelUpBonus()
	return levelBonus
end

function addStatDetails(theString, slot)
	local row = 154
	local column = 53 + (60 * slot)
	writeTextToScreen(column, row, theString, true, true)
end

function addStatOptions()
	local newline = 8
	local statrow = 1
	local row = 20
	local column = 12
	local pstats = getPlayerStats()
	local sentence = ("level:      " .. tostring(pstats[1]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("exp:        " .. tostring(pstats[2]) .. "/" .. tostring(pstats[3]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("health:     " .. tostring(pstats[4]) .. "/" .. tostring(pstats[5]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("speed:      " .. tostring(pstats[6]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("att rate:   " .. tostring(pstats[7]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("magnet:     " .. tostring(pstats[8]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("slots:      " .. tostring(pstats[9]) .. "/4")
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("damage:     " .. tostring(pstats[10]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("reflect:    " .. tostring(pstats[11]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("bonus exp:  " .. tostring(pstats[12]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("luck:       " .. tostring(pstats[13]) .. "%")
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("bullet spd: " .. tostring(pstats[14]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("armor:      " .. tostring(pstats[15]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("dodge:      " .. tostring(pstats[16]) .. "%")
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("heal bonus: " .. tostring(pstats[17]))
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("vampire:    " .. tostring(pstats[18]) .. "%")
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
	
	statrow += 1 --move on to the next line
	sentence = ("stun:       " .. tostring(pstats[19]) .. "%")
	writeTextToScreen(column, (row + newline * statrow), sentence, false, true)
end

function addLevelOptions()
	levelBonus = math.random(1, 2 + math.floor(getLuck()/20))
	bonusStat = 0
	if math.random(0,99) < getLuck() then bonusStat = 1 end
	local astats = getAvailLevelUpStats()
	
	local randStat = math.random(1, #astats)
	local stat1 = astats[randStat]
	table.remove(astats,randStat)
	
	randStat = math.random(1, #astats)
	local stat2 = astats[randStat]
	table.remove(astats,randStat)
	
	randStat = math.random(1, #astats)
	local stat3 = astats[randStat]
	table.remove(astats,randStat)
	
	local stat4 = "empty"
	if bonusStat == 1 then 
		randStat = math.random(1, #astats)
		stat4 = astats[randStat]
		table.remove(astats,randStat)
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
		addStatDetails("need luck!", slot)
	elseif sel == "armor" then
		theStat = 1
		theImage = stat1Image
		addStatDetails("armor +" .. tostring(levelBonus), slot)
	elseif sel == "attrate" then
		theStat = 2
		theImage = stat2Image
		addStatDetails("att. rate +" .. tostring((5 * levelBonus)/25), slot)
	elseif sel == "bullspeed" then
		theStat = 3
		theImage = stat3Image
		addStatDetails("bullet spd +" .. tostring(levelBonus), slot)
	elseif sel == "damage" then
		theStat = 4
		theImage = stat4Image
		addStatDetails("damage +" .. tostring(2 * levelBonus), slot)
	elseif sel == "dodge" then
		theStat = 5
		theImage = stat5Image
		addStatDetails("dodge % +" .. tostring(3 * levelBonus), slot)
	elseif sel == "exp" then
		theStat = 6
		theImage = stat6Image
		addStatDetails("bonus exp +" .. tostring(levelBonus), slot)
	elseif sel == "heal" then
		theStat = 7
		theImage = stat7Image
		addStatDetails("bonus heal +" .. tostring(4 * levelBonus), slot)
	elseif sel == "health" then
		theStat = 8
		theImage = stat8Image
		addStatDetails("max health +" .. tostring(8 * levelBonus), slot)
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
		addStatDetails("reflect +" .. tostring(3 * levelBonus), slot)
	elseif sel == "speed" then
		theStat = 12
		theImage = stat12Image
		addStatDetails("speed +" .. tostring(5 * levelBonus), slot)
	elseif sel == "vampire" then
		theStat = 13
		theImage = stat13Image
		addStatDetails("vampire % +" .. tostring(5 * levelBonus), slot)
	elseif sel == "stun" then
		theStat = 14
		theImage = stat14Image
		addStatDetails("stun % +" .. tostring(5 * levelBonus), slot)
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