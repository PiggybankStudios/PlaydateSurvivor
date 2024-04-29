import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/math"

import "globals"
import "tags"

bump = import "bump"
import "LDtk"

import "savefile"

import "healthbar" -- edit player healthbar so we can get rid of this
import "uibanner"
import "pausemenu"

--import "expbar"


import "controls"
import "player"
import "camera"
import "mun"
import "item_v2"
import "enemy_v2"
import "bullet_v2"
import "particle"
import "write"
import "writefunctions"
import "gameScene_v2"
import "startmenu"
import "mainmenu"
import "deathmenu"
import "levelupmenu"
import "weaponmenu"
import "bulletGraphic"




-- +--------------------------------------------------------------+
-- |                          Constants                           |
-- +--------------------------------------------------------------+

-- extensions
local pd <const> = playdate
local gfx <const> = pd.graphics

-- time
local getMilliseconds <const> = pd.getCurrentTimeMilliseconds

-- math
local floor 	<const> = math.floor
local random 	<const> = math.random

-- sprites and color
local setColor <const> = gfx.setColor
local colorWhite <const> = gfx.kColorWhite
local colorBlack <const> = gfx.kColorBlack

-- controls
local crankAngle <const> = pd.getCrankPosition


-- Update Functions
local c_UpdatePlayer 	<const> = updatePlayer
local c_UpdateCamera 	<const> = updateCamera
local c_UpdateBullets 	<const> = updateBullets
local c_UpdateEnemies	<const> = updateEnemies
local c_UpdateGameScene <const> = updateGameScene

local c_DrawPlayerUI <const> = drawPlayerUI

-- +--------------------------------------------------------------+
-- |                        Inits for Main                        |
-- +--------------------------------------------------------------+

local recycleValue = 0
local mainLoopTime = 0
local mainTimePassed = 0
local elapsedPauseTime = 0
local startPauseTime = 0


local menuCopy = pd.getSystemMenu()
--local menuItem, error = menuCopy:addMenuItem("Main Menu", returnToMenuCall())

elapsedTime = 0
currentState = GAMESTATE.startscreen
lastState = GAMESTATE.nothing

-- Set Background Color
gfx.setBackgroundColor(colorBlack)

-- Lower Garbage Collection time to have more CPU bandwidth - default is 1
pd.setMinimumGCTime(0.5)


-- +--------------------------------------------------------------+
-- |                       Tracked Values                         |
-- +--------------------------------------------------------------+

local shotsFired = 0
local itemsCollected = 0
local screenOffsetX, screenOffsetY = 0, 0

-- +--------------------------------------------------------------+
-- |                         Main Update                          |
-- +--------------------------------------------------------------+

---------
local resetTime <const> = pd.resetElapsedTime
local getTime <const> = pd.getElapsedTime

local timerWindow = 0
local totalElapseTime = 0
local timeInstances = 0
local TIME_INSTANCE_MAX <const> = 500
local averageTime = 0
local maxTime = 0
local minTime = 1

local function addTotalTime()
	if timeInstances >= TIME_INSTANCE_MAX then return end

	local elapsed = getTime()
	totalElapseTime += elapsed
	timeInstances += 1

	if elapsed < minTime then 
		minTime = elapsed
	elseif elapsed > maxTime then 
		maxTime = elapsed
	end
end

local function printAndClearTotalTime(activeNameAsString, activeObject)
	-- avoid divide by 0
	if timeInstances == 0 then return end

	-- time instance check
	if timeInstances < TIME_INSTANCE_MAX then return end 

	-- calc average
	averageTime = totalElapseTime / timeInstances

	local objectName = activeNameAsString or ""
	local object = activeObject or ""

	-- print statistics
	print(	"------------")
	print(	objectName .. ": " .. object ..
			" - total time: " .. totalElapseTime .. 
			" - average time: " .. averageTime .. 
			" - time instances: " .. timeInstances .. 
			" - min: " .. minTime .. 
			" - max: " .. maxTime)

	-- reset values for new data
	totalElapseTime = 0
	averageTime = 0
	timeInstances = 0
	minTime = 1
	maxTime = 0
end
--------



gameScene_init()	-- Testing scene outside of main, will put back into scene loading later



function pd.update()

	local time = getMilliseconds()
	local crank = floor(crankAngle())

	c_UpdateGameScene(screenOffsetX, screenOffsetY)

	--- debugging here ---
	--gameSceneDebugUpdate()
	----------------------

	-- Controls, Player, Camera
	local inputX, inputY, inputButtonB = updateControls_DuringGamePlay()
	local playerX, playerY = c_UpdatePlayer(time, inputX, inputY, inputButtonB, crank, shotsFired, itemsCollected)

	local cameraPosX, cameraPosY
	screenOffsetX, screenOffsetY, cameraPosX, cameraPosY = c_UpdateCamera(time, crank, playerX, playerY)

	-- Bullets, Enemies, Items
	shotsFired = c_UpdateBullets(time, crank, playerX, playerY, screenOffsetX, screenOffsetY)
	c_UpdateEnemies(time, playerX, playerY, cameraPosX, cameraPosY, screenOffsetX, screenOffsetY)
	itemsCollected = updateItems(time, playerX, playerY, screenOffsetX, screenOffsetY)

	-- Particles, UI
	--updateParticles(dt, mainTimePassed, mainLoopTime, elapsedPauseTime)
	
	-- UI
	c_DrawPlayerUI()


