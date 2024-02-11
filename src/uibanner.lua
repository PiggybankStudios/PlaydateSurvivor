local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2

local bannerHeight <const> = 30
local halfBannerHeight <const> = bannerHeight / 2
local timerTime = 0
local lastTime = 0
local targTime = 0
local waveTime = 20
local waveNumber = 1
local waveOver = false


-- +--------------------------------------------------------------+
-- |                          Draw Banner                         |
-- +--------------------------------------------------------------+

--setup main menu
local clockImage = gfx.image.new('Resources/Sprites/lClockBox')
local clockSprite = gfx.sprite.new(clockImage)
clockSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
clockSprite:setZIndex(ZINDEX.uibanner)
clockSprite:moveTo(halfScreenWidth, 25)

local bannerImage = gfx.image.new('Resources/Sprites/UIBanner')
local bannerSprite = gfx.sprite.new(bannerImage)
bannerSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
bannerSprite:setZIndex(ZINDEX.uibanner)
bannerSprite:moveTo(halfScreenWidth, halfBannerHeight)


-- +--------------------------------------------------------------+
-- |                       Banner Functions                       |
-- +--------------------------------------------------------------+


function addUIBanner()
	targTime = getRunTime()
	waveNumber = getSaveValue("waveNumber")
	setDifficulty(waveNumber)
	setWaveTime()
	bannerSprite:add()
end

function hideUIBanner()
	bannerSprite:remove()
end

function addClock()
	clockSprite:add()
end

function hideClock()
	clockSprite:remove()
end

function getHalfUIBannerHeight()
	return halfBannerHeight
end

function updateWaveTime()
	local runTime = getRunTime()
	if getUnpaused() == true then targTime += runTime - lastTime end
	timerTime = waveTime - math.ceil((runTime - targTime)/1000)
	writeTextToScreen(halfScreenWidth - 5, 25, tostring(timerTime), true, false)
	lastTime = getRunTime()
	if timerTime <= 0 then handleEndWave() end
end

function updateWaveNumber()
	local currWave = "wave:" .. waveNumber
	writeTextToScreen(360, 18, currWave, false, true)
end

function getWave()
	return waveNumber
end

function incWave(amount)
	waveNumber += amount
	setDifficulty(waveNumber)
	setSaveValue("waveNumber", waveNumber)
end

function getWaveTime()
	return waveTime
end

function setWaveTime()
	waveTime = 26 + (waveNumber * 5)
end

function handleEndWave()
	targTime = getRunTime()
	setEndWaveText("end wave " .. waveNumber)
	incWave(1)
	setWaveTime()
	setWaveOver(true)
	--setGameState(GAMESTATE.wavescreen)
end

function getWaveOver()
	return waveOver
end

function setWaveOver(value)
	waveOver = value
end