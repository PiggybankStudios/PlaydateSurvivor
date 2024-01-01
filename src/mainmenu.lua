local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2

blinking = false
lastBlink = 0

--setup main menu
local mainImage = gfx.image.new('Resources/Sprites/mainMenu')
local mainSprite = gfx.sprite.new(mainImage)
mainSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
mainSprite:setZIndex(ZINDEX.ui)
mainSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup prompt
local promptImage = gfx.image.new('Resources/Sprites/mainPrompt')
local promptSprite = gfx.sprite.new(promptImage)
promptSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
promptSprite:setZIndex(ZINDEX.uidetails)
promptSprite:moveTo(190, 212)


function openMainMenu()
	mainSprite:add()
	promptSprite:add()
	blinking = true
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

function closeMainMenu()
	mainSprite:remove()
	if blinking == true then promptSprite:remove() end
	--print("unpaused")
end