--printAndClearTotalTime("level draw in main")

	playdate.drawFPS()
end



--[[
function playdate.update()
	mainLoopTime = playdate.getCurrentTimeMilliseconds()

	dt = 1/20
	elapsedTime = elapsedTime + dt

	-- Start Screen
	if currentState == GAMESTATE.startscreen then
		if lastState == GAMESTATE.deathscreen then
			cleanLetters()
			closeDeadMenu()
			--snapCamera() somehow need to handle offset on death
			gfx.sprite.removeAll()
			openStartMenu()
			lastState = currentState
		elseif lastState == GAMESTATE.nothing then
			initializeConfig()
			initializeSave()
			menuCopy:addMenuItem("Main Menu", returnToMenuCall)
			openStartMenu()
			lastState = currentState
		elseif lastState ~= currentState then
			--snapCamera() somehow need to handle offset on death
			cleanLetters()
			gfx.sprite.removeAll()
			openStartMenu()
			lastState = currentState
		else
			updateStartManu()
		end
		
	-- Main Menu
	elseif currentState == GAMESTATE.mainmenu then
		if lastState ~= currentState then
			cleanLetters()
			readConfigFile()
			closeStartMenu()
			openMainMenu()
			lastState = currentState
		else
			updateMainManu()
		end

	-- Main Game
	elseif currentState == GAMESTATE.maingame then
		if lastState == GAMESTATE.mainmenu then
			cleanLetters()
			closeMainMenu()
			gameScene()
			addClock()
			setPauseTime()
			setGameState(GAMESTATE.unpaused)
			setEndWaveText("start wave " .. getWave())
			setSpawnTime(mainLoopTime + (getConfigValue("pause_time") + 1)*1000)
			lastState = currentState
		elseif lastState ~= currentState then
			lastState = currentState
			elapsedPauseTime = mainLoopTime - startPauseTime
			if recycleValue ~= 0 then
				addEXP(recycleValue)
				recycleValue = 0
			end
		end
		
		cleanLetters()
		updateMun()
		updateWaveTime()
		updateWaveNumber()
		updatePlayer(dt)
		updateCamera(dt)
		updateBullets(dt, mainTimePassed, mainLoopTime, elapsedPauseTime)
		updateEnemies(dt, mainTimePassed, mainLoopTime)
		updateItems(dt, mainTimePassed, mainLoopTime)
		updateParticles(dt, mainTimePassed, mainLoopTime, elapsedPauseTime)
		gameSceneUpdate()
		startPauseTime = mainLoopTime

		-- clear possible pause time
		elapsedPauseTime = 0

	-- Pause Menu
	elseif currentState == GAMESTATE.pausemenu then
		if lastState ~= currentState then
			cleanLetters()
			openPauseMenu()
			lastState = currentState
		end
		updatePauseManu()
		updateCamera(dt)

	-- Level Up Menu
	elseif currentState == GAMESTATE.levelupmenu then
		if lastState ~= currentState then
			cleanLetters()
			openLevelUpMenu()
			lastState = currentState
		end
		updateLevelUpMenu()
		updateCamera(dt)

	-- Weapon Menu
	elseif currentState == GAMESTATE.newweaponmenu then
		if lastState ~= currentState then
			cleanLetters()
			openWeaponMenu(random(1, 6), decideWeaponTier())
			lastState = currentState
		end
		updateWeaponMenu()
		updateCamera(dt)

	-- Death Screen
	elseif currentState == GAMESTATE.deathscreen then
		if lastState ~= currentState then
			cleanLetters()
			openDeadMenu()
			startPauseTime = mainLoopTime
			lastState = currentState
		else
			updateDeadManu()
		end

	-- UnPaused
	elseif currentState == GAMESTATE.unpaused then
		if lastState ~= currentState then
			lastState = currentState
		end
		updateUnPaused()
		
	-- waveScreen
	elseif currentState == GAMESTATE.wavescreen then
		if lastState ~= currentState then
			cleanLetters()
			lastState = currentState
			startPauseTime = mainLoopTime
		else
			if getLevelUpList() > 0 then 
				incLevelUpList(-1)
				updateLevel()
			elseif getWeaponsGrabbedList() > 0 then
				incWeaponsGrabbedList(-1)
				setGameState(GAMESTATE.newweaponmenu)
			else
				setPauseTime()
				setGameState(GAMESTATE.unpaused)
				setEndWaveText("start wave " .. getWave())
			end
		end
		updateCamera(dt)
	end
	if getWaveOver() == true then
		screenFlash()
		clearItems()
		clearEnemies()
		clearBullets()
		clearParticles()
		setWaveOver(false)
		setSaveValue("level_up_list", getLevelUpList())
		setSaveValue("weapons_grabbed_list", getWeaponsGrabbedList())
		writeSaveFile(getConfigValue("Default_Save"))
		setGameState(GAMESTATE.wavescreen) 
	end

	gfx.sprite.update()

	mainTimePassed = getRunTime() - mainLoopTime
	--playdate.drawFPS()
end
]]

-- +--------------------------------------------------------------+
-- |                     Game State Functions                     |
-- +--------------------------------------------------------------+


function getGameState()
	return currentState
end


function setGameState(newState)
	currentState = newState
end


function recycleGun(value)
	recycleValue += value
end