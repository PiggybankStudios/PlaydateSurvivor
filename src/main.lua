import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/math"

import "globals"
import "tags"

bump = import "bump"
import "LDtk"

import "savefile"

--import "healthbar" -- edit player healthbar so we can get rid of this
import "uibanner"

--import "expbar"


import "controls"
import "player"
import "camera"
import "mun"
import "item_v2"
import "enemy_v2"
import "bullet_v2"
import "particle"
import "objects"
import "write"
import "writefunctions"
import "gameScene_v2"

import "flowerMinigame"
import "newWeaponMenu"
import "playerUpgradeMenu"
import "levelModifierMenu"
import "startmenu"
import "mainmenu"
import "deathmenu"

import "levelupmenu"
import "weaponmenu"
import "bulletGraphic"

import "pausemenu_v2"

--- TEMPORARY - remove from final builds ---
import "transitions" 	-- code from transition animations, used in export process for transition image tables


-- +--------------------------------------------------------------+
-- |                          Constants                           |
-- +--------------------------------------------------------------+

-- extensions
local pd <const> = playdate
local gfx <const> = pd.graphics

-- time
local getMilliseconds 	<const> = pd.getCurrentTimeMilliseconds

-- GC
local COLLECT_GARBAGE 	<const> = collectgarbage

-- math
local floor 	<const> = math.floor
local ceil 		<const> = math.ceil
local random 	<const> = math.random
local min 		<const> = math.min
local max 		<const> = math.max
local sqrt 		<const> = math.sqrt

-- drawing
local GET_DRAW_OFFSET 		<const> = gfx.getDrawOffset
local SET_COLOR 			<const> = gfx.setColor
local COLOR_WHITE 			<const> = gfx.kColorWhite
local COLOR_BLACK 			<const> = gfx.kColorBlack
local SET_DITHER_PATTERN 	<const> = gfx.setDitherPattern
local DITHER_DIAGONAL 		<const> = gfx.image.kDitherTypeDiagonalLine
local FILL_RECT 			<const> = gfx.fillRect
local FILL_CIRCLE 			<const> = gfx.fillCircleAtPoint
local GET_IMAGE 			<const> = gfx.imagetable.getImage
local GET_LENGTH 			<const> = gfx.imagetable.getLength
local DRAW_IMAGE 			<const> = gfx.image.draw
local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local FLIP_XY 				<const> = gfx.kImageFlippedXY

-- controls
local crankAngle 	<const> = pd.getCrankPosition
local c_ResetInput 	<const> = resetInput

-- Main Game
local c_UpdateGameScene 			<const> = updateGameScene
local c_UpdateControls_MainGame 	<const> = updateControls_MainGame
local c_UpdatePlayer 				<const> = updatePlayer
local c_UpdateCamera 				<const> = updateCamera
local c_UpdateBullets 				<const> = updateBullets
local c_UpdateEnemies				<const> = updateEnemies
local c_UpdateItems 				<const> = updateItems
local c_UpdateObjects				<const> = updateObjects
local c_DrawPlayerUI 				<const> = drawPlayerUI

-- Pause Menu
local c_GetPauseTime_Player 		<const> = getPauseTime_Player
local c_GetPauseTime_Camera 		<const> = getPauseTime_Camera
local c_GetPauseTime_Bullets 		<const> = getPauseTime_Bullets
local c_GetPauseTime_Enemies 		<const> = getPauseTime_Enemies
local c_GetPauseTime_Items	 		<const> = getPauseTime_Items
local c_GetPauseTime_Objects 		<const> = getPauseTime_Objects

local c_RedrawPlayer 				<const> = redrawPlayer
local c_RedrawBullets 				<const> = redrawBullets
local c_RedrawEnemies 				<const> = redrawEnemies
local c_RedrawItems 				<const> = redrawItems
local c_RedrawObjects				<const> = redrawObjects

-- Transitions
local c_UpdateControls_SetInputLockForMainGameControls <const> = updateControls_SetInputLockForMainGameControls


-- +--------------------------------------------------------------+
-- |                         Game States                          |
-- +--------------------------------------------------------------+


local GS_MAIN_GAME 					<const> = GAMESTATE.maingame
local GS_PAUSE_MENU					<const> = GAMESTATE.pauseMenu
local GS_FLOWER_MINIGAME 			<const> = GAMESTATE.flowerMinigame
local GS_NEW_WEAPON_MENU			<const> = GAMESTATE.newWeaponMenu
local GS_PLAYER_UPGRADE_MENU		<const> = GAMESTATE.playerUpgradeMenu
local GS_LEVEL_MODIFIER_MENU		<const> = GAMESTATE.levelModifierMenu
local GS_DEATH_SCREEN				<const> = GAMESTATE.deathscreen
local GS_STARTSCREEN				<const> = GAMESTATE.startscreen
local GS_MAIN_MENU 					<const> = GAMESTATE.mainmenu	


