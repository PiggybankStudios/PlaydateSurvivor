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
	clearParticles()
	clearPauseMenu()
end

function returnToMenuCall()
	if getGameState() == GAMESTATE.startscreen then
		print("Why reset the start screen?")
	elseif getGameState() == GAMESTATE.mainmenu then
			closeMainMenu()
	elseif getGameState() == GAMESTATE.levelupmenu then
			closeLevelUpMenu()
			clearAllThings()
			clearStats()
	elseif getGameState() == GAMESTATE.newweaponmenu then
			closeWeaponMenu()
			clearAllThings()
			clearStats()
	elseif getGameState() == GAMESTATE.pausemenu then
			closePauseMenu()
			clearAllThings()
			clearStats()
	elseif getGameState() == GAMESTATE.maingame then
			clearAllThings()
			clearStats()
	elseif getGameState() == GAMESTATE.deathscreen then
			closeDeadMenu()
			clearStats()
	else print("reset from unhandled state") end
	setGameState(GAMESTATE.startscreen)
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
	if getGameState() == GAMESTATE.pausemenu then print("no move L")--pauseMenuMoveL()
	elseif getGameState() == GAMESTATE.levelupmenu then pauseLevelUpMoveL() end
end
function playdate.leftButtonUp()
	inputX = 0
end
function playdate.rightButtonDown()
	inputX = 1
	if getGameState() == GAMESTATE.pausemenu then print("no move R")--pauseMenuMoveR()
	elseif getGameState() == GAMESTATE.levelupmenu then pauseLevelUpMoveR() end
end
function playdate.rightButtonUp()
	inputX = 0
end
function playdate.upButtonDown()
	inputY = -1
	if getGameState() == GAMESTATE.newweaponmenu then weaponMenuMoveU()
	elseif getGameState() == GAMESTATE.mainmenu then mainMenuMoveU() end
end
function playdate.upButtonUp()
	inputY = 0
end
function playdate.downButtonDown()
	inputY = 1
	if getGameState() == GAMESTATE.newweaponmenu then weaponMenuMoveD()
	elseif getGameState() == GAMESTATE.mainmenu then mainMenuMoveD() end
end
function playdate.downButtonUp()
	inputY = 0
end

function playdate.BButtonDown()
	if getGameState() == GAMESTATE.startscreen then
		setGameState(GAMESTATE.mainmenu)
	else
		setRunSpeed(2)
	end
end

function playdate.BButtonUp()
	setRunSpeed(1)
end

function playdate.AButtonDown()
	if getGameState() == GAMESTATE.startscreen then
		setGameState(GAMESTATE.mainmenu)
	elseif getGameState() == GAMESTATE.mainmenu then
		if MainMenuNavigate() == true then
			setGameState(GAMESTATE.maingame)
			gameStartTime = playdate.getCurrentTimeMilliseconds()
		end
	elseif getGameState() == GAMESTATE.maingame then
		setGameState(GAMESTATE.pausemenu)
	elseif getGameState() == GAMESTATE.levelupmenu then
		upgradeStat(levelUpSelection(),levelUpBonus())
		closeLevelUpMenu()
		setUnpaused(true)
		setGameState(GAMESTATE.maingame)
	elseif getGameState() == GAMESTATE.newweaponmenu then
		if newWeaponSlot() ~= 5 then
			newWeaponChosen(newWeaponGot(), newWeaponSlot(), getweaponTier())
		else
			recycleGun(5)
		end
		closeWeaponMenu()
		setUnpaused(true)
		setGameState(GAMESTATE.maingame)
	elseif getGameState() == GAMESTATE.pausemenu then
		closePauseMenu()
		setUnpaused(true)
		setGameState(GAMESTATE.maingame)
			
	elseif getGameState() == GAMESTATE.deathscreen then
		setGameState(GAMESTATE.startscreen)
		clearStats()
	end
end

function playdate.cranked(change, acceleratedChange)
	physicalCrankAngle += change
	crankAngle = physicalCrankAngle - 90
end

