import "player"
import "tweening"

-- define lookup functions
	-- Could help squeeze out performance if really needed, saving here for future reference
local gfx <const> = playdate.graphics
local mathFloor <const> = math.floor


local screenHeight = playdate.display.getHeight()
local screenWidth = playdate.display.getWidth()
local halfScreenHeight = screenHeight / 2
local halfScreenWidth = screenWidth / 2

-- this is the target position the camera is trying to get to
local cameraPos = {}
cameraPos["x"] = 0
cameraPos["y"] = 0

-- this keeps the camera's current position - only set by the camera
local currentCameraPos = {}
currentCameraPos["x"] = 0
currentCameraPos["y"] = 0

local speed = 4
local distance = 60


-- Debugging
playerX = 0
playerY = 0


-- +--------------------------------------------------------------+
-- |                           Position                           |
-- +--------------------------------------------------------------+


function setCameraPos(angle, posX, posY)
	rad = math.rad(angle)
	cameraPos.x = distance * math.cos(rad) + posX
	cameraPos.y = distance * math.sin(rad) + posY	
	
	-- For debugging
	playerX = posX
	playerY = posY
end


-- Seems like this is getting camera jittering, but this should be tweaked after we get some static sprites on the screen
local function moveCamera()
	currentCameraPos.x = mathFloor( moveTowards(currentCameraPos.x, cameraPos.x, speed) ) -- attempting to stop camera jitter, but need to set background tiles before that can be properly tested
	currentCameraPos.y = mathFloor( moveTowards(currentCameraPos.y, cameraPos.y, speed) )

	gfx.setDrawOffset(halfScreenWidth - currentCameraPos.x, halfScreenHeight - currentCameraPos.y)
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updateCamera(dt)

	setCameraPos(crankAngle, player.x, player.y)
	moveCamera()

	-- Debugging
		-- this space draws primitives to the whole screen's background
	local offsetX, offsetY = gfx.getDrawOffset()
	gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
        	gfx.clear()	-- clears any drawn shape from the previous frame
            gfx.setClipRect( x, y, width, height )
            gfx.setColor(gfx.kColorBlack)
            gfx.setImageDrawMode(gfx.kDrawModeNXOR)
            gfx.drawLine(playerX + offsetX, playerY + offsetY, cameraPos.x + offsetX, cameraPos.y + offsetY) -- added w/ draw offset to be accurate to player position
            gfx.clearClipRect()
        end
    )

end
