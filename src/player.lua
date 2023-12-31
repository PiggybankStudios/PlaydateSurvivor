-- playdate screen 400 x 240
local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D
local mathFloor <const> = math.floor


local healthbarOffsetY <const> = 30
local setDamageTimer <const> = 200
local halfScreenWidth <const> = playdate.display.getWidth() / 2
local halfScreenHeight <const> = playdate.display.getHeight() / 2

-- Sprite
playerSheet = gfx.imagetable.new('Resources/Sheets/player')
iplayerSheet = gfx.imagetable.new('Resources/Sheets/iplayer')
animationLoop = gfx.animation.loop.new(16, playerSheet)
ianimationLoop = gfx.animation.loop.new(16, iplayerSheet)
player = gfx.sprite:new()
player:setZIndex(ZINDEX.player)
player:setImage(animationLoop:image())

-- Collider
local colliderSize <const> = 24
collider = gfx.sprite:new()
collider:setTag(TAGS.player)
collider:setSize(colliderSize, colliderSize)
collider:setCollideRect(0, 0, colliderSize, colliderSize)

-- ItemAbsorber
local itemAbsorberSizeStart <const> = 100
local absorbSpeed <const> = 45
local itemAbsorberRange = itemAbsorberSizeStart
itemAbsorber = gfx.sprite:new()
itemAbsorber:setTag(TAGS.itemAbsorber)
itemAbsorber:setSize(itemAbsorberSizeStart, itemAbsorberSizeStart)
itemAbsorber:setCollideRect(0, 0, itemAbsorberSizeStart, itemAbsorberSizeStart)

-- Player
local playerSpeed = 50
local playerRunSpeed = 1
local maxHealth = 10
local health = maxHealth
local damageTimer = 0
local startingExpForLevel = 10
local playerHealthbar
local playerExpbar
local playerLevel = 0
local playerUpgradeAmount = 0


-- Bullets
bullets = {}
theShotTime = 0
gunType = 0

-- Particles
particles = {}

-- Enemies
enemies = {}
theSpawnTime = 0

-- Items
items = {}
invincibleTime = 10000
invincible = true

--Menu
Pause = false
Unpaused = false

-- +--------------------------------------------------------------+
-- |            Player Sprite and Collider Interaction            |
-- +--------------------------------------------------------------+

-- Add the player sprite and collider back to the drawing list after level load - also sets starting position
function addPlayerSpritesToList()	
	physicalCrankAngle = playdate.getCrankPosition()	-- Adjust crank angle and player angle on level load.
	crankAngle = physicalCrankAngle - 90				-- ensures physical crank angle always matches the player rotation
	player:setRotation(crankAngle)

	player:add()
	collider:add()
	itemAbsorber:add()
	health = maxHealth
	playerHealthbar = healthbar(player.x, player.y - healthbarOffsetY, health)
	playerExpbar = expbar(startingExpForLevel)
	movePlayerWithCollider(150,150) -- move to starting location
end


-- Moves both player sprite and collider - flooring stops jittering b/c only integers
function movePlayerWithCollider(x, y)
	local floorX = mathFloor(x)
	local floorY = mathFloor(y)
	player:moveTo(floorX, floorY)
	collider:moveTo(floorX, floorY)
	itemAbsorber:moveTo(floorX, floorY)
	playerHealthbar:moveTo(floorX, floorY - healthbarOffsetY)
end


-- Damage player health - called via enemies
function player:damage(amount, camShakeStrength, enemyX, enemyY)
	if Unpaused then damageTimer += theLastTime end
	-- Invincibility
	if damageTimer > theCurrTime then
		return
	elseif invincible then
		return
	end

	-- Damaging
	damageTimer = theCurrTime + setDamageTimer
	health -= amount
	if health < 0 then health = 0 end
	playerHealthbar:damage(amount)

	-- Camera Shake
	local playerPos = vec.new(player.x, player.y)
	local enemyPos = vec.new(enemyX, enemyY)
	local direction = (enemyPos - playerPos):normalized()
	cameraShake(camShakeStrength, direction)
	spawnParticles(PARTICLE_TYPE.impact, 5, direction)
	screenFlash()
end

function updateLevel()
	playerLevel += 1
end

function heal(amount)
	health += amount
	if health > maxHealth then health = maxHealth end

	playerHealthbar:heal(amount)
	print("healed")
end


function addEXP(amount)
	print("earnedEXP")
	playerExpbar:gainExp(amount)
end


function shield(amount)
	invincibleTime = theCurrTime + amount
	invincible = true
	print("shielded")
end


function newWeapon(weapon)
	gunType += weapon
	if gunType > 3 then
		gunType -= 4
	end
	print("new weapon")
end


function changeItemAbsorbRangeBy(value)
	itemAbsorberRange += value
	itemAbsorber:setSize(itemAbsorberRange, itemAbsorberRange)
	itemAbsorber:setCollideRect(0, 0, itemAbsorberRange, itemAbsorberRange)
end


function setItemAbsorbRange(value)
	itemAbsorberRange = value
	itemAbsorber:setSize(itemAbsorberRange, itemAbsorberRange)
	itemAbsorber:setCollideRect(0, 0, itemAbsorberRange, itemAbsorberRange)
