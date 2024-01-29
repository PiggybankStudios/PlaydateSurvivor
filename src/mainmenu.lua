local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2

local blinking = false
local lastBlink = 0
local menuSpot = 0

--setup main menu
local mainImage = gfx.image.new('Resources/Sprites/menu/mainMenu')
local mainSprite = gfx.sprite.new(mainImage)
mainSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
mainSprite:setZIndex(ZINDEX.ui)
mainSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup prompt
local promptImage = gfx.image.new('Resources/Sprites/menu/mainselect')
local promptSprite = gfx.sprite.new(promptImage)
promptSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
promptSprite:setZIndex(ZINDEX.uidetails)
promptSprite:moveTo(halfScreenWidth, 50)

function openMainMenu()
	mainSprite:add()
	promptSprite:add()
	writeTextToScreen(halfScreenWidth - 5, 50, "play", true, false)
	writeTextToScreen(halfScreenWidth - 5, 100, "upgrade", true, false)
	writeTextToScreen(halfScreenWidth - 5, 150, "options", true, false)
	writeTextToScreen(halfScreenWidth - 5, 200, "savefile", true, false)
	blinking = true
	menuSpot = 0
	--print("paused")
end

function updateMainManu()
	local theCurrTime = playdate.getCurrentTimeMilliseconds()
	if theCurrTime > lastBlink then
		lastBlink = theCurrTime + 500
		if blinking then
			promptSprite:remove()
			blinking = false
		else
			promptSprite:add()
			blinking = true
		end
	end
end

function mainMenuMoveU()
	if menuSpot == 0 then 
		promptSprite:moveTo(halfScreenWidth, 200)
		menuSpot = 3
	elseif menuSpot == 1 then 
		promptSprite:moveTo(halfScreenWidth, 50)
		menuSpot = 0
	elseif menuSpot == 2 then 
		promptSprite:moveTo(halfScreenWidth, 100)
		menuSpot = 1
	elseif menuSpot == 3 then 
		promptSprite:moveTo(halfScreenWidth, 150)
		menuSpot = 2
	end
end

function mainMenuMoveD()
	if menuSpot == 0 then 
		promptSprite:moveTo(halfScreenWidth, 100)
		menuSpot = 1
	elseif menuSpot == 1 then 
		promptSprite:moveTo(halfScreenWidth, 150)
		menuSpot = 2
	elseif menuSpot == 2 then 
		promptSprite:moveTo(halfScreenWidth, 200)
		menuSpot = 3
	elseif menuSpot == 3 then 
		promptSprite:moveTo(halfScreenWidth, 50)
		menuSpot = 0
	end
end

function closeMainMenu()
	mainSprite:remove()
	if blinking == true then promptSprite:remove() end
	cleanLetters()
	--print("unpaused")
end
