local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local random <const> = math.random

local theCurrTime = 0

-- Particle Type Variables --
-- This table needs to be identical to the global PARTICLE_TYPE in tags.lua - local here for speed
local LOCAL_PARTICLE_TYPE = {
	playerImpact = 1,
	enemyTrail = 2
}

-- Index position is the gun type - this list returns the speed for each gun type.
local PARTICLE_SPEEDS = {
	40, 	-- player impact
	0 		-- enemy trail
}

local PARTICLE_LIFETIMES = {
	1200,	-- player impact
	1500	-- enemy trail
}

local minParticleScale <const> = 0.1

-- Particles
local maxParticles <const> = 10000 -- max that can exist in the world at one time
local activeParticles = 0

-- Arrays
local particleType = {}
local posX = {}
local posY = {}
local rotation = {}
local scale = {}
local dirX = {}
local dirY = {}
local speed = {}
local lifeTime = {}



-----------
-- Debug --
local maxUpdateTimer = 0
local currentUpdateTimer = 0
-----------
-----------

-- +--------------------------------------------------------------+
-- |                           Timers                             |
-- +--------------------------------------------------------------+


local function getUpdateTimer()
	currentUpdateTimer = playdate.getElapsedTime()
	if maxUpdateTimer < currentUpdateTimer then
		maxUpdateTimer = currentUpdateTimer
		print("PARTICLE -- Update: " .. 1000*maxUpdateTimer)
	end
end


-- +--------------------------------------------------------------+
-- |                Init, Create, Delete, Handle                  |
-- +--------------------------------------------------------------+


--- Init Arrays ---
for i = 1, maxParticles do
	particleType[i] = 0
	posX[i] = 0
	posY[i] = 0
	rotation[i] = 0
	scale[i] = 0
	dirX[i] = 0
	dirY[i] = 0
	speed[i] = 0
	lifeTime[i] = 0
end


-- LOCAL create
local function createParticle(type, spawnX, spawnY, newRotation, newScale, newSpeed)
	if activeParticles >= maxParticles then do return end end -- if too many particles exist, then don't make another particle

	-- optional parameters
	newRotation = newRotation or 0
	newScale = newScale or 1
	newSpeed = newSpeed or 1

	activeParticles += 1
	local total = activeParticles
	local direction = vec.newPolar(1, newRotation)

	particleType[total] = type
	posX[total] = spawnX
	posY[total] = spawnY
	rotation[total] = newRotation
	scale[total] = newScale
	dirX[total] = direction.x
	dirY[total] = direction.y 
	speed[total] = PARTICLE_SPEEDS[type] * newSpeed
	lifeTime[total] = theCurrTime + PARTICLE_LIFETIMES[type]
end
local create <const> = createParticle


-- GLOBAL create
function spawnParticleEffect(type, spawnX, spawnY, direction)
	-- Optional Parameters
	direction = direction or 0

	local newAngle, newSize, newSpeed

	-- Player Impact
	if type == LOCAL_PARTICLE_TYPE.playerImpact then		
		for i = 1, 5 do
			newAngle = -1 * direction:angleBetween(vec.new(0, 1)) + math.random(-30, 30) + 180
			newSize = math.random() + math.random(3, 4)
			newSpeed = math.random(1, 4)
			create(type, spawnX, spawnY, newAngle, newSize, newSpeed)
		end
	
	-- Enemy Trail
	elseif type == LOCAL_PARTICLE_TYPE.enemyTrail then
		newAngle = math.random(0, 180)
		newSize = math.random() + 1
		create(type, spawnX, spawnY, newAngle, newSize)
	end
end


-- GLOBAL debug create
function debugParticleSpawn()
	local type = 2
	for i = 1, 10000 do		
		local x = random(-1000, 1000)
		local y = random(-1000, 1000)
		local angle = random(0, 180)
		local size = random() + 1
		create(type, x, y, angle, size)
	end
end


-- Delete
local function deleteParticle(index, currentActiveParticles)
	local i = index
	local total = currentActiveParticles

	-- overwrite the to-be-deleted particle with the particle at the end
	particleType[i] = particleType[total]
	posX[i] = posX[total]
	posY[i] = posY[total]
	rotation[i] = rotation[total]
	scale[i] = scale[total]
	dirX[i] = dirX[total]
	dirY[i] = dirY[total] 
	speed[i] = speed[total]
	lifeTime[i] = lifeTime[total]
end


-- +--------------------------------------------------------------+
-- |                     Paraticle Management                     |
-- +--------------------------------------------------------------+


function clearParticles()
	activeParticles = 0
end


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+


local img_playerImpact = gfx.image.new('Resources/Sprites/Particles/particle_PlayerImpact')
local img_enemyTrail = gfx.image.new('Resources/Sprites/Particles/particle_EnemyTrail')

local IMAGE_LIST = {
	img_playerImpact,
	img_enemyTrail
}

