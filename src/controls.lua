-- playdate screen 400 x 240

local pd <const> = playdate
local physicalCrankAngle <const> = pd.getCrankPosition

local inputX = 0 
local inputY = 0
local crankAngle = physicalCrankAngle() - 90


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

function pd.leftButtonDown()
	inputX = -1
	if getGameState() == GAMESTATE.pausemenu then print("no move L")--pauseMenuMoveL()
	elseif getGameState() == GAMESTATE.levelupmenu then pauseLevelUpMoveL() end
end
function pd.leftButtonUp()
	inputX = 0
end
function pd.rightButtonDown()
	inputX = 1
	if getGameState() == GAMESTATE.pausemenu then print("no move R")--pauseMenuMoveR()
	elseif getGameState() == GAMESTATE.levelupmenu then pauseLevelUpMoveR() end
end
function pd.rightButtonUp()
	inputX = 0
end
function pd.upButtonDown()
	inputY = -1
	if getGameState() == GAMESTATE.newweaponmenu then weaponMenuMoveU()
	elseif getGameState() == GAMESTATE.mainmenu then mainMenuMoveU() end
end
function pd.upButtonUp()
	inputY = 0
end
function pd.downButtonDown()
	inputY = 1
	if getGameState() == GAMESTATE.newweaponmenu then weaponMenuMoveD()
	elseif getGameState() == GAMESTATE.mainmenu then mainMenuMoveD() end
end
function pd.downButtonUp()
	inputY = 0
end


function pd.BButtonDown()
	if getGameState() == GAMESTATE.startscreen then
		setGameState(GAMESTATE.mainmenu)
	else
		--setRunSpeed(2)
		--worldToggleDrawCells()
		debugSpawnMassEnemy()
		--debugSpawnMassAllEnemies()
	end

end


function pd.BButtonUp()
	setRunSpeed(1)
end

function pd.AButtonDown()
	if getGameState() == GAMESTATE.startscreen then
		setGameState(GAMESTATE.mainmenu)
	elseif getGameState() == GAMESTATE.mainmenu then
		if MainMenuNavigate() == true then
			setGameState(GAMESTATE.maingame)
			gameStartTime = pd.getCurrentTimeMilliseconds()
		end
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
			newWeaponChosen(newWeaponGot(), newWeaponSlot(), getweaponTier())
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

-- constrains crankAngle to 0 - 360 range
function pd.cranked()
	crankAngle = physicalCrankAngle() - 90
end

