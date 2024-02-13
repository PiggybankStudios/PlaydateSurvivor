import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/math"

import "LDtk"

import "tags"
import "savefile"
--import "bullet"
import "bullet_v2"
import "particle"
import "healthbar"
import "uibanner"
import "pausemenu"
import "write"
import "writefunctions"
import "expbar"
import "enemy"
import "controls"
import "player"
import "camera"
import "gameScene"
import "mun"
--import "item"
import "item_v2"
import "startmenu"
import "mainmenu"
import "deathmenu"
import "levelupmenu"
import "weaponmenu"
import "bulletGraphic"

local random <const> = math.random

local gfx <const> = playdate.graphics
local recycleValue = 0
local mainLoopTime = 0
local mainTimePassed = 0
local elapsedPauseTime = 0
local startPauseTime = 0

gfx.setColor(gfx.kColorWhite)
gfx.fillRect(0, 0, 400, 240)
gfx.setBackgroundColor(gfx.kColorBlack)

local menuCopy = playdate.getSystemMenu()
--local menuItem, error = menuCopy:addMenuItem("Main Menu", returnToMenuCall())

elapsedTime = 0
currentState = GAMESTATE.startscreen
lastState = GAMESTATE.nothing


-- +--------------------------------------------------------------+
-- |                         Main Update                          |
-- +--------------------------------------------------------------+

function recycleGun(value)
	recycleValue += value
end

function getRunTime()
	return mainLoopTime
end

function playdate.update()
	mainLoopTime = playdate.getCurrentTimeMilliseconds()

	dt = 1/20
	elapsedTime = elapsedTime + dt
	gfx.sprite.setAlwaysRedraw(true)	-- causes all sprites to always redraw. Should help performance since there are so many moving images on the screen

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
		updateEnemies(dt)
		updateItems(dt, mainTimePassed, mainLoopTime)
		updateParticles(dt, mainTimePassed, mainLoopTime, elapsedPauseTime)
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


-- +--------------------------------------------------------------+
-- |                     Game State Functions                     |
-- +--------------------------------------------------------------+

function getGameState()
	return currentState
end


function setGameState(newState)
	currentState = newState
end