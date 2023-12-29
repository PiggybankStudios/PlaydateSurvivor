-- playdate screen 400 x 240
local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D
local mathFloor <const> = math.floor

local colliderSize <const> = 24
local healthbarOffsetY <const> = 20
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
collider = gfx.sprite:new()
collider:setTag(TAGS.player)
collider:setSize(colliderSize, colliderSize)
collider:setCollideRect(0, 0, colliderSize, colliderSize)

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
	player:setRotation(crankAngle)
	player:add()
	collider:add()
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
	playerPos = vec.new(player.x, player.y)
	enemyPos = vec.new(enemyX, enemyY)
	cameraShake(camShakeStrength, playerPos, enemyPos)
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


-- Collision response based on tags
function collider:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.weapon then
		return "overlap"
	elseif tag == TAGS.item then
		other:itemGrab()
		return "overlap"
	elseif tag == TAGS.enemy then
		return "overlap"
	else -- Any collision that's not set is defaulted to Wall Collision
		return "slide"
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
	if Pause then 
		Pause = false
		Unpaused = true
	else
		Pause = true
	end
end

function playdate.cranked(change, acceleratedChange)
	physicalCrankAngle += change
	crankAngle = physicalCrankAngle - 90
end

-- If any buttons are being held or pressed, then FALSE for not clearing. Otherwise return TRUE for no buttons pressed and okay to clear input
	-- Fixes bug when input increments too far
function clearPlayerInput()
	if playdate.getButtonState() == 0 then
		inputX = 0
		inputY = 0
		return true
	else
		return false
	end
end


function movePlayer(dt)
	if collider == nil then return end	-- If the collider doesn't exist, then don't look for collisions
	if clearPlayerInput() == true then return end 	-- If no buttons pressed, don't move and clear input

	local moveSpeed = playerSpeed * playerRunSpeed * dt
	goalX = player.x + inputX * moveSpeed
	goalY = player.y + inputY * moveSpeed

	-- The actual position is determined via collision response above
	local actualX, actualY, collisions = collider:checkCollisions(goalX, goalY)
	movePlayerWithCollider(actualX, actualY)
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
			newItem = item(enemies[eIndex].x, enemies[eIndex].y, enemies[eIndex].drop)
			newItem:add()
			items[#items + 1] = newItem
			enemies[eIndex]:remove()
			table.remove(enemies,eIndex)
		end
	end

	spawnMonsters()
end


-- +--------------------------------------------------------------+
-- |                  Monster Management                 |
-- +--------------------------------------------------------------+

function updateItems()
	for iIndex,item in pairs(items) do		
		if items[iIndex].pickedUp == 1 then
			if items[iIndex].type == 1 then
				heal(3)
			elseif items[iIndex].type == 2 then
				newWeapon(math.random(1, 3))
			elseif items[iIndex].type == 3 then
				shield(10000)
			elseif items[iIndex].type == 4 then
				addEXP(9)
			elseif items[iIndex].type == 5 then
				addEXP(3)
			else
				addEXP(1)
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

		updateBullets()
		updateMonsters()
		updateItems()
		
		theLastTime = theCurrTime
		Unpaused = false
	end
end
