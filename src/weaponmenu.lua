local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2
local menuSpot = 1

local blinking = false
local lastBlink = 0
local weaponTier

local newWeapon = 1

--setup main menu
local pauseImage = gfx.image.new('Resources/Sprites/menu/weaponMenu')
local pauseSprite = gfx.sprite.new(pauseImage)
pauseSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
pauseSprite:setZIndex(ZINDEX.ui)
pauseSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup selector
local selectImage = gfx.image.new('Resources/Sprites/menu/levelUpselect')
local selectSprite = gfx.sprite.new(selectImage)
selectSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
selectSprite:setZIndex(ZINDEX.uidetails)
selectSprite:moveTo(346, 40)

--new Weapon
local gunNewSprite = gfx.sprite.new(selectWeaponImage(1))
gunNewSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
gunNewSprite:setZIndex(ZINDEX.uidetails)
gunNewSprite:moveTo(150, 110)

function openWeaponMenu(newWeap, tier)
	pauseSprite:add()
	selectSprite:add()
	gun1Sprite:add()
	gun2Sprite:add()
	gun3Sprite:add()
	gun4Sprite:add()
	gunNewSprite:setImage(selectWeaponImage(newWeap))
	local strSend = GUN_NAMES[newWeap] .. getTierStr(tier)
	writeTextToScreen(148, 132, strSend, true, true)
	newWeapon = newWeap
	gunNewSprite:add()
	blinking = true
	weaponTier = tier
	for i=1,4,1 do
		if getEquippedGun(i) ~= 0 then 
			local strSend = GUN_NAMES[getEquippedGun(i)] .. getTierStr(getTierForGun(i))
			writeTextToScreen(346, 15 + (45 * i), strSend, true, true)
		end
	end
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

function getTierStr(value)
	if value == 1 then
		return "*"
	elseif value == 2 then
		return "**"
	elseif value == 3 then
		return "***"
	else
		return " "
	end
end

function newWeaponSlot()
	return menuSpot
end

function newWeaponGot()
	return newWeapon
end

function getGunName(name)
	return GUN_NAMES[name]
end

function getweaponTier()
	return weaponTier
end