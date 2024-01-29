import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/math"

import "LDtk"

import "savefile"
import "tags"
import "bullet"
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
import "item"
import "startmenu"
import "mainmenu"
import "deathmenu"
import "levelupmenu"
import "weaponmenu"
import "bulletGraphic"

local gfx <const> = playdate.graphics

local reset = false
local recycleValue = 0
local currentFrame = 0

gfx.setColor(gfx.kColorWhite)
gfx.fillRect(0, 0, 400, 240)
gfx.setBackgroundColor(gfx.kColorBlack)

elapsedTime = 0
currentState = GAMESTATE.startscreen
lastState = GAMESTATE.nothing


-- +--------------------------------------------------------------+
-- |                         Main Update                          |
-- +--------------------------------------------------------------+

function recycleGun(value)
	recycleValue = value
end


function playdate.update()
	dt = 1/20
	elapsedTime = elapsedTime + dt
	currentFrame = (currentFrame + 1) % 60

	-- Start Screen
	if currentState == GAMESTATE.startscreen then
		if lastState == GAMESTATE.deathscreen then
			closeDeadMenu()
			openStartMenu()
			lastState = currentState
		elseif lastState ~= currentState then
			openStartMenu()
			lastState = currentState
		else
			updateStartManu()
		end
		
	-- Main Menu
	elseif currentState == GAMESTATE.mainmenu then
		if lastState ~= currentState then
			writeSaveFile()
			closeStartMenu()
			openMainMenu()
			lastState = currentState
			readSaveFile()
		else
			updateMainManu()
		end

	-- Main Game
	elseif currentState == GAMESTATE.maingame then
		if lastState == GAMESTATE.mainmenu then
			closeMainMenu()
			gameScene()
			lastState = currentState
		elseif reset == true then
			gameScene()
			lastState = currentState
			reset = false
		elseif lastState ~= currentState then
			lastState = currentState
			if recycleValue ~= 0 then
				addEXP(recycleValue)
				recycleValue = 0
			end
		end
		updatePlayer(dt)
		updateCamera(dt)
		updateEnemies(dt, currentFrame)

	-- Pause Menu
	elseif currentState == GAMESTATE.pausemenu then
		if lastState ~= currentState then
			lastState = currentState
		end
		updatePauseManu()
		updateCamera(dt)

	-- Level Up Menu
	elseif currentState == GAMESTATE.levelupmenu then
		if lastState ~= currentState then
			lastState = currentState
		end
		updateLevelUpManu()
		updateCamera(dt)

	-- Level Up Menu
	elseif currentState == GAMESTATE.newweaponmenu then
		if lastState ~= currentState then
			lastState = currentState
		end
		updateWeaponMenu()
		updateCamera(dt)

	-- Death Screen
	elseif currentState == GAMESTATE.deathscreen then
		if lastState ~= currentState then
			openDeadMenu()
			lastState = currentState
		else
			updateDeadManu()
		end
	end

	gfx.sprite.update()
end


-- +--------------------------------------------------------------+
-- |                     Game State Functions                     |
-- +--------------------------------------------------------------+


function resetGame()
	print("empty")
end


function getGameState()
	return currentState
end


function setGameState(newState)
	currentState = newState
end


function restartGame()
	reset = true
end

