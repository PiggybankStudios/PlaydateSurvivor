-- playdate screen 400 x 240

local pd <const> = playdate

local inputXL = 0
local inputXR = 0
local inputYU = 0
local inputYD = 0


local function clearAllThings()
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


function handleDeath()
	print("handling death")
	setGameState(GAMESTATE.deathscreen)
	clearAllThings()
	clearFlash()
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

--[[
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
	--if getGameState() == GAMESTATE.startscreen then
	--	setGameState(GAMESTATE.mainmenu)
	--elseif getGameState() == GAMESTATE.deathscreen then
	--	setGameState(GAMESTATE.startscreen)
	--	clearStats()
	--else
		setRunSpeed(2)
		debugSpawnMassEnemy()
	--end

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
]]

-----------------
------DEBUG------
-----------------

--[[
function pd.BButtonDown()
	--spawnTwoEnemies()
	--debugSpawnMassEnemy()
end
]]

-----------------
-----------------
-----------------


-- +--------------------------------------------------------------+
-- |                       General Controls                       |
-- +--------------------------------------------------------------+

local UP 		<const> = pd.kButtonUp
local DOWN 		<const> = pd.kButtonDown
local LEFT 		<const> = pd.kButtonLeft
local RIGHT 	<const> = pd.kButtonRight
local A_BUTTON 	<const> = pd.kButtonA
local B_BUTTON 	<const> = pd.kButtonB

local button_pressed 		<const> = pd.buttonIsPressed
local button_just_pressed 	<const> = pd.buttonJustPressed

local inputX, inputY = 0
local inputButtonB = 0
local inputButtonA = false

local inputLock = false


function resetInput()
	inputX, inputY = 0
	inputButtonB = 0
	inputButtonA = false
end


-- +--------------------------------------------------------------+
-- |                      Main Gameplay Loop                      |
-- +--------------------------------------------------------------+

function updateControls_SetInputLockForMainGameControls(value)
	inputLock = value
end


function updateControls_MainGame()

	if inputLock then return 0, 0, 0 end

	-- Moving Up and Down
	if 		button_pressed(UP) 		then 	inputY = -1
	elseif 	button_pressed(DOWN) 	then 	inputY = 1
	else 									inputY = 0 	
	end

	-- Moving Left and Right
	if 		button_pressed(LEFT) 	then 	inputX = -1
	elseif 	button_pressed(RIGHT)	then 	inputX = 1
	else 									inputX = 0
	end

	-- Toggle Run if held
	if 		button_pressed(B_BUTTON) then 	inputButtonB = 2
	else 									inputButtonB = 1
	end

	return inputX, inputY, inputButtonB
end


-- +--------------------------------------------------------------+
-- |                          ----------                          |
-- +--------------------------------------------------------------+