end


-- Collision response based on tags
-- Player Collider
function collider:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.weapon then
		return "overlap"
	elseif tag == TAGS.item then
		other:itemGrab()
		return "overlap"
	elseif tag == TAGS.itemAbsorber then
		return "overlap"
	elseif tag == TAGS.enemy then
		return "overlap"
	else -- Any collision that's not set is defaulted to Wall Collision
		return "slide"
	end
end


-- Item Abosrber Collider
function itemAbsorber:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.item then
		-- if already being mass attracted, skip this absorb movement
		if other:getMassAttraction() == true then
			return "overlap"
		end

		-- if not within a circular range of the player, skip
		local distance = vec.new(player.x, player.y) - vec.new(other.x, other.y)
		if distance:magnitude() > (itemAbsorberRange / 2) then
			return "overlap"
		end

		-- okay to apply absorb movement
		local dt = 1/20
		local dir = distance:normalized()
		local x = other.x + dir.x * absorbSpeed * dt
		local y = other.y + dir.y * absorbSpeed * dt
		other:moveTo(x, y)
		return "overlap"
	else 
		return "overlap"	-- only looking for item collisions, all others don't matter.
	end
end

-- +--------------------------------------------------------------+
-- |                            Input                             |
-- +--------------------------------------------------------------+
inputX, inputY = 0, 0
local physicalCrankAngle = playdate.getCrankPosition()
crankAngle = physicalCrankAngle - 90

function playdate.leftButtonDown()
	inputX -= 1
end
function playdate.leftButtonUp()
	inputX += 1
end
function playdate.rightButtonDown()
	inputX += 1
end
function playdate.rightButtonUp()
	inputX -= 1
end
function playdate.upButtonDown()
	inputY -= 1
end
function playdate.upButtonUp()
	inputY += 1
end
function playdate.downButtonDown()
	inputY += 1
end
function playdate.downButtonUp()
	inputY -= 1
end

function playdate.BButtonDown()
	playerRunSpeed = 2
end

function playdate.BButtonUp()
	playerRunSpeed = 1
end

function playdate.AButtonDown()
	--[[
	if Pause then 
		Pause = false
		Unpaused = true
	else
		Pause = true
	end
	]]--
	changeItemAbsorbRangeBy(5)
end

function playdate.cranked(change, acceleratedChange)
	physicalCrankAngle += change
	crankAngle = physicalCrankAngle - 90
end


function movePlayer(dt)
	if collider == nil then return end	-- If the collider doesn't exist, then don't look for collisions

	-- Reset input to 0 if nothing is held
	if playdate.getButtonState() == 0 then
		inputX = 0
		inputY = 0
	end

	local moveSpeed = playerSpeed * playerRunSpeed * dt
	local goalX = player.x + inputX * moveSpeed
	local goalY = player.y + inputY * moveSpeed

	-- The actual position is determined via collision response above
	local actualX, actualY, collisions = collider:checkCollisions(goalX, goalY)
	movePlayerWithCollider(actualX, actualY)
end


-- Checking for collisions with items to move them towards the player
function itemAbsorberCollisions()
	if itemAbsorber == nil then return end
	itemAbsorber:checkCollisions(player.x, player.y)
end


-- +--------------------------------------------------------------+
-- |                     Paraticle Management                     |
-- +--------------------------------------------------------------+