-- +--------------------------------------------------------------+
-- |                            Timing                            |
-- +--------------------------------------------------------------+

local resetTime <const> = pd.resetElapsedTime
local getTime <const> = pd.getElapsedTime

local timerWindow = 0
local totalElapseTime = 0
local timeInstances = 0
local TIME_INSTANCE_MAX <const> = 250
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

-- Set Background Color
gfx.setBackgroundColor(COLOR_BLACK)

-- Lower Garbage Collection time to have more CPU bandwidth - default is 1
--pd.setMinimumGCTime(0.5)



-- +--------------------------------------------------------------+
-- |                       Tracked Values                         |
-- +--------------------------------------------------------------+

--------------
--- Shared ---
local currentState = GS_MAIN_GAME	--GAMESTATE.startscreen
local lastState = currentState


-----------------
--- Main Game ---
local shotsFired = 0
local itemsCollected = 0
local playerX, playerY = 0, 0 -- need this for camera updates, before player pos is updated


------------------
--- Pause Menu ---
local readyGo_imageTable 		= gfx.imagetable.new('Resources/Sprites/menu/readyGO')
local countdownImageTable 		= gfx.imagetable.new('Resources/Sprites/menu/countdown_v3')
local countdownDitherPattern 	= gfx.image.new('Resources/Sprites/menu/ditherPattern_Dashed')
local pauseBackground 		= GET_IMAGE(readyGo_imageTable, 1)
local readyImage 			= GET_IMAGE(readyGo_imageTable, 2)
local goImage 				= GET_IMAGE(readyGo_imageTable, 3)

local COUNTDOWN_TIMER_SET 	<const> = 1500
local GO_TIMER_SET 			<const> = 500
local COUNTDOWN_TOTAL 		<const> = 3
local COUNTDOWN_PHASES 		<const> = COUNTDOWN_TIMER_SET // COUNTDOWN_TOTAL
local COUNTDOWN_TRANSITION	<const> = COUNTDOWN_TOTAL + 1
local GO_SHAKE_DISTANCE 	<const> = 1200
local BAR_LENGTH 			<const> = 130
local BAR_HEIGHT 			<const> = 6

local goWidth, goHeight = pauseBackground:getSize()
local READYGO_WIDTH_HALF, READYGO_HEIGHT_HALF 		<const> = goWidth * 0.5, goHeight * 0.5

local pauseTimer = 0
local countdownTimer = 0
local readyGoPhase = 0

-- send the final elapsed pause time to all files that need it
local function sendPauseTimer(endTime)
	local finalTime = endTime - pauseTimer
	c_GetPauseTime_Player(finalTime)	-- player
	c_GetPauseTime_Camera(finalTime) 	-- camera
	c_GetPauseTime_Bullets(finalTime) 	-- bullets
	c_GetPauseTime_Enemies(finalTime) 	-- enemies
	c_GetPauseTime_Items(finalTime) 	-- items
	c_GetPauseTime_Objects(finalTime) 	-- objects
end

-- called from pd.gameWillResume in pauseMenu_v2.lua
function gameState_SwitchToPauseMenu()

	-- if coming from a menu state, then don't perform countdown timer.
	if currentState ~= GS_MAIN_GAME then
		return
	end

	-- else perform countdown timer
	if currentState ~= GS_PAUSE_MENU then
		lastState = currentState
	end
	pauseTimer = getMilliseconds()
	currentState = GS_PAUSE_MENU
	countdownTimer = pauseTimer + COUNTDOWN_TIMER_SET
	readyGoPhase = 1
end



-- +--------------------------------------------------------------+
-- |                         Transitions                          |
-- +--------------------------------------------------------------+

local performTransition = false
local transitionStart = false
local transitionEnd = false

local transition_PassedFunction = 0
local transition_nextState = currentState

local TRANSITION_TIME_PER_FRAME_SET <const> = 30
local transition_frameTimer = 0
local transition_index = 0
local transition_anim = 0
local transition_frames = 0
local transition_previousAnimType = 1

-- Transition Animations
local imgTable_transition_growingCircles 	= gfx.imagetable.new('Resources/Sheets/Transitions/Transition_GrowingCircles_v2')

local TRANSITION_ANIM = {
	imgTable_transition_growingCircles 		-- growing circles
}

local TRANSITION_TABLE_LENGTH = {
	GET_LENGTH(imgTable_transition_growingCircles) 	-- growing circles
}


