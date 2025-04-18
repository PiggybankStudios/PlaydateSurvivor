import "CoreLibs/graphics"
import "CoreLibs/math"
import "CoreLibs/ui"
import "CoreLibs/easing"


import "globals"
import "tags"

bump = import "bump"
import "LDtk"

import "fonts"
import "savefile"

--import "healthbar" -- edit player healthbar so we can get rid of this
--import "uibanner"	 -- re-writing banner code as 'actionBannerUI.lua'
--import "expbar" 	 -- this is also getting incorporated into the action banner

import "actionBannerUI"
import "player"
import "camera"
import "mun"
import "item_v2"
import "enemy_v2"
import "bullet_v2"
import "particle"
import "objects"

--import "write"
--import "writefunctions"

import "flowerMiniGame_PuzzleSettings"
import "gameScene_v2"

import "selectionBubble" -- multiple menus use the selection bubble for navigation
import "flowerMiniGame_CountdownTimer"
import "flowerMiniGame_ComboScore"
import "flowerMiniGame_WhiteOut"
import "flowerMiniGame_ValidWordList"
import "flowerMiniGame"

import "newWeaponMenu"
import "playerUpgradeMenu"
import "levelModifierMenu"
import "startmenu"
import "mainmenu_v2"
--import "mainmenu"
import "deathmenu"
import "levelupmenu"
import "weaponmenu"
import "pausemenu_v2"

--- TEMPORARY - remove from final builds ---
import "transitions"
--import "transitionAnimations" 	-- code from transition animations, used in export process for transition image tables


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
local crankAngle 			<const> = pd.getCrankPosition

-- Main Game
local c_UpdateGameScene 			<const> = updateGameScene
local c_UpdatePlayer 				<const> = updatePlayer
local c_UpdateCamera 				<const> = updateCamera
local c_UpdateBullets 				<const> = updateBullets
local c_UpdateEnemies				<const> = updateEnemies
local c_UpdateItems 				<const> = updateItems
local c_UpdateObjects				<const> = updateObjects
local c_DrawPlayerUI 				<const> = drawPlayerUI
local c_UpdateActionBanner 			<const> = updateActionBanner

-- Pause Menu
local c_GetPauseTime_Player 		<const> = getPauseTime_Player
local c_GetPauseTime_Camera 		<const> = getPauseTime_Camera
local c_GetPauseTime_Bullets 		<const> = getPauseTime_Bullets
local c_GetPauseTime_Enemies 		<const> = getPauseTime_Enemies
local c_GetPauseTime_Items	 		<const> = getPauseTime_Items
local c_GetPauseTime_Objects 		<const> = getPauseTime_Objects
local c_getPauseTime_ActionBanner 	<const> = getPauseTime_ActionBanner

local c_RedrawPlayer 				<const> = redrawPlayer
local c_RedrawBullets 				<const> = redrawBullets
local c_RedrawEnemies 				<const> = redrawEnemies
local c_RedrawItems 				<const> = redrawItems
local c_RedrawObjects				<const> = redrawObjects

-- Other State Updates
local c_UpdateFlowerMinigame 		<const> = updateFlowerMinigame
local c_UpdateNewWeaponMenu			<const> = updateNewWeaponMenu 
local c_UpdatePlayerUpgradeMenu		<const> = updatePlayerUpgradeMenu
local c_UpdateLevelModifierMenu		<const> = updateLevelModifierMenu

-- death screen
local c_UpdateStartScreen			<const> = updateStartScreen
local c_UpdateMainMenu				<const> = updateMainMenu

-- Transitions
local c_Player_LockInput 			<const> = player_LockInput
local c_UpdateTransitions 			<const> = updateTransitions


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
local GS_LOAD_GAME 					<const> = GAMESTATE.loadGame


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
local currentState = GS_LOAD_GAME --GS_FLOWER_MINIGAME --GS_STARTSCREEN
local lastState = currentState


-----------------
--- Main Game ---
local playerX, playerY = 0, 0 -- need this for camera updates, before player pos is updated


-- +--------------------------------------------------------------+
-- |                           Pausing                            |
-- +--------------------------------------------------------------+

