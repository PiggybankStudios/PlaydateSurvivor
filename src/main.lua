import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/math"

import "LDtk"

import "tags"
import "bullet"
import "healthbar"
import "enemy"
import "player"
import "camera"
import "gameScene"
import "item"

local gfx <const> = playdate.graphics

gfx.setColor(gfx.kColorWhite)
gfx.fillRect(0, 0, 400, 240)
gfx.setBackgroundColor(gfx.kColorWhite)

elapsedTime = 0

gameScene()

function playdate.update()
	dt = 1/20
	elapsedTime = elapsedTime + dt
	
	updatePlayer(dt)
	
	
	gfx.sprite.update()

	updateCamera(dt)
end