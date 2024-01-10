local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2
local menuSpot = 0

local blinking = false
local lastBlink = 0

local writings = {}

--setup main menu
local pauseImage = gfx.image.new('Resources/Sprites/pauseMenu')
local pauseSprite = gfx.sprite.new(pauseImage)
pauseSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
pauseSprite:setZIndex(ZINDEX.ui)
pauseSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup selector
local selectImage = gfx.image.new('Resources/Sprites/menuselect')
local selectSprite = gfx.sprite.new(selectImage)
selectSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
selectSprite:setZIndex(ZINDEX.uidetails)
selectSprite:moveTo(55, 212)

--setup guns
local gunxImage = gfx.image.new('Resources/Sprites/gLocked')
local gun0Image = gfx.image.new('Resources/Sprites/gEmpty')
local gun1Image = gfx.image.new('Resources/Sprites/gPea')
local gun2Image = gfx.image.new('Resources/Sprites/gCannon')
local gun3Image = gfx.image.new('Resources/Sprites/gMini')
local gun4Image = gfx.image.new('Resources/Sprites/gShot')
local gun5Image = gfx.image.new('Resources/Sprites/gBurst')
local gun6Image = gfx.image.new('Resources/Sprites/gGrenade')
local gun7Image = gfx.image.new('Resources/Sprites/gRang')
local gun8Image = gfx.image.new('Resources/Sprites/gWave')
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
	addStats()
	addDifficulty()
	for i=1,4,1 do
		if getEquippedGun(i) ~= 0 then 
			local strSend = getGunName(getEquippedGun(i)) .. getTierStr(getTierForGun(i))
			addPauseWeaponDetails(strSend, 15 + (45 * i), 346)
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
	for gIndex,gchar in pairs(writings) do --need all graphics removed first
		writings[gIndex]:remove()
	end
	for gIndex,gchar in pairs(writings) do --need to clear the table now
		table.remove(writings,gIndex)
	end
	--print("unpaused")
end

function addPauseWeaponDetails(theString, trow, tcolumn)
	local spacing = 4
	local row = trow
	local column = tcolumn
	local lchars = {}
	lchars = lstrtochar(theString)
	column -= math.floor(#lchars * spacing / 2)
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), row, letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
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
	statrow += 1 --move on to the next line
	lchars = lstrtochar("heal bonus: " .. tostring(pstats[17]))
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("vampire: " .. tostring(pstats[18]) .. "%")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
	statrow += 1 --move on to the next line
	lchars = lstrtochar("stun: " .. tostring(pstats[19]) .. "%")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row + newline * statrow), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
end

function addDifficulty()
	local spacing = 4
	local row = 20
	local column = 162
	local lchars = {}
	lchars = lstrtochar("difficulty --" .. tostring(getDifficulty()) .. "--")
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), (row), letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
end

function clearPauseMenu()
	gun1Sprite:setImage(gun1Image)
	gun2Sprite:setImage(gunxImage)
	gun3Sprite:setImage(gunxImage)
	gun4Sprite:setImage(gunxImage)
end