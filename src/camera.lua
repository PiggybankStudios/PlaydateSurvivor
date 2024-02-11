import "tweening"

local gfx <const> = playdate.graphics
local dsp <const> = playdate.display
local vec <const> = playdate.geometry.vector2D
local mathp <const> = playdate.math
local mathFloor <const> = math.floor

local currentTime

-- screen size
local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenHeight <const> = screenHeight / 2
local halfScreenWidth <const> = screenWidth / 2

-- this is the target position the camera is trying to get to
local cameraPos = {}
cameraPos["x"] = 0
cameraPos["y"] = 0

-- this keeps the camera's current position - only set by the camera
local currentCameraPos = {}
currentCameraPos["x"] = 0
currentCameraPos["y"] = 0
local speed = 6
local camDistance = {}
camDistance.x = 100
camDistance.y = 40

-- camera shake
local camAnchor = vec.new(0, 0)
local camBob = vec.new(0, 0)
local shakeVelocity = vec.new(0, 0)
local minCamDifference <const> = 0.02
local springConstant <const> = 0.5
local springDampen <const> = 0.85
local shakeEndDelta = 0.1
local setShakeTimer = 2000
local shakeTimer = 0

-- screen flash
local setFlashTimer = 100
local flashTimer


-- +--------------------------------------------------------------+
-- |                         Screen Flash                         |
-- +--------------------------------------------------------------+


function screenFlash()
	dsp.setInverted(true)
	flashTimer = currentTime + setFlashTimer
	--print("flash")
end


local function manageScreenFlash()
	if dsp.getInverted() == true and flashTimer <= currentTime then
		dsp.setInverted(false)
	end
end


function clearFlash()
	dsp.setInverted(false)
end


-- +--------------------------------------------------------------+
-- |                           Position                           |
-- +--------------------------------------------------------------+


function getCameraPosition()
	return cameraPos
end


local function setCameraPos(angle, posX, posY)
	rad = math.rad(angle)
	cameraPos.x = camDistance.x * math.cos(rad) + posX
	cameraPos.y = camDistance.y * math.sin(rad) + posY - getHalfUIBannerHeight()	
end


-- Pass positions for shake direction - global function called to actually shake the camera
function cameraShake(strength, direction)
	if direction == nil then
		local randX, randY
		randX = math.random() * 2 - 1
		randY = math.random() * 2 - 1
		direction = vec.new(randX, randY):normalized()
	end

	shakeVelocity = direction * strength
	camBob = camAnchor + shakeVelocity

	shakeTimer = currentTime + setShakeTimer
end

--[[
local function calculateCameraShake()
	-- If the shake velocity is slow enough, just pass the anchor
	if shakeVelocity:magnitude() <= minCamDifference then 
		shakeVelocity = vec.new(0, 0)
		return camAnchor
	end

	-- If the shake timer has elapsed, move the shake velocity to 0
	if shakeTimer <= currentTime then
		shakeVelocity.x = moveTowards(shakeVelocity.x, 0, shakeEndDelta)
		shakeVelocity.y = moveTowards(shakeVelocity.y, 0, shakeEndDelta)
		return camAnchor + shakeVelocity
	end

	-- Calculate spring force
	local force = camBob - camAnchor
	local x = force:magnitude()

	force:normalize()
	force *= (-1 * springConstant * x)
	shakeVelocity += force
	shakeVelocity *= springDampen

	return camBob + shakeVelocity
end
]]--


local function calculateDisplayShake()
	-- If the shake velocity is slow enough, then set velocity to 0
	if shakeVelocity:magnitude() <= minCamDifference then 
		shakeVelocity = vec.new(0, 0)
		camBob = camAnchor
		return shakeVelocity
	end

	-- Calculate spring force
	local force = camBob - camAnchor
	local x = force:magnitude()

	-- Dampen force based on the shake timer
	local diff = setShakeTimer - (shakeTimer - currentTime)
	local t = clamp(diff / setShakeTimer, 0, 1)
	x = mathp.lerp(x, 0, t)

	force:normalize()
	force *= (-1 * springConstant * x)
	shakeVelocity += force
	shakeVelocity *= springDampen
	camBob += shakeVelocity

	return shakeVelocity
end


local function shakeCameraUpdate()
	vel = calculateDisplayShake()
	dsp.setOffset(vel.x, vel.y)
end


local function moveCamera()
	currentCameraPos.x = moveTowards(currentCameraPos.x, cameraPos.x, speed)
	currentCameraPos.y = moveTowards(currentCameraPos.y, cameraPos.y, speed)

	camAnchor.x = mathFloor(halfScreenWidth - currentCameraPos.x)
	camAnchor.y = mathFloor(halfScreenHeight - currentCameraPos.y)
	--camBob = calculateCameraShake()

	--gfx.setDrawOffset(camBob.x, camBob.y)
	gfx.setDrawOffset(camAnchor.x, camAnchor.y)
end


-- global function to snap the camera to its target position instead of trying to move there
function snapCamera()
	playerPos = getPlayerPosition()
	setCameraPos(getCrankAngle(), playerPos.x, playerPos.y)

	currentCameraPos.x = cameraPos.x
	currentCameraPos.y = cameraPos.y
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


function updateCamera(dt)
	currentTime = getRunTime()

	setCameraPos(getCrankAngle(), player.x, player.y)
	moveCamera()
	shakeCameraUpdate()

	manageScreenFlash()
end