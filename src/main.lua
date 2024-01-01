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

local gfx <const> = playdate.graphics

gfx.setColor(gfx.kColorWhite)
gfx.fillRect(0, 0, 400, 240)
gfx.setBackgroundColor(gfx.kColorBlack)

elapsedTime = 0

gameScene()

function playdate.update()
	dt = 1/20
	elapsedTime = elapsedTime + dt
	
	updatePlayer(dt)
	gfx.sprite.update()
	updateCamera(dt)
end


-- TO DO:
	-- bullets are slow
	-- character gun is too offset from bullet spawn point - might adjust spawn point
		-- remake sprite to make aiming feel better - less bulky
	-- level layout too dense to start - should open up 
	-- pick up radius for ground objects
	-- equipped items ui
	-- enemy cap / object cap
	-- death screen
	-- game start screen
	-- level select screen