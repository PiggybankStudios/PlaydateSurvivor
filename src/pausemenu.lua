local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2
local menuSpot = 0
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
local gun0Image = gfx.image.new('Resources/Sprites/gEmpty')
local gun1Image = gfx.image.new('Resources/Sprites/gPea')
local gun2Image = gfx.image.new('Resources/Sprites/gCannon')
local gun3Image = gfx.image.new('Resources/Sprites/gMini')
local gun4Image = gfx.image.new('Resources/Sprites/gShot')
local gun1Sprite = gfx.sprite.new(gun1Image)
local gun2Sprite = gfx.sprite.new(gun0Image)
local gun3Sprite = gfx.sprite.new(gun0Image)
local gun4Sprite = gfx.sprite.new(gun0Image)
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
	--print("paused")
end

function closePauseMenu()
	pauseSprite:remove()
	selectSprite:remove()
	gun1Sprite:remove()
	gun2Sprite:remove()
	gun3Sprite:remove()
	gun4Sprite:remove()
	selectSprite:moveTo(55, 212)
	--print("unpaused")
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

function updateMenuWeapon(slot, gun)
	local newGun = gun0Image
	if gun == 1 then newGun = gun1Image
	elseif gun == 2 then newGun = gun2Image
	elseif gun == 3 then newGun = gun3Image
	elseif gun == 4 then newGun = gun4Image
	else newGun = gun0Image
	end
	
	if slot == 1 then gun1Sprite:setImage(newGun)
	elseif slot == 2 then gun2Sprite:setImage(newGun)
	elseif slot == 3 then gun3Sprite:setImage(newGun)
	elseif slot == 4 then gun4Sprite:setImage(newGun)
	else print("slot doesnt exist")
	end
end

