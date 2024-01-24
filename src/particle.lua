local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local theCurrTime = 0
local playerPos = vec.new(0, 0)


-- Particle Type Variables --
--local PARTICLE_TYPE = {} -- is held in tags.lua b/c of communication between scripts

-- Index position is the gun type - this list returns the speed for each gun type.
local PARTICLE_SPEEDS = {
	0, 		-- none
	40, 	-- player impact
	0 		-- enemy trail
}

local PARTICLE_LIFETIMES = {
	0, 		-- none
	1200,	-- player impact
	1500	-- enemy trail
}

local minParticleScale <const> = 0.1

-- Particles
--local particleLifetime <const> = 3000 --1500
local maxParticles <const> = 500 -- max that can exist in the world at one time
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


-- +--------------------------------------------------------------+
-- |                Init, Create, Delete, Handle                  |
-- +--------------------------------------------------------------+


--- Init Arrays ---
for i = 1, maxParticles do
	particleType[i] = PARTICLE_TYPE.none
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
	if type == PARTICLE_TYPE.none then do return end end	

	-- optional parameters
	newRotation = newRotation or 0
	newScale = newScale or 1
	newSpeed = newSpeed or 1

	activeParticles += 1
	local direction = vec.newPolar(1, newRotation)

	particleType[activeParticles] = type
	posX[activeParticles] = spawnX
	posY[activeParticles] = spawnY
	rotation[activeParticles] = newRotation
	scale[activeParticles] = newScale
	dirX[activeParticles] = direction.x
	dirY[activeParticles] = direction.y 
	speed[activeParticles] = PARTICLE_SPEEDS[type] * newSpeed
	lifeTime[activeParticles] = theCurrTime + PARTICLE_LIFETIMES[type]
end


local function deleteParticle(index)
	-- overwrite the to-be-deleted particle with the particle at the end
	particleType[index] = particleType[activeParticles]
	posX[index] = posX[activeParticles]
	posY[index] = posY[activeParticles]
	rotation[index] = rotation[activeParticles]
	scale[index] = scale[activeParticles]
	dirX[index] = dirX[activeParticles]
	dirY[index] = dirY[activeParticles] 
	speed[index] = speed[activeParticles]
	lifeTime[index] = lifeTime[activeParticles]

	-- set the last particle to NONE and reduce active particles (effectively deletes the particle)
	particleType[activeParticles] = PARTICLE_TYPE.none
	activeParticles -= 1
end


-- GLOBAL create
function spawnParticleEffect(type, spawnX, spawnY, direction)
	-- Optional Parameters
	direction = direction or 0

	local newAngle, newSize, newSpeed

	-- Player Impact
	if type == PARTICLE_TYPE.playerImpact then		
		for i = 1, 5 do
			newAngle = -1 * direction:angleBetween(vec.new(0, 1)) + math.random(-30, 30) + 180
			newSize = math.random() + math.random(2, 3)
			newSpeed = math.random(1, 4)
			createParticle(type, spawnX, spawnY, newAngle, newSize, newSpeed)
		end
	
	-- Enemy Trail
	elseif type == PARTICLE_TYPE.enemyTrail then
		newAngle = math.random(0, 180)
		newSize = math.random() + 1
		createParticle(type, spawnX, spawnY, newAngle, newSize)
	end
end


-- +--------------------------------------------------------------+
-- |                     Paraticle Management                     |
-- +--------------------------------------------------------------+


-- Scale
local function adjustParticle(i, dt)
	local type = particleType[i]

	-- decrease size	
	local scalar = (lifeTime[i] - theCurrTime) / PARTICLE_LIFETIMES[type]
	scale[i] *= scalar
	if scale[i] <= minParticleScale then 
		lifeTime[i] = 0
	end
end


-- Movement
local function moveParticle(i, dt)
	posX[i] += (dirX[i] * speed[i] * dt)
	posY[i] += (dirY[i] * speed[i] * dt)
end


-- update function for moving particles and removing from particle list
local function updateParticleLists(dt)
	for i = 1, activeParticles do
		adjustParticle(i, dt)
		moveParticle(i, dt)

		if theCurrTime >= lifeTime[i] then 
			deleteParticle(i)
			i -= 1
		end
	end
end


function clearParticles()
	for i = 1, maxParticles do
		particleType[i] = PARTICLE_TYPE.none
		lifeTime[i] = 0
	end

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


local particlesImage = gfx.image.new(400, 240) -- screen size draw
local particlesSprite = gfx.sprite.new(particlesImage)
particlesSprite:setIgnoresDrawOffset(true)
particlesSprite:setZIndex(ZINDEX.particle)
particlesSprite:moveTo(200, 120)


-- Draws a specific single particle
local function drawSingleParticle(index, offsetX, offsetY)

	local type = particleType[index]
	if type == PARTICLE_TYPE.none then -- if the particle doesn't exist, don't draw it
		do return end
	end

	local imageID = type - 1
	local x = posX[index] + offsetX
	local y = posY[index] + offsetY
	local angle = rotation[index]
	local size = scale[index]
	local outsideScreen = false

	-- if particle is too far outside the screen, don't draw it and delete it
	if x < -50 or x > 450 then outsideScreen = true end
	if y < -50 or y > 290 then outsideScreen = true end
	if outsideScreen == true then
		lifeTime[index] = 0
		do return end
	end

	IMAGE_LIST[imageID]:drawRotated(x, y, angle, size)
end


-- Draws all particles to a screen-sized sprite in one push context
local function drawParticles()	

	particlesImage:clear(gfx.kColorClear)
	local offX, offY = gfx.getDrawOffset()

	-- if no particles, clear the sprite and don't try to draw anything
	if activeParticles == 0 then do return end end

	-- Create the new particles image
		gfx.pushContext(particlesImage)
			-- set details
			gfx.setColor(gfx.kColorBlack)

			-- loop through and draw each particle
			for i = 1, activeParticles do
				drawSingleParticle(i, offX, offY)
			end
		gfx.popContext()

	-- Draw the new particles sprite
	particlesSprite:setImage(particlesImage)
end


-- Global to be called after level creation, b/c level start clears the sprite list
function addParticleSpriteToList()
	particlesSprite:add()
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


function updateParticles(dt)
	-- Get run-time variables
	theCurrTime = playdate.getCurrentTimeMilliseconds()
	playerPos = getPlayerPosition()

	-- Particle Handling
	updateParticleLists(dt)
	drawParticles()

end