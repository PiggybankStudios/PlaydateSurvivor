import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/math"

import "LDtk"

import "tags"
import "bullet"
import "particle"
import "healthbar"
import "uibanner"
import "pausemenu"
import "write"
import "expbar"
import "enemy"
import "player"
import "camera"
import "gameScene"
import "item"
import "mainmenu"
import "deathmenu"

local gfx <const> = playdate.graphics

local reset = false

gfx.setColor(gfx.kColorWhite)
gfx.fillRect(0, 0, 400, 240)
gfx.setBackgroundColor(gfx.kColorBlack)

elapsedTime = 0
currentState = GAMESTATE.startscreen
lastState = GAMESTATE.nothing

function playdate.update()
	dt = 1/20
	elapsedTime = elapsedTime + dt
	if currentState == GAMESTATE.startscreen then
		if lastState == GAMESTATE.deathscreen then
			closeDeadMenu()
			openMainMenu()
			lastState = currentState
		elseif lastState ~= currentState then
			openMainMenu()
			lastState = currentState
		else
			updateMainManu()
		end
	elseif currentState == GAMESTATE.maingame then
		if lastState == GAMESTATE.startscreen then
			gameScene()
			closeMainMenu()
			lastState = currentState
		elseif reset == true then
			gameScene()
			lastState = currentState
			reset = false
		elseif lastState ~= currentState then
			lastState = currentState
		end
		updatePlayer(dt)
		updateCamera(dt)
	elseif currentState == GAMESTATE.pausemenu then
		if lastState ~= currentState then
			lastState = currentState
		end
		updateCamera(dt)
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

-- TO DO:
	-- bullets are slow
	-- character gun is too offset from bullet spawn point - might adjust spawn point
		-- remake sprite to make aiming feel better - less bulky
	-- equipped items ui
	-- enemy cap / object cap
	-- level select screen


-- To Make:
	-- one more gun: laser
	-- enemy that shoots
	-- choose level ups
	-- SHOW the timer for end of the round - it's already made
	-- end of timer death: reaper? kill the reaper with right setup? game state after reaper? vampires?

-- My next project:
	-- enemy management
	-- bullet management
	-- calc stuff in frame chunks