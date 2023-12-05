import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"

import "player"

gfx = playdate.graphics

gfx.setColor(gfx.kColorWhite)
gfx.fillRect(0, 0, 400, 240)
gfx.setBackgroundColor(gfx.kColorWhite)

elapsedTime = 0

function playdate.update()
	dt = 1/20
	elapsedTime = elapsedTime + dt
	
	updatePlayer(dt)
	
	gfx.sprite.update()
end
