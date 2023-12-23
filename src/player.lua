-- playdate screen 400 x 240
local gfx <const> = playdate.graphics
local vec <const> = playdate.geometry.vector2D

local colliderSize <const> = 24
local healthbarOffsetY <const> = 20
local setDamageTimer <const> = 200


-- Sprite
playerSheet = gfx.imagetable.new('Resources/Sheets/player')
animationLoop = gfx.animation.loop.new(16, playerSheet)
player = gfx.sprite:new()
player:setImage(animationLoop:image())

-- Collider
collider = gfx.sprite:new()
collider:setTag(TAGS.player)
collider:setSize(colliderSize, colliderSize)
collider:setCollideRect(0, 0, colliderSize, colliderSize)

-- Bullets & Enemies
bullets = {}
enemies = {}

local playerSpeed = 50
local playerRunSpeed = 1
local maxHealth = 10
local health = maxHealth
local damageTimer = 0
local playerHealthbar

enemySpeed = 30

nextShotTime = 0
theSpawnTime = 0

-- +--------------------------------------------------------------+
-- |            Player Sprite and Collider Interaction            |
-- +--------------------------------------------------------------+

-- Add the player sprite and collider back to the drawing list after level load - also sets starting position
function addPlayerSpritesToList()
	player:add()
	collider:add()
	health = maxHealth
	playerHealthbar = healthbar(player.x, player.y - healthbarOffsetY, health)
	movePlayerWithCollider(150,150) -- move to starting location
end


-- Moves both player sprite and collider
function movePlayerWithCollider(x, y)
	player:moveTo(x, y)
	collider:moveTo(x, y)
	playerHealthbar:moveTo(x, y - healthbarOffsetY)
end


-- Damage player health
function damagePlayer(amount)
	if damageTimer > theCurrTime then
		return
	end

	damageTimer = theCurrTime + setDamageTimer
	health -= amount
	if health < 0 then health = 0 end

	playerHealthbar:damage(amount)
end


-- Collision response based on tags
function collider:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.weapon then
		return "overlap"
	elseif tag == TAGS.enemy then
		damagePlayer(1)
		return "overlap"
	else -- Any collision that's not set is defaulted to Wall Collision
		return "slide"
	end
end

-- +--------------------------------------------------------------+
-- |                            Input                             |
-- +--------------------------------------------------------------+
inputX, inputY = 0, 0
crankAngle = 0

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

function playdate.cranked(change, acceleratedChange)
	crankAngle += change
end


function movePlayer(dt)
	if collider == nil then return end	-- If the collider doesn't exist, then don't look for collisions

	local moveSpeed = playerSpeed * playerRunSpeed * dt
	goalX = player.x + inputX * moveSpeed
	goalY = player.y + inputY * moveSpeed

	-- The actual position is determined via collision response above
	local actualX, actualY, collisions = collider:checkCollisions(goalX, goalY)
	movePlayerWithCollider(actualX, actualY)
end

-- +--------------------------------------------------------------+
-- |                  Bullet & Monster Management                 |
-- +--------------------------------------------------------------+


function spawnBullets()
	if theCurrTime >= theShotTime then
		theShotTime = theCurrTime + 200

		local newRotation = player:getRotation() + 90
		local newLifeTime = theCurrTime + 1000
		newBullet = bullet(player.x, player.y, newRotation, newLifeTime)
		newBullet:add()

		bullets[#bullets + 1] = newBullet
	end
end


-- Bullet movement and spawning
function updateBullets()
	-- Movement
	for bIndex,bullet in pairs(bullets) do
		bullet:move(bulletSpeed)
		if theCurrTime >= bullets[bIndex].lifeTime then
			bullets[bIndex]:remove()
			table.remove(bullets, bIndex)
		end
	end

	-- Spawning
	spawnBullets()
end


-- Monster movement and spawning
function spawnMonsters()
	-- Movement
	if theCurrTime >= theSpawnTime then
		rndLoc = math.random(1,8)
		theSpawnTime = theCurrTime + 3000

		local startX = player.x + enemyX[rndLoc]
		local startY = player.y + enemyY[rndLoc]
		newEnemy = enemy(startX, startY)
		newEnemy:add()

		enemies[#enemies + 1] = newEnemy
	end
end


function updateMonsters()
	for eIndex,enemy in pairs(enemies) do
		enemy:update(dt, player.x, player.y)
		local newX = enemy.x + (enemyVec.x * enemySpeed * dt)
		local newY = enemy.y + (enemyVec.y * enemySpeed * dt)
		enemy:move(newX, newY)
		if enemies[eIndex].health <= 0 then
			enemies[eIndex]:remove()
	end

	spawnMonsters()
end
	]]--



-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updatePlayer(dt)
	theCurrTime = playdate.getCurrentTimeMilliseconds()
	
	movePlayer(dt)
	player:setRotation(crankAngle)

	updateBullets()
	updateMonsters()
end