local readyGo_imageTable 		= gfx.imagetable.new('Resources/Sprites/menu/PauseMenu/readyGO')
local countdownImageTable 		= gfx.imagetable.new('Resources/Sprites/menu/PauseMenu/countdown_v3')
--local countdownDitherPattern 	= gfx.image.new('Resources/Sprites/menu/ditherPattern_Dashed')
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

local skip_countdown = false

local savedTimeAtPause = 0


-- send the final elapsed pause time to all files that need it
local function sendPauseTimer(endTime)
	local finalTime = endTime - pauseTimer
	c_GetPauseTime_Player(finalTime)		-- player
	c_GetPauseTime_Camera(finalTime) 		-- camera
	c_GetPauseTime_Bullets(finalTime) 		-- bullets
	c_GetPauseTime_Enemies(finalTime) 		-- enemies
	c_GetPauseTime_Items(finalTime) 		-- items
	c_GetPauseTime_Objects(finalTime) 		-- objects
	c_getPauseTime_ActionBanner(finalTime)	-- action banner
end


-- switching from Pause Menu back to previous menu 
-- called from pd.gameWillResume in pauseMenu_v2.lua
function gameState_SwitchToPauseMenu()

	-- if coming from a menu state, then don't perform countdown timer.
	if currentState ~= GS_MAIN_GAME and currentState ~= GS_PAUSE_MENU then
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


-- cancels the countdown timer after pausing for the main game
function gameState_CancelCountdownTimer()
	readyGoPhase = 4
end


-- saves the time at moment of pause to stop animations
function gameState_SaveTimeAtPause()
	savedTimeAtPause = getMilliseconds()
end


-- +--------------------------------------------------------------+
-- |                         Initial Load                         |
-- +--------------------------------------------------------------+

-- coroutine list
	-- 1. Filled on transitionStart
	-- 2. Runs through coroutines one-at-a-time - in transitions - with yeilds until all coroutines are dead
	-- 3. List cleared on transitionEnd
local coroutineList = {
	coroutine.create(player_initialize_data),
	coroutine.create(bullet_v2_initialize_data),
	coroutine.create(enemy_v2_initialize_data),
	coroutine.create(item_v2_initialize_data),
	coroutine.create(objects_initialize_data),
	coroutine.create(transitions_initialize_data),
	coroutine.create(gameScene_v2_initialize_world),
	coroutine.create(flowerMiniGame_initialize_dictionary)
}
local COROUTINE_LIST_LENGTH 	<const> = #coroutineList
local coroutineTracker = 1
local currentTask, totalTasks = 1, 1
local taskDescription = ""


