local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local playerMun = 0
local playerTotalMun = 0

function initializeMun()
	playerTotalMun = getSaveValue("mun")
end

function updateMun()
	local totalMun = "mun:" .. playerMun
	writeTextToScreen(halfScreenWidth - 5, 18, totalMun, true, true)
end

function updateTotalMun()
	local totalMun = "mun:" .. playerTotalMun
	writeTextToScreen(halfScreenWidth - 150, 30, totalMun, true, false)
end

function addMun(amount)
	playerMun += amount
	cleanLetters()
	updateMun()
end

function addTotalMun(amount)
	playerTotalMun = getSaveValue("mun") + amount
	setSaveValue("mun", playerTotalMun)
	writeSaveFile(getConfigValue("Default_Save"))
end

function getMun()
	return playerMun
end

function getTotalMun()
	return playerTotalMun
end