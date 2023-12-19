-- playdate screen 400 x 240
local gfx <const> = playdate.graphics

local colliderSize <const> = 24


playerSheet = gfx.imagetable.new('Resources/Sheets/player')
animationLoop = gfx.animation.loop.new(16, playerSheet)

bullets = {}

enemies = {}

playerSpeed = 50
playerRunSpeed = 1
enemySpeed = 30

nextShotTime = 0
theSpawnTime = 0

-- +--------------------------------------------------------------+
-- |            Player Sprite and Collider Interaction            |
-- +--------------------------------------------------------------+

-- Global function called after level is created - level removes all sprites in game on level load
function createPlayerSprite()
	-- Sprite
	player = gfx.sprite:new()
	player:setImage(animationLoop:image())

	-- Collider -- not adding to sprite list, only using this for collision detection
	collider = gfx.sprite:new()
	collider:setSize(colliderSize, colliderSize)
	collider:setCollideRect(0, 0, colliderSize, colliderSize)
	collider.collisionResponse = 'slide'

	player:add()
	collider:add()

	movePlayerWithCollider(150,150) -- move to starting location
end


function movePlayerWithCollider(x, y)
	player:moveTo(x, y)
	collider:moveTo(x, y)
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
	local moveSpeed = playerSpeed * playerRunSpeed * dt
	goalX = player.x + inputX * moveSpeed
	goalY = player.y + inputY * moveSpeed

	local actualX, actualY = collider:checkCollisions(goalX, goalY)
	movePlayerWithCollider(actualX, actualY)
end

-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updatePlayer(dt)
	theCurrTime = playdate.getCurrentTimeMilliseconds()
	
	movePlayer(dt)
	player:setRotation(crankAngle)

	for bIndex,bullet in pairs(bullets) do
		bullet:update(dt, theCurrTime)
		if not bullet.isAlive then
			bullet:remove()
			table.remove(bullets, bIndex)
		end
	end
	
	for eIndex,enemy in pairs(enemies) do
		enemy:update(dt, player.x, player.y)
	end
	
	--[[
	local collisions = gfx.sprite.allOverlappingSprites()
	for i = 1, #collisions do
		local collisionPair = collisions[i]
		local sprite1 = collisionPair[1]
		local sprite2 = collisionPair[2]
		if sprite1.width ~= sprite2.width then
			sprite1:setZIndex(-99)
			sprite2:setZIndex(-99)
			--print("collision detected")
		end
	end
	]]--
	
	--spawn a bullet
	if theCurrTime >= nextShotTime then
		nextShotTime = theCurrTime + 200
		newBullet = Bullet(theCurrTime, 'Resources/Sprites/Bullet1', player.x, player.y, player:getRotation() + 90)
		bullets[#bullets + 1] = newBullet
		-- print("Firing!")
	end
	
	--spawn a monster 230 x 150
	if theCurrTime >= theSpawnTime then
		theSpawnTime = theCurrTime + 5000
		newEnemy = Enemy(theCurrTime, 'Resources/Sprites/Enemy2', player.x, player.y)
		enemies[#enemies + 1] = newEnemy
	end
	-- animationLoop:draw(player.x, player.y)
	-- animationLoop:draw(0, 0)
	-- print(player.x .. "," .. player.y)
end
