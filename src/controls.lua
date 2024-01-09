-- playdate screen 400 x 240

local inputX = 0 
local inputY = 0
local physicalCrankAngle = playdate.getCrankPosition()
local crankAngle = physicalCrankAngle - 90


function handleDeath()
	setGameState(GAMESTATE.deathscreen)
	clearAllThings()
	clearFlash()
end

function clearAllThings()
	clearItems()
	clearEnemies()
	clearBullets()
	clearPauseMenu()
end

-- +--------------------------------------------------------------+
-- |                            Input                             |
-- +--------------------------------------------------------------+

function getCrankAngle()
	return crankAngle
end

function getInputX()
	return inputX
end

function getInputY()
	return inputY
end

function resetInputXY()
	inputX = 0
	inputY = 0
end

function playdate.leftButtonDown()
	inputX = -1
	if getGameState() == GAMESTATE.pausemenu then pauseMenuMoveL() end
	if getGameState() == GAMESTATE.levelupmenu then pauseLevelUpMoveL() end
end
function playdate.leftButtonUp()
	inputX = 0
end
function playdate.rightButtonDown()
	inputX = 1
	if getGameState() == GAMESTATE.pausemenu then pauseMenuMoveR() end
	if getGameState() == GAMESTATE.levelupmenu then pauseLevelUpMoveR() end
end
function playdate.rightButtonUp()
	inputX = 0
end
function playdate.upButtonDown()
	inputY = -1
	if getGameState() == GAMESTATE.newweaponmenu then weaponMenuMoveU() end
end
function playdate.upButtonUp()
	inputY = 0
end
function playdate.downButtonDown()
	inputY = 1
	if getGameState() == GAMESTATE.newweaponmenu then weaponMenuMoveD() end
end
function playdate.downButtonUp()
	inputY = 0
end

function playdate.BButtonDown()
	playerRunSpeed = 2
end

function playdate.BButtonUp()
	playerRunSpeed = 1
end

function playdate.AButtonDown()
	if getGameState() == GAMESTATE.startscreen then
		setGameState(GAMESTATE.maingame)
		gameStartTime = playdate.getCurrentTimeMilliseconds()
	elseif getGameState() == GAMESTATE.maingame then
		openPauseMenu()
		setGameState(GAMESTATE.pausemenu)
	elseif getGameState() == GAMESTATE.levelupmenu then
		upgradeStat(levelUpSelection(),levelUpBonus())
		closeLevelUpMenu()
		setUnpaused(true)
		setGameState(GAMESTATE.maingame)
	elseif getGameState() == GAMESTATE.newweaponmenu then
		if newWeaponSlot() ~= 5 then
			newWeaponChosen(newWeaponGot(), newWeaponSlot())
		else
			recycleGun(5)
		end
		closeWeaponMenu()
		setUnpaused(true)
		setGameState(GAMESTATE.maingame)
	elseif getGameState() == GAMESTATE.pausemenu then
		if pauseSelection() == 0 then
			closePauseMenu()
			setUnpaused(true)
			setGameState(GAMESTATE.maingame)
		elseif pauseSelection() == 1 then
			closePauseMenu()
			setUnpaused(true)
			clearAllThings()
			clearStats()
			restartGame()
			setGameState(GAMESTATE.maingame)
		elseif pauseSelection() == 2 then
			closePauseMenu()
			setUnpaused(true)
			clearAllThings()
			clearStats()
			setGameState(GAMESTATE.startscreen)
		end
			
	elseif getGameState() == GAMESTATE.deathscreen then
		setGameState(GAMESTATE.startscreen)
		clearStats()
	end
end

function playdate.cranked(change, acceleratedChange)
	physicalCrankAngle += change
	crankAngle = physicalCrankAngle - 90
end

