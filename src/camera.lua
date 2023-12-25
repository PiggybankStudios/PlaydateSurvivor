import "tweening"

local gfx <const> = playdate.graphics
local mathFloor <const> = math.floor

-- screen size
local screenHeight <const> = playdate.display.getHeight()
local screenWidth <const> = playdate.display.getWidth()
halfScreenHeight = screenHeight / 2
halfScreenWidth = screenWidth / 2

-- this is the target position the camera is trying to get to
local cameraPos = {}
cameraPos["x"] = 0
cameraPos["y"] = 0

-- this keeps the camera's current position - only set by the camera
local currentCameraPos = {}
currentCameraPos["x"] = 0
currentCameraPos["y"] = 0

-- camera shake
shakeStrength = {
	tiny = 1,
	small = 2, 
	medium = 3,
	large = 4,
	massive = 5
}


local speed = 6
local camDistance = {}
camDistance.x = 100
camDistance.y = 40




-- +--------------------------------------------------------------+
-- |                           Position                           |
-- +--------------------------------------------------------------+


function setCameraPos(angle, posX, posY)
	rad = math.rad(angle)
	cameraPos.x = camDistance.x * math.cos(rad) + posX
	cameraPos.y = camDistance.y * math.sin(rad) + posY	
end


-- Seems like this is still getting camera jittering :( need to test on hardware
local function moveCamera(dt)
	currentCameraPos.x = moveTowards(currentCameraPos.x, cameraPos.x, speed)
	currentCameraPos.y = moveTowards(currentCameraPos.y, cameraPos.y, speed)

	local offsetX = mathFloor(halfScreenWidth - currentCameraPos.x)
	local offsetY = mathFloor(halfScreenHeight - currentCameraPos.y)

	gfx.setDrawOffset(offsetX, offsetY)
end


function cameraShake()

end

-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updateCamera(dt)

	setCameraPos(crankAngle, player.x, player.y)
	moveCamera(dt)

	-- Debugging
		-- this space draws primitives to the whole screen's background
		-- need to comment this out when not using, bc it draws to the whole screen every frame
	--[[
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
    ]]--

end