local IMAGE_DRAW = {
	function(i, x, y, size, angle)
		IMAGE_LIST[i]:drawRotated(x, y, angle, size)
	end,

	function(i, x, y, size)
		IMAGE_LIST[i]:drawScaled(x, y, size)
	end
}


local particlesImage = gfx.image.new(400, 240) -- screen size draw
local particlesSprite = gfx.sprite.new(particlesImage)
particlesSprite:setIgnoresDrawOffset(true)
particlesSprite:setZIndex(ZINDEX.particle)
particlesSprite:moveTo(200, 120)


-- Global to be called after level creation, b/c level start clears the sprite list
function addParticleSpriteToList()
	particlesSprite:add()
end


-- Constants for speed
local lockFocus <const> = gfx.lockFocus
local unlockFocus <const> = gfx.unlockFocus
local setColor <const> = gfx.setColor
local colorBlack <const> = gfx.kColorBlack
local colorClear <const> = gfx.kColorClear
local drawOffset <const> = gfx.getDrawOffset

local function scaleMove(i, dt, localCurrentTime, offsetX, offsetY)
	-- out of bounds - checking before movement bc particle could be deleted from camera movement OR spawned outside camera range
	local startX = posX[i] + offsetX
	local startY = posY[i] + offsetY
	if startX < -50 or 450 < startX or startY < -50 or 290 < startY then
		lifeTime[i] = 0 
		return startX, startY
	end

	-- scale - deletion from shrinking too small
	local type = particleType[i]
	local scalar = (lifeTime[i] - localCurrentTime) / PARTICLE_LIFETIMES[type]
	scale[i] *= scalar
	local size = scale[i]
	if size < minParticleScale then 
		lifeTime[i] = 0 
		return startX, startY
	end

	-- move - NOT DELETED
	local particleSpeed = speed[i]
	posX[i] += (dirX[i] * particleSpeed * dt)
	posY[i] += (dirY[i] * particleSpeed * dt)
	local x = posX[i] + offsetX
	local y = posY[i] + offsetY
	
	return x, y, type, size	
end

-- update function for moving particles and removing from particle list
local function updateParticleLists(dt, elapsedPauseTime)
	local localCurrentTime = theCurrTime
	local offsetX
	local offsetY
	offsetX, offsetY = drawOffset()

	particlesImage:clear(colorClear)
	lockFocus(particlesImage)

		-- set details
		setColor(colorBlack)

		local i = 1
		local currentActiveParticles = activeParticles
		while i <= currentActiveParticles do

			-- adjust pause time
			lifeTime[i] += elapsedPauseTime

			local x, y, type, size = scaleMove(i, dt, localCurrentTime, offsetX, offsetY)			

			-- delete
			if localCurrentTime >= lifeTime[i] then 
				deleteParticle(i, currentActiveParticles)
				currentActiveParticles -= 1
				i -= 1			
			
			-- draw, if not deleted
			else
				local image = IMAGE_LIST[type]
				local width, height = image:getSize()
				width *= 0.5 * size
				height *= 0.5 * size
				local angle = rotation[i]		
				IMAGE_DRAW[type](type, x - width, y - height, size, angle)
			end

			-- increment
			i += 1
		end
	unlockFocus()

	activeParticles = currentActiveParticles
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

--- DEBUG TEXT ---
local debugImage = gfx.image.new(160, 175, gfx.kColorWhite)
local debugSprite = gfx.sprite.new(debugImage)
debugSprite:setIgnoresDrawOffset(true)
debugSprite:moveTo(80, 100)
debugSprite:setZIndex(ZINDEX.uidetails)
------------------


function updateParticles(dt, mainTimePassed, mainLoopTime, elapsedPauseTime)
	-- Get run-time variables
	theCurrTime = mainLoopTime

	-- Particle Handling
	--playdate.resetElapsedTime()
		updateParticleLists(dt, elapsedPauseTime)
	--getUpdateTimer()

	--[[
	-- DEBUGGING
	debugImage:clear(gfx.kColorWhite)
	gfx.pushContext(debugImage)
		gfx.setColor(gfx.kColorWhite)
		gfx.drawRect(0, 0, 140, 150)
		gfx.setColor(gfx.kColorBlack)
		--gfx.drawText(" Cur C: " .. 1000*currentCreateTimer, 0, 0)
		gfx.drawText(" Update Timer: " .. 1000*currentUpdateTimer, 0, 25)
		gfx.drawText("Max Ptcl: " .. maxParticles, 0, 75)
		gfx.drawText("Active Ptcl: " .. activeParticles, 0, 100)
		gfx.drawText("FPS: " .. playdate.getFPS(), 0, 125)
		gfx.drawText("Main Time:" .. mainTimePassed, 0, 150)
	gfx.popContext()
	debugSprite:setImage(debugImage)
	debugSprite:add()
	-----
	]]--
end