-- fades screen TO black
-- The passedFunction needs to have 'runTransitionEnd' called by it.
function runTransitionStart(nextState, animType, passedFunction)

	-- If a transition was already started, then abort. We don't want to restart it.
	if performTransition then return end 

	performTransition = true
	transitionStart = true
	transitionEnd = false
	c_UpdateControls_SetInputLockForMainGameControls(true) -- lock player controls during animation - unlocked at end of TransitionEnd check.

	transition_nextState = nextState
	transition_PassedFunction = passedFunction

	transition_previousAnimType = animType
	transition_anim = TRANSITION_ANIM[animType]
	transition_frames = TRANSITION_TABLE_LENGTH[animType]

	transition_frameTimer = 0
	transition_index = 0
end

-- fades screen FROM black
function runTransitionEnd(animType)

	-- default animType to what TransitionStart used if nothing passed
	if not animType then animType = transition_previousAnimType end

	performTransition = true 
	transitionStart = false
	transitionEnd = true

	currentState = transition_nextState			
	transition_nextState = 0
	transition_PassedFunction = 0

	transition_anim = TRANSITION_ANIM[animType]
	transition_frames = TRANSITION_TABLE_LENGTH[animType]

	transition_frameTimer = 0
	transition_index = transition_frames
end



-- +--------------------------------------------------------------+
-- |                         Main Update                          |
-- +--------------------------------------------------------------+


gameScene_init()	-- Testing scene outside of main, will put back into scene loading later


-- NOTES:
	-- A long if-statement checking current gamestate is *slightly* faster than using a function table,
	-- but the gamestates that need to run as fast as possible NEED to be checked for first. All menus
	-- should be at the bottom of the check.
	-- *
	-- Using the 'Less Than' check (<) is faster than using the 'Equals' check (==).
	-- *
	-- Assigning the 'currentState' variable to a local and if-checking the local is slightly faster than 
	-- just if-checking 'currentState'.

function pd.update()

	-- Set up
	local time = getMilliseconds()
	local crank = floor(crankAngle())
	local checkState = currentState 	-- when switching states, use 'currentState', not 'checkState'.


	---- Main Game ----
	if checkState < 2 then
		
		-- Camera
		local screenOffsetX, screenOffsetY, cameraPosX, cameraPosY = c_UpdateCamera(time, crank, playerX, playerY)

		-- Draw World, Objects
		c_UpdateGameScene(screenOffsetX, screenOffsetY)
		--gameSceneDebugUpdate() --- visual debugging over game scene here ---
		c_UpdateObjects(time, playerX, playerY, screenOffsetX, screenOffsetY)

		-- Input, Player
		local inputX, inputY, inputButtonB = updateControls_MainGame()
		playerX, playerY = c_UpdatePlayer(time, inputX, inputY, inputButtonB, crank, shotsFired, itemsCollected)
		
		-- Bullets, Enemies, Items
		shotsFired = c_UpdateBullets(time, crank, playerX, playerY, screenOffsetX, screenOffsetY)
		c_UpdateEnemies(time, playerX, playerY, cameraPosX, cameraPosY, screenOffsetX, screenOffsetY)
		itemsCollected = c_UpdateItems(time, playerX, playerY, screenOffsetX, screenOffsetY)
		

		-- Particles, UI
		--updateParticles(dt, mainTimePassed, mainLoopTime, elapsedPauseTime)
		
		-- UI
		c_DrawPlayerUI()

	---- Pause Menu ----
	elseif checkState < 3 then 

		-- Redraw all components of Main Game screen so camera can rotate during countdown
		local screenOffsetX, screenOffsetY, cameraPosX, cameraPosY = c_UpdateCamera(time, crank, playerX, playerY)
		c_UpdateGameScene(screenOffsetX, screenOffsetY)
		playerX, playerY = c_RedrawPlayer(time, crank)
		c_RedrawBullets()
		c_RedrawEnemies(screenOffsetX, screenOffsetY)
		c_RedrawItems(screenOffsetX, screenOffsetY)
		c_RedrawObjects(screenOffsetX, screenOffsetY)
		-- draw particles
		c_DrawPlayerUI()

		-- 'Ready' phase
		if readyGoPhase < 2 then
			local timePassed = (countdownTimer - time)
			local index = COUNTDOWN_TOTAL - timePassed // COUNTDOWN_PHASES

			if index < COUNTDOWN_TRANSITION then
				local remainingX 	= cameraPosX + (BAR_LENGTH * 0.5) - 3	-- set on right side
				local remainingY 	= cameraPosY + BAR_HEIGHT + 13
				local passedX 		= cameraPosX - (BAR_LENGTH * 0.5) - 3	-- set on left side
				local passedY 		= cameraPosY + BAR_HEIGHT + 13
				local timePercent 	= timePassed / COUNTDOWN_TIMER_SET

				DRAW_IMAGE(pauseBackground, cameraPosX - READYGO_WIDTH_HALF + 8, cameraPosY - READYGO_HEIGHT_HALF)	-- background
				DRAW_IMAGE( GET_IMAGE(countdownImageTable, max(index, 1)), cameraPosX - 90, cameraPosY + 12)	-- countdown numbers
				DRAW_IMAGE(readyImage, cameraPosX - READYGO_WIDTH_HALF, cameraPosY - READYGO_HEIGHT_HALF)		-- ready image
				SET_COLOR(COLOR_WHITE)
				FILL_RECT(remainingX, remainingY, BAR_LENGTH * -timePercent, BAR_HEIGHT)						-- remaining time
				SET_DITHER_PATTERN(0.6, DITHER_DIAGONAL)
				FILL_RECT(passedX, passedY, BAR_LENGTH * (1 - timePercent), BAR_HEIGHT)							-- passed time

			else 
				readyGoPhase = 2 
				countdownTimer = getMilliseconds() + GO_TIMER_SET
			end

		-- 'GO' phase
		elseif readyGoPhase < 3 then 
			local timePercent = max((countdownTimer - time) / GO_TIMER_SET - 0.4, 0) -- offset by 0.4
			local centerX, centerY = cameraPosX - READYGO_WIDTH_HALF, cameraPosY - READYGO_HEIGHT_HALF
			local shakeX, shakeY = random() * 2 - 1, random() * 2 - 1 	-- -1 to 1
			local diffX, diffY =  shakeX - centerX, shakeY - centerY
			local mag = sqrt(diffX * diffX + diffY * diffY)
			local dist = GO_SHAKE_DISTANCE * timePercent
			shakeX, shakeY = shakeX / mag * dist, shakeY / mag * dist

			DRAW_IMAGE(pauseBackground, centerX + 8, centerY)				-- background
			DRAW_IMAGE(goImage, centerX + shakeX, centerY + shakeY)		-- go image

			if countdownTimer < time then readyGoPhase = 3 end

		-- Switch back to last state after countdown
		else
			currentState = lastState
			c_ResetInput()
			COLLECT_GARBAGE("collect") -- clean up 			
			sendPauseTimer(time)
		end

	---- Flower Minigame ----
	elseif checkState < 4 then 
		updateFlowerMinigame(time)
	
	---- New Weapon Menu ----
	elseif checkState < 5 then 
		updateNewWeaponMenu(time)

	---- Player Upgrade Menu ----
	elseif checkState < 6 then
		updatePlayerUpgradeMenu(time)

	---- Level Modifier Menu ----
	elseif checkState < 7 then
		updateLevelModifierMenu(time)

	---- Death Screen ----
	elseif checkState < 8 then

	---- Start Screen ----
	elseif checkState < 9 then

	---- Main Menu ----
	elseif checkState < 10 then

	end


	-- Transition Overlay
	if performTransition then 
	
		if transitionStart then 
			-- Increment frame
			if transition_frameTimer < time then 
				transition_frameTimer = time + TRANSITION_TIME_PER_FRAME_SET
				transition_index = transition_index + 1 
			end

			-- Check end condition
			if transition_index > transition_frames then 
				performTransition = false
				transitionStart = false						
				SET_COLOR(COLOR_BLACK)
				local xOffset, yOffset = GET_DRAW_OFFSET()
				FILL_RECT(-xOffset, -yOffset, 400, 240) -- This covers the last frame of the transition.	
				transition_PassedFunction() -- at then end of the transition, perform the function that was passed.

			-- Else draw frame
			else
				DRAW_IMAGE_STATIC( GET_IMAGE(transition_anim, transition_index), 0, 0)
				--doTransition_GrowingCircles(timePercent) -- functions for creating animations - comment out after the imageTable is created.
			end

		elseif transitionEnd then 
			-- Decrement frame
			if transition_frameTimer < time then 
				transition_frameTimer = time + TRANSITION_TIME_PER_FRAME_SET
				transition_index = transition_index - 1 
			end

			-- Check end condition
			if transition_index < 1 then 
				performTransition = false 
				transitionEnd = false
				c_UpdateControls_SetInputLockForMainGameControls(false) -- unlock player controls

			-- Else draw frame, flipped on both X and Y.
			else
				DRAW_IMAGE_STATIC( GET_IMAGE(transition_anim, transition_index), 0, 0, FLIP_XY)
			end
		end

	end


	--printAndClearTotalTime("GS loop in main")
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