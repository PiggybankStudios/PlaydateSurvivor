local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2
local menuSpot = 0

local blinking = false
local lastBlink = 0

--setup main menu
local pauseImage = gfx.image.new('Resources/Sprites/menu/pauseMenu')
local pauseSprite = gfx.sprite.new(pauseImage)
pauseSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
pauseSprite:setZIndex(ZINDEX.ui)
pauseSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup selector
local selectImage = gfx.image.new('Resources/Sprites/menu/menuselect')
local selectSprite = gfx.sprite.new(selectImage)
selectSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
selectSprite:setZIndex(ZINDEX.uidetails)
selectSprite:moveTo(55, 212)

--setup guns
local gunxImage = gfx.image.new('Resources/Sprites/icon/gLocked')
local gun0Image = gfx.image.new('Resources/Sprites/icon/gEmpty')
local gun1Image = gfx.image.new('Resources/Sprites/icon/gPea')
local gun2Image = gfx.image.new('Resources/Sprites/icon/gCannon')
local gun3Image = gfx.image.new('Resources/Sprites/icon/gMini')
local gun4Image = gfx.image.new('Resources/Sprites/icon/gShot')
local gun5Image = gfx.image.new('Resources/Sprites/icon/gBurst')
local gun6Image = gfx.image.new('Resources/Sprites/icon/gGrenade')
local gun7Image = gfx.image.new('Resources/Sprites/icon/gRang')
local gun8Image = gfx.image.new('Resources/Sprites/icon/gWave')
gun1Sprite = gfx.sprite.new(gun1Image)
gun2Sprite = gfx.sprite.new(gunxImage)
gun3Sprite = gfx.sprite.new(gunxImage)
gun4Sprite = gfx.sprite.new(gunxImage)
gun1Sprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
gun2Sprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
gun3Sprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
gun4Sprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
gun1Sprite:setZIndex(ZINDEX.uidetails)
gun2Sprite:setZIndex(ZINDEX.uidetails)
gun3Sprite:setZIndex(ZINDEX.uidetails)
gun4Sprite:setZIndex(ZINDEX.uidetails)
gun1Sprite:moveTo(346, 40)
gun2Sprite:moveTo(346, 85)
gun3Sprite:moveTo(346, 130)
gun4Sprite:moveTo(346, 175)

function openPauseMenu()
	pauseSprite:add()
	selectSprite:add()
	gun1Sprite:add()
	gun2Sprite:add()
	gun3Sprite:add()
	gun4Sprite:add()
	blinking = true
	writeTextToScreen(50, 212, "play", true, false)
	writeTextToScreen(199, 212, "reset", true, false)
	writeTextToScreen(339, 212, "quit", true, false)
	addStats()
	addDifficulty()
	for i=1,4,1 do
		if getEquippedGun(i) ~= 0 then 
			local strSend = getGunName(getEquippedGun(i)) .. getTierStr(getTierForGun(i))
			writeTextToScreen(346, 15 + (45 * i), strSend, true, true)
		end
	end
	--print("paused")
end

function closePauseMenu()
	pauseSprite:remove()
	if blinking == true then selectSprite:remove() end
	gun1Sprite:remove()
	gun2Sprite:remove()
	gun3Sprite:remove()
	gun4Sprite:remove()
	selectSprite:moveTo(55, 212)
	menuSpot = 0
	cleanLetters()
	--print("unpaused")
end

function updatePauseManu()
	local theCurrTime = playdate.getCurrentTimeMilliseconds()
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

function pauseMenuMoveR()
	if menuSpot == 0 then 
		selectSprite:moveTo(204, 212)
		menuSpot = 1
	elseif menuSpot == 1 then 
		selectSprite:moveTo(344, 212)
		menuSpot = 2
	elseif menuSpot == 2 then 
		selectSprite:moveTo(55, 212)
		menuSpot = 0
	end
end

function pauseMenuMoveL()
	if menuSpot == 0 then 
		selectSprite:moveTo(344, 212)
		menuSpot = 2
	elseif menuSpot == 1 then 
		selectSprite:moveTo(55, 212)
		menuSpot = 0
	elseif menuSpot == 2 then 
		selectSprite:moveTo(204, 212)
		menuSpot = 1
	end
end

function pauseSelection()
	return menuSpot
end

function selectWeaponImage(gun)
	local newGun = gunxImage
	if gun == 0 then newGun = gun0Image --empty
	elseif gun == 1 then newGun = gun1Image --Pea
	elseif gun == 2 then newGun = gun2Image --Cannon
	elseif gun == 3 then newGun = gun3Image --Mini
	elseif gun == 4 then newGun = gun4Image --Shot
	elseif gun == 5 then newGun = gun5Image --Burst
	elseif gun == 6 then newGun = gun6Image --Grenade
	elseif gun == 7 then newGun = gun7Image --Rang
	elseif gun == 8 then newGun = gun8Image --Wave
	end
	return newGun
end

function updateMenuWeapon(slot, gun)
	if slot == 1 then gun1Sprite:setImage(selectWeaponImage(gun))
	elseif slot == 2 then gun2Sprite:setImage(selectWeaponImage(gun))
	elseif slot == 3 then gun3Sprite:setImage(selectWeaponImage(gun))
	elseif slot == 4 then gun4Sprite:setImage(selectWeaponImage(gun))
	else print("slot doesnt exist")
	end
end

function addStats()
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

function addDifficulty()
	local spacing = 4
	local row = 20
	local column = 162
	local sentence = ("difficulty --" .. tostring(getDifficulty()) .. "--")
	writeTextToScreen(column, row, sentence, false, true)
end

function clearPauseMenu()
	gun1Sprite:setImage(gun1Image)
	gun2Sprite:setImage(gunxImage)
	gun3Sprite:setImage(gunxImage)
	gun4Sprite:setImage(gunxImage)
end