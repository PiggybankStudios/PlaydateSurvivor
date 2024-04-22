

-- +--------------------------------------------------------------+
-- |                          Constants                           |
-- +--------------------------------------------------------------+

-- extensions
local pd 	<const> = playdate
local gfx 	<const> = pd.graphics
local dsp 	<const> = pd.display

-- math
local floor 	<const> = math.floor
local rad 		<const> = math.rad
local sin 		<const> = math.sin
local cos 		<const> = math.cos
local random 	<const> = math.random
local max 		<const>	= math.max
local sqrt 		<const> = math.sqrt
local MOVE_TOWARDS <const> = moveTowards

-- screen
local setDrawOffset 	<const> = gfx.setDrawOffset
local setDspOffset 		<const> = dsp.setOffset
local setInverted 		<const> = dsp.setInverted

local screenWidth 		<const> = dsp.getWidth()
local screenHeight 		<const> = dsp.getHeight()
local halfScreenHeight 	<const> = screenHeight / 2
local halfScreenWidth 	<const> = screenWidth / 2
local halfBannerHeight 	<const> = getHalfUIBannerHeight()



-- +--------------------------------------------------------------+
-- |                            Init                              |
-- +--------------------------------------------------------------+

local SPEED 			<const> = 6
local CAM_DISTANCE_X 	<const> = 100
local CAM_DISTANCE_Y 	<const> = 40

-- camera shake
local minCamDifference 	<const> = 0.02
local springConstant 	<const> = 0.5
local springDampen 		<const> = 0.85
local setShakeTimer 	<const> = 2000
local shakeTimer = 0

-- camera position and shake storage
local cameraPosX, cameraPosY 			= 0, 0
local camAnchorX, camAnchorY 			= 0, 0
local camBobX, camBobY 					= 0, 0
local shakeVelocityX, shakeVelocityY 	= 0, 0

-- screen flash
local setFlashTimer <const> = 100
local screenFlashState = false
local flashTimer = 0

-- time
local currentTime = 0


-- +--------------------------------------------------------------+
-- |                         Screen Flash                         |
-- +--------------------------------------------------------------+


local function manageScreenFlash()
	if screenFlashState == true and flashTimer < currentTime then
		setInverted(false)
		screenFlashState = false
	end
end


function screenFlash()
	setInverted(true)
	screenFlashState = true
	flashTimer = currentTime + setFlashTimer
end


function clearFlash()
	setInverted(false)
	screenFlashState = false
end


-- +--------------------------------------------------------------+
-- |                           Position                           |
-- +--------------------------------------------------------------+


local function moveCamera(angle, posX, posY)
	local rad = rad(angle)
	local targetPosX = CAM_DISTANCE_X * cos(rad) + posX
	local targetPosY = CAM_DISTANCE_Y * sin(rad) + posY - halfBannerHeight

	cameraPosX = MOVE_TOWARDS(cameraPosX, targetPosX, SPEED)
	cameraPosY = MOVE_TOWARDS(cameraPosY, targetPosY, SPEED)

	camAnchorX = floor(halfScreenWidth - cameraPosX)
	camAnchorY = floor(halfScreenHeight - cameraPosY)

	setDrawOffset(camAnchorX, camAnchorY)
end


local function shakeCameraUpdate(time)

	-- If the shake velocity is 0, then don't do anything
	if shakeVelocityX + shakeVelocityY == 0 then
		return
	end

	-- Calculate spring force
	local timer = setShakeTimer - (shakeTimer - time)
	timer = max(1 - timer / setShakeTimer, 0)

	if timer == 0 then 
		shakeVelocityX = 0
		shakeVelocityY = 0
	else 
		local forceX = (camBobX - camAnchorX) * springConstant * -timer
		local forceY = (camBobY - camAnchorY) * springConstant * -timer

		shakeVelocityX = (shakeVelocityX + forceX) * springDampen
		shakeVelocityY = (shakeVelocityY + forceY) * springDampen

		camBobX = camBobX + shakeVelocityX
		camBobY = camBobY + shakeVelocityY
	end

	-- Set the display offset
	setDspOffset(shakeVelocityX, shakeVelocityY)
end



-- global function to snap the camera to its target position instead of trying to move there
local crankAngle <const> = getCrankAngle
function snapCamera(playerX, playerY)
	cameraPosX = playerX
	cameraPosY = playerY
	moveCamera(floor(crankAngle()), playerX, playerY)
end


-- Pass positions for shake direction - global function called to actually shake the camera
function cameraShake(strength, dirX, dirY)
	if dirX == nil or dirY == nil then
		local randX = random() * 2 - 1
		local randY = random() * 2 - 1
		local mag = randX * randX + randY * randY
		dirX = randX / mag
		dirY = randY / mag
	end

	shakeVelocityX = dirX * strength
	shakeVelocityY = dirY * strength
	camBobX = camAnchorX + shakeVelocityX
	camBobY = camAnchorY + shakeVelocityY

	shakeTimer = currentTime + setShakeTimer
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


function updateCamera(dt, time, crank, playerX, playerY)
	currentTime = time

	moveCamera(crank, playerX, playerY)
	shakeCameraUpdate(time)
	manageScreenFlash()
 		
	return 	camAnchorX, camAnchorY, 	-- screen offset
			cameraPosX, cameraPosY		-- camera position
end