-- playdate screen 400 x 240

local pd <const> = playdate
local physicalCrankAngle <const> = pd.getCrankPosition

local inputXL = 0
local inputXR = 0
local inputYU = 0
local inputYD = 0
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
	hideUIBanner()
	hideClock()
	setWaveOver(false)
	incWave(1 - getWave())
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
	--print("x:"..inputXL..","..inputXR)
	return (inputXR - inputXL)
end

function getInputY()
	--print("y:"..inputYU..","..inputYD)
	return (inputYD - inputYU)
end

function resetInputXY()
	inputXL = 0 
	inputXR = 0 
	inputYU = 0
	inputYD = 0
end

function pd.leftButtonDown()
	inputXL = 1
	if getGameState() == GAMESTATE.levelupmenu then pauseLevelUpMoveL() end
end
function pd.leftButtonUp()
	inputXL = 0
end

function playdate.rightButtonDown()
	inputXR = 1
	if getGameState() == GAMESTATE.levelupmenu then pauseLevelUpMoveR() end
end
function pd.rightButtonUp()
	inputXR = 0
end

function playdate.upButtonDown()
	inputYU = 1
	if getGameState() == GAMESTATE.newweaponmenu then weaponMenuMoveU()
	elseif getGameState() == GAMESTATE.mainmenu then mainMenuMoveU() end
end
function pd.upButtonUp()
	inputYU = 0
end

function playdate.downButtonDown()
	inputYD = 1
	if getGameState() == GAMESTATE.newweaponmenu then weaponMenuMoveD()
	elseif getGameState() == GAMESTATE.mainmenu then mainMenuMoveD() end
end
function pd.downButtonUp()
	inputYD = 0
end


function pd.BButtonDown()
	if getGameState() == GAMESTATE.startscreen then
		setGameState(GAMESTATE.mainmenu)
	elseif getGameState() == GAMESTATE.deathscreen then
		setGameState(GAMESTATE.startscreen)
		clearStats()
	else
		setRunSpeed(2)
		--worldToggleDrawCells()
		--debugSpawnMassEnemy()
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
			gameStartTime = getRunTime()
		end
	elseif getGameState() == GAMESTATE.maingame then
		setGameState(GAMESTATE.pausemenu)
	elseif getGameState() == GAMESTATE.levelupmenu then
		upgradeStat(levelUpSelection(),levelUpBonus())
		closeLevelUpMenu()
		setGameState(GAMESTATE.wavescreen)
		--setGameState(GAMESTATE.maingame)
	elseif getGameState() == GAMESTATE.newweaponmenu then
		if newWeaponSlot() ~= 5 then
			newWeaponChosen(newWeaponGot(), newWeaponSlot(), getweaponTier())
		else
			recycleGun(5)
		end
		closeWeaponMenu()
		setGameState(GAMESTATE.wavescreen)
		--setGameState(GAMESTATE.maingame)
	elseif getGameState() == GAMESTATE.pausemenu then
		closePauseMenu()
		setGameState(GAMESTATE.unpaused)
			
	elseif getGameState() == GAMESTATE.deathscreen then
		setGameState(GAMESTATE.startscreen)
		clearStats()
	end
end

-- constrains crankAngle to 0 - 360 range
function pd.cranked()
	crankAngle = physicalCrankAngle() - 90
end