function spawnParticles(type, amount, direction)
	for i = 1, amount do
		newParticle = particle(player.x, player.y, type, theCurrTime, direction)
		particles[#particles + 1] = newParticle
	end
end


-- update function for moving particles and removing from particle list
local function updateParticles()
	for index, particle in pairs(particles) do
		particle:move(theCurrTime)
		if theCurrTime >= particle.lifeTime then
			particle:remove()
			table.remove(particles, index)
		end
	end
end

-- +--------------------------------------------------------------+
-- |                       Bullet Management                      |
-- +--------------------------------------------------------------+


function spawnBullets()
	if Unpaused then theShotTime += theLastTime end
	if theCurrTime >= theShotTime then
		local newRotation = player:getRotation() + 90
		local newLifeTime = theCurrTime + 1500
		
		if gunType == 1 then --cannon
			theShotTime = theCurrTime + 500
			newBullet = bullet(player.x, player.y, newRotation, newLifeTime, gunType)
			newBullet:add()
			bullets[#bullets + 1] = newBullet 
		elseif gunType == 2 then -- minigun
			theShotTime = theCurrTime + 100
			newBullet = bullet(player.x, player.y, newRotation + math.random(-8, 8), newLifeTime, gunType)
			newBullet:add()
			bullets[#bullets + 1] = newBullet
		elseif gunType == 3 then -- shotgun
			theShotTime = theCurrTime + 300
			newBullet = bullet(player.x, player.y, newRotation+ math.random(-8, 8), newLifeTime, gunType)
			newBullet:add()
			bullets[#bullets + 1] = newBullet
			newBullet = bullet(player.x, player.y, newRotation + math.random(10, 25), newLifeTime, gunType)
			newBullet:add()
			bullets[#bullets + 1] = newBullet
			newBullet = bullet(player.x, player.y, newRotation - math.random(10, 25), newLifeTime, gunType)
			newBullet:add()
			bullets[#bullets + 1] = newBullet
		else --peagun
			theShotTime = theCurrTime + 200
			newBullet = bullet(player.x, player.y, newRotation, newLifeTime, gunType)
			newBullet:add()
			bullets[#bullets + 1] = newBullet 
		end

	end
end


-- Bullet movement and spawning
function updateBullets()
	-- Movement
	for bIndex,bullet in pairs(bullets) do
		bullet:move()
		
	if Unpaused then bullets[bIndex].lifeTime += theLastTime end
		if theCurrTime >= bullets[bIndex].lifeTime then
			bullets[bIndex]:remove()
			table.remove(bullets, bIndex)
		end
	end
	-- Spawning
	spawnBullets()
end

-- +--------------------------------------------------------------+
-- |                       Monster Management                     |
-- +--------------------------------------------------------------+
-- Monster movement and spawning
	-- TO DO:
		-- Need to move spawning logic into enemy class
		-- Need to make multiple types of enemies that can be selected
function spawnMonsters()
	-- Movement
	if Unpaused then theSpawnTime += theLastTime end
	if theCurrTime >= theSpawnTime then
		rndLoc = math.random(1,8)
		theSpawnTime = theCurrTime + 3000

		direction = { 	x = math.random(-1,1), 
						y = math.random(-1,1)}		        -- either -1, 0, 1
		if (direction.x == 0 and direction.y == 0) then
			direction.x = (math.random(0,1) * 2) - 1 
			direction.y = (math.random(0,1) * 2) - 1		-- either -1 or 1
		end
		distance = { 	x = math.random(), 
						y = math.random() }					-- between 0 to 1
		enemyX = player.x + (halfScreenWidth + (halfScreenWidth * distance.x)) * direction.x
		enemyY = player.y + (halfScreenHeight + (halfScreenHeight * distance.y)) * direction.y

		local eType = math.random(1, 4)
		local eAccel = 0.5

		newEnemy = enemy(enemyX, enemyY, eType, theCurrTime)
		newEnemy:add()

		enemies[#enemies + 1] = newEnemy
	end
end


function updateMonsters()
	for eIndex,enemy in pairs(enemies) do		
		if Unpaused then enemies[eIndex].time += theLastTime end
		enemy:move(player.x, player.y, theCurrTime)
		if enemies[eIndex].health <= 0 then
			newItem = item(enemies[eIndex].x, enemies[eIndex].y, enemies[eIndex]:getDrop())
			newItem:add()
			items[#items + 1] = newItem
			enemies[eIndex]:remove()
			table.remove(enemies,eIndex)
		end
	end

	spawnMonsters()
end


-- +--------------------------------------------------------------+
-- |                       Item Management                        |
-- +--------------------------------------------------------------+


function attractAllItems()
	print("attracting items")
	for iIndex,item in pairs(items) do	
		item:startMassAttraction()
	end
end


function updateItems(dt)
	for iIndex,item in pairs(items) do	

		-- Moving all items if being attracted
		if item:getMassAttraction() == true then
			local dir = (vec.new(player.x, player.y) - vec.new(item.x, item.y)):normalized()
			local x = item.x + dir.x * absorbSpeed * dt * 3
			local y = item.y + dir.y * absorbSpeed * dt * 3
			item:moveTo(x, y)
		end

		-- Item effect when picked up	
		if items[iIndex].pickedUp == 1 then
			if items[iIndex].type == ITEM_TYPE.health then
				heal(3)
			elseif items[iIndex].type == ITEM_TYPE.ammo then
				newWeapon(math.random(1, 3))
			elseif items[iIndex].type == ITEM_TYPE.shield then
				shield(10000)
			elseif items[iIndex].type == ITEM_TYPE.exp9 then
				addEXP(9)
			elseif items[iIndex].type == ITEM_TYPE.exp3 then
				addEXP(3)
			elseif items[iIndex].type == ITEM_TYPE.absorbAll then 
				attractAllItems()
			else
				addEXP(1)	-- default is exp1
			end
			
			items[iIndex]:remove()
			table.remove(items,iIndex)
		end
	end
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updatePlayer(dt)
	theCurrTime = playdate.getCurrentTimeMilliseconds()
	
	if Pause == false then
		if Unpaused then theLastTime = theCurrTime - theLastTime end
		if Unpaused then invincibleTime += theLastTime end
		if invincibleTime > theCurrTime then
			if ((theCurrTime % 500) >= 250 ) then
				player:setImageDrawMode(gfx.kDrawModeInverted)
				print("inverted")
			else
				player:setImageDrawMode(gfx.kDrawModeCopy)
			end
		else
			if invincible then
				invincible = false
				player:setImage(animationLoop:image())
			end
		end
		
		movePlayer(dt)
		player:setRotation(crankAngle)
		itemAbsorberCollisions()

		updateBullets()
		updateMonsters()
		updateParticles()
		updateItems(dt)
		
		theLastTime = theCurrTime
		Unpaused = false
	end
end
