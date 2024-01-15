local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2

local blinking = false
local lastBlink = 0

--setup main menu
local startMenu = gfx.image.new('Resources/Sprites/startMenu')
local startSprite = gfx.sprite.new(startMenu)
startSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
startSprite:setZIndex(ZINDEX.ui)
startSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup prompt
local promptImage = gfx.image.new('Resources/Sprites/mainPrompt')
local promptSprite = gfx.sprite.new(promptImage)
promptSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
promptSprite:setZIndex(ZINDEX.uidetails)
promptSprite:moveTo(190, 212)


function openStartMenu()
	startSprite:add()
	promptSprite:add()
	blinking = true
	--print("paused")
end

function updateStartManu()
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

function closeStartMenu()
	startSprite:remove()
	if blinking == true then promptSprite:remove() end
	--print("unpaused")
end
