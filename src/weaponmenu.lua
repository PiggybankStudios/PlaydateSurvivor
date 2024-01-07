local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2
local menuSpot = 1

local blinking = false
local lastBlink = 0

local writings = {}
local newWeapon = 1
local gunnames = {"pistol", "cannon", "minigun", "shotgun", "burst rifle", "grenade launcher", "boomerang", "wave gun"}

--setup main menu
local pauseImage = gfx.image.new('Resources/Sprites/weaponMenu')
local pauseSprite = gfx.sprite.new(pauseImage)
pauseSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
pauseSprite:setZIndex(ZINDEX.ui)
pauseSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup selector
local selectImage = gfx.image.new('Resources/Sprites/levelUpselect')
local selectSprite = gfx.sprite.new(selectImage)
selectSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
selectSprite:setZIndex(ZINDEX.uidetails)
selectSprite:moveTo(346, 40)

--new Weapon
local gunNewSprite = gfx.sprite.new(selectWeaponImage(1))
gunNewSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
gunNewSprite:setZIndex(ZINDEX.uidetails)
gunNewSprite:moveTo(150, 110)

function openWeaponMenu(newWeap)
	pauseSprite:add()
	selectSprite:add()
	gun1Sprite:add()
	gun2Sprite:add()
	gun3Sprite:add()
	gun4Sprite:add()
	gunNewSprite:setImage(selectWeaponImage(newWeap))
	addWeaponDetails(getGunName(newWeap))
	newWeapon = newWeap
	gunNewSprite:add()
	blinking = true
	--print("paused")
end

function closeWeaponMenu()
	pauseSprite:remove()
	if blinking == true then selectSprite:remove() end
	gun1Sprite:remove()
	gun2Sprite:remove()
	gun3Sprite:remove()
	gun4Sprite:remove()
	gunNewSprite:remove()
	selectSprite:moveTo(346, 40)
	menuSpot = 1
	for gIndex,gchar in pairs(writings) do --need all graphics removed first
		writings[gIndex]:remove()
	end
	for gIndex,gchar in pairs(writings) do --need to clear the table now
		table.remove(writings,gIndex)
	end
	--print("unpaused")
end

function updateWeaponMenu()
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

function weaponMenuMoveD()
	if menuSpot == 1 then 
		if getPlayerSlots() == 2 then
			selectSprite:moveTo(346, 85)
			menuSpot = 2
		elseif getPlayerSlots() == 3 then
			selectSprite:moveTo(346, 130)
			menuSpot = 3
		elseif getPlayerSlots() == 4 then
			selectSprite:moveTo(346, 175)
			menuSpot = 4
		else
			selectSprite:moveTo(346, 210)
			menuSpot = 5
		end
	elseif menuSpot == 2 then 
		if getPlayerSlots() == 3 then
			selectSprite:moveTo(346, 130)
			menuSpot = 3
		elseif getPlayerSlots() == 4 then
			selectSprite:moveTo(346, 175)
			menuSpot = 4
		else
			selectSprite:moveTo(346, 210)
			menuSpot = 5
		end
	elseif menuSpot == 3 then 
		if getPlayerSlots() == 4 then
			selectSprite:moveTo(346, 175)
			menuSpot = 4
		else
			selectSprite:moveTo(346, 210)
			menuSpot = 5
		end
	elseif menuSpot == 4 then 
		selectSprite:moveTo(346, 210)
		menuSpot = 5
	elseif menuSpot == 5 then 
		selectSprite:moveTo(346, 40)
		menuSpot = 1
	end
end

function weaponMenuMoveU()
	if menuSpot == 1 then 
		selectSprite:moveTo(346, 210)
		menuSpot = 5
	elseif menuSpot == 2 then 
		selectSprite:moveTo(346, 40)
		menuSpot = 1
	elseif menuSpot == 3 then 
		selectSprite:moveTo(346, 85)
		menuSpot = 2
	elseif menuSpot == 4 then 
		selectSprite:moveTo(346, 130)
		menuSpot = 3
	elseif menuSpot == 5 then 
		if getPlayerSlots() == 1 then
			selectSprite:moveTo(346, 40)
			menuSpot = 1
		elseif getPlayerSlots() == 2 then
			selectSprite:moveTo(346, 85)
			menuSpot = 2
		elseif getPlayerSlots() == 3 then
			selectSprite:moveTo(346, 130)
			menuSpot = 3
		else
			selectSprite:moveTo(346, 175)
			menuSpot = 4
		end
	end
end

function addWeaponDetails(theString)
	local spacing = 4
	local row = 140
	local column = 130
	local lchars = {}
	lchars = lstrtochar(theString)
	for lIndex,letter in pairs(lchars) do
		newLetter = write((column + spacing * lIndex), row, letter, true)
		newLetter:add()
		writings[#writings + 1] = newLetter
	end
end

function newWeaponSlot()
	return menuSpot
end

function newWeaponGot()
	return newWeapon
end

function getGunName(name)
	return gunnames[name]
end