-- +--------------------------------------------------------------+
-- |                         Main Update                          |
-- +--------------------------------------------------------------+


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
		
		--- Action game loop performed here, instead of its own file, to help keep things fast. Reduces function calls this way. ---

		-- Camera
		local screenOffsetX, screenOffsetY = c_UpdateCamera(time, crank, playerX, playerY)

		-- Draw World, Objects
		c_UpdateGameScene(screenOffsetX, screenOffsetY)
		--gameSceneDebugUpdate() --- visual debugging over game scene here ---
		c_UpdateObjects(time, playerX, playerY, screenOffsetX, screenOffsetY)
		
		-- Player, Bullets, Enemies, Items
		playerX, playerY = c_UpdatePlayer(time, crank)
		c_UpdateBullets(time, crank, playerX, playerY, screenOffsetX, screenOffsetY)
		c_UpdateEnemies(time, playerX, playerY, screenOffsetX, screenOffsetY)
		c_UpdateItems(time, playerX, playerY, screenOffsetX, screenOffsetY)
		

		-- Particles, UI
		--updateParticles(dt, mainTimePassed, mainLoopTime, elapsedPauseTime)
		
		-- UI
		c_DrawPlayerUI()
		c_UpdateActionBanner(time)


	---- Pause Menu ----
	elseif checkState < 3 then 

		-- Redraw all components of Main Game screen so camera can rotate during countdown
		local screenOffsetX, screenOffsetY, cameraPosX, cameraPosY = c_UpdateCamera(time, crank, playerX, playerY)
		c_UpdateGameScene(screenOffsetX, screenOffsetY)
		c_RedrawObjects(screenOffsetX, screenOffsetY)
		playerX, playerY = c_RedrawPlayer(time, crank)
		c_RedrawBullets()
		c_RedrawEnemies(screenOffsetX, screenOffsetY)
		c_RedrawItems(screenOffsetX, screenOffsetY)		
		-- draw particles
		c_DrawPlayerUI()
		c_UpdateActionBanner(savedTimeAtPause)

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
			--COLLECT_GARBAGE("collect") -- clean up 			
			sendPauseTimer(time)
		end

	---- Flower Minigame ----
	elseif checkState < 4 then 
		c_UpdateFlowerMinigame(time)
	
	---- New Weapon Menu ----
	elseif checkState < 5 then 
		c_UpdateNewWeaponMenu(time)

	---- Player Upgrade Menu ----
	elseif checkState < 6 then
		c_UpdatePlayerUpgradeMenu(time)

	---- Level Modifier Menu ----
	elseif checkState < 7 then
		c_UpdateLevelModifierMenu(time)

	---- Death Screen ----
	elseif checkState < 8 then
		-- EMPTY --

	---- Start Screen ----
	elseif checkState < 9 then
		c_UpdateStartScreen(time)

	---- Main Menu ----
	elseif checkState < 10 then
		c_UpdateMainMenu(time)

	---- Initial Load at Start of Game ----
	elseif checkState < 11 then

		--print("inside 'loadGame' state - performCoroutines: " .. tostring(coroutineTracker <= COROUTINE_LIST_LENGTH))
		
		if coroutineTracker <= COROUTINE_LIST_LENGTH then

			-- Perform all coroutines from list IN ORDER, starting the next once the previous is dead.
			local _, passedCurrentTask, passedTotalTasks, description = coroutine.resume(coroutineList[coroutineTracker])

			-- If this coroutine is finished, begin the next one.
			if coroutine.status(coroutineList[coroutineTracker]) == 'dead' then
				coroutineTracker += 1
			
			else
				currentTask = passedCurrentTask == nil and currentTask or passedCurrentTask
				totalTasks = passedTotalTasks == nil and totalTasks or passedTotalTasks
				taskDescription = description == nil and taskDescription or description

				print("performing coroutines - loading: " .. coroutineTracker .. "/" .. COROUTINE_LIST_LENGTH .. 
						" - subTasks: " .. currentTask .. "/" .. totalTasks)

				
				-- draw a 'loading' animation
				gfx.setColor(gfx.kColorBlack)
				gfx.fillRect(0, 0, 400, 240)
				gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				gfx.drawText(taskDescription, 100, 130)
				gfx.setImageDrawMode(gfx.kDrawModeCopy)

				gfx.setColor(gfx.kColorWhite)
				local totalWidth = 200

				local taskPercentage = currentTask / totalTasks
				local taskWidth = totalWidth // COROUTINE_LIST_LENGTH * taskPercentage

				local completedTaskWidth = ((coroutineTracker-1) / COROUTINE_LIST_LENGTH) * totalWidth
				local width = completedTaskWidth + taskWidth
				gfx.fillRect(100, 100, width, 20)
				--print("width: " .. width .. " - completedTaskWidth: " .. completedTaskWidth .. " - taskWidth: " .. taskWidth ..
				--		" - completedTasks: " .. coroutineTracker .. " - all Tasks: " .. COROUTINE_LIST_LENGTH)
			end
			
			-- DEBUGGING after initial load, perform single actions here
			--[[
			if coroutineTracker > COROUTINE_LIST_LENGTH then 
				print_dictionary()
			end
			]]

		-- once all the loading is done, change the game state.
		else
			--print("stopping coroutine loop")
			--runTransitionStart( GAMESTATE.startscreen, TRANSITION_TYPE.growingCircles, startMenu_StateStart )
			--runTransitionStart( GAMESTATE.flowerMinigame, TRANSITION_TYPE.growingCircles, flowerMiniGame_StateStart ) -- DEBUGGING
			runTransitionStart( GAMESTATE.maingame, TRANSITION_TYPE.growingCircles, gameScene_startFirstLevel, mainMenu_ClearState ) -- DEBUGGING - loads into action portion
		end

	end

	-- Transition Overlay
	c_UpdateTransitions(time)

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

--function main_UpdateShotsFired(newShotsCount)
--	shotsFired += newShotsCount
--end