

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
local min 		<const> = math.min
local sqrt 		<const> = math.sqrt
local abs 		<const> = math.abs
local MOVE_TOWARDS <const> = moveTowards_global
local rescale 	<const> = rescaleRange_global

-- screen
local setDrawOffset 	<const> = gfx.setDrawOffset
local setDspOffset 		<const> = dsp.setOffset
local setInverted 		<const> = dsp.setInverted

local screenWidth 		<const> = dsp.getWidth()
local screenHeight 		<const> = dsp.getHeight()
local halfScreenHeight 	<const> = screenHeight / 2
local halfScreenWidth 	<const> = screenWidth / 2
local halfBannerHeight 	<const> = getBannerHeight() // 2



-- +--------------------------------------------------------------+
-- |                            Init                              |
-- +--------------------------------------------------------------+

local CAMERA_SPEED_MAX 	<const> = 6
local CAM_DISTANCE_X 	<const> = 100
local CAM_DISTANCE_Y 	<const> = 40

-- camera shake
local SPRING_CONSTANT 	<const> = 0.5
local SPRING_DAMPEN 	<const> = 0.7
local SET_SHAKE_TIMER 	<const> = 2000
local shakeTimer = 0

-- camera position and shake storage
local cameraPosX, cameraPosY 			= 0, 0
local camAnchorX, camAnchorY 			= 0, 0
local camBobX, camBobY 					= 0, 0
local shakeVelocityX, shakeVelocityY 	= 0, 0

-- screen flash
local SET_FLASH_TIMER	<const> = 100
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
	flashTimer = currentTime + SET_FLASH_TIMER
end


function clearFlash()
	setInverted(false)
	screenFlashState = false
end


-- +--------------------------------------------------------------+
-- |                           Position                           |
-- +--------------------------------------------------------------+


local function moveCamera(angle, posX, posY)
	local rad = rad(angle - 90)
	local targetPosX = CAM_DISTANCE_X * cos(rad) + posX
	local targetPosY = CAM_DISTANCE_Y * sin(rad) + posY - halfBannerHeight

	-- Adjusting camera speed based on separate axis to move cleanly to the target point - no more separate horizontal/vertical movement.
		-- Needed b/c horizontal movement is greater than vertical movement in most cases, which gives weird 'sliding' effect
	local distX, distY = targetPosX - cameraPosX, targetPosY - cameraPosY
	local magnitude = sqrt(distX * distX + distY * distY)
	local speedScale = min(magnitude / 5, CAMERA_SPEED_MAX) -- smooths movement based on distance to target
	local scaledMag = speedScale / max(magnitude, 1) -- setting mag to min 1 avoids any chance for div by 0
	local speedX = abs(distX) * scaledMag 
	local speedY = abs(distY) * scaledMag

	cameraPosX = MOVE_TOWARDS(cameraPosX, targetPosX, speedX)
	cameraPosY = MOVE_TOWARDS(cameraPosY, targetPosY, speedY)

	-- Need to floor to avoid camera jitter - happens at non-integer values
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
	local timer = SET_SHAKE_TIMER - (shakeTimer - time)
	timer = max(1 - timer / SET_SHAKE_TIMER, 0)

	if timer == 0 then 
		shakeVelocityX = 0
		shakeVelocityY = 0
	else 
		local forceX = (camBobX - camAnchorX) * SPRING_CONSTANT * -timer
		local forceY = (camBobY - camAnchorY) * SPRING_CONSTANT * -timer

		shakeVelocityX = (shakeVelocityX + forceX) * SPRING_DAMPEN
		shakeVelocityY = (shakeVelocityY + forceY) * SPRING_DAMPEN

		camBobX = camBobX + shakeVelocityX
		camBobY = camBobY + shakeVelocityY
	end

	-- Set the display offset
	setDspOffset(shakeVelocityX, shakeVelocityY)
end



-- global function to snap the camera to its target position instead of trying to move there
local crankAngle <const> = pd.getCrankPosition
function snapCamera(playerX, playerY)
	local rad = rad(floor(crankAngle()) - 90)
	cameraPosX = CAM_DISTANCE_X * cos(rad) + playerX
	cameraPosY = CAM_DISTANCE_Y * sin(rad) + playerY - halfBannerHeight

	camAnchorX = floor(halfScreenWidth - cameraPosX)
	camAnchorY = floor(halfScreenHeight - cameraPosY)

	setDrawOffset(camAnchorX, camAnchorY)
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

	shakeTimer = currentTime + SET_SHAKE_TIMER
end


-- To be called at the end of the pause animation.
function getPauseTime_Camera(pauseTime)
	shakeTimer = shakeTimer + pauseTime
	flashTimer = flashTimer + pauseTime
	currentTime = currentTime + pauseTime
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


function updateCamera(time, crank, playerX, playerY)
	currentTime = time

	moveCamera(crank, playerX, playerY)
	shakeCameraUpdate(time)
	manageScreenFlash()

	return 	camAnchorX, camAnchorY, 	-- screen offset
			cameraPosX, cameraPosY		-- camera position
end