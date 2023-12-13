-- playdate screen 400 x 240
gfx = playdate.graphics

playerSheet = gfx.imagetable.new('Resources/Sheets/player')
animationLoop = gfx.animation.loop.new(16, playerSheet)

player = gfx.sprite:new()
-- player:setImage(gfx.image.new('Resources/Sprites/Enemy1'))
player:setImage(animationLoop:image())
player:moveTo(100,100)
player:addSprite()

bullets = {}
bulletLife = {}

enemies = {}

playerSpeed = 50
playerRunSpeed = 1
bulletSpeed = 200
enemySpeed = 30

theShotTime = 0
theSpawnTime = 0
enemyX = {0,230,230,230,0,-230,-230,-230}
enemyY = {150,150,0,-150,-150,-150,0,150}

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

-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updatePlayer(dt)
	theCurrTime = playdate.getCurrentTimeMilliseconds()
	
	moveSpeed = playerSpeed * playerRunSpeed * dt
	player:moveTo(player.x + inputX * moveSpeed, player.y + inputY * moveSpeed)
	player:setRotation(crankAngle)
	for bIndex,bullet in pairs(bullets) do
		rotation = ((bullet:getRotation() - 90) / 180) * 3.1415926
		bullet:moveTo(bullet.x + (math.cos(rotation)) * bulletSpeed * dt, bullet.y + (math.sin(rotation)) * bulletSpeed * dt)
		--bullet:setCollideRect(bullet:getBounds())
		buletZ = bullet:getZIndex()
		if theCurrTime >= bulletLife[bIndex] or buletZ == -99 then
			bullet:remove()
			table.remove(bullets,bIndex)
			table.remove(bulletLife,bIndex)
		end
	end
	for eIndex,enemy in pairs(enemies) do
		enemyVec = playdate.geometry.vector2D.new(player.x - enemy.x,player.y - enemy.y)
		enemyVec:normalize()
		enemy:moveTo(enemy.x + (enemyVec.x * enemySpeed * dt), enemy.y + (enemyVec.y * enemySpeed * dt))
		--enemy:setCollideRect(enemy:getBounds())
		enemyZ = enemy:getZIndex()
		if enemyZ == -99 then
			enemy:remove()
			table.remove(enemies,eIndex)
		end
	end
	
	local collisions = gfx.sprite.allOverlappingSprites()

	for i = 1, #collisions do
	        local collisionPair = collisions[i]
	        local sprite1 = collisionPair[1]
	        local sprite2 = collisionPair[2]
	        if sprite1.width ~= sprite2.width then
	        	sprite1:setZIndex(-99)
	        	sprite2:setZIndex(-99)
	        	print("collision detected")
	        end
	end
	
	--spawn a bullet
	if theCurrTime >= theShotTime then
		theShotTime = theCurrTime + 200
		newBullet = gfx.sprite:new()
		newBullet:setImage(gfx.image.new('Resources/Sprites/Bullet1'))
		newBullet:moveTo(player.x, player.y)
		newBullet:setRotation(player:getRotation() + 90)
		newBullet:addSprite()
		newBullet:setCollideRect(newBullet::getBounds())
		bullets[#bullets + 1] = newBullet
		newBulletLife = theCurrTime + 1000
		bulletLife[#bulletLife + 1] = newBulletLife
		-- print("Firing!")
	end
	
	--spawn a monster 230 x 150
	if theCurrTime >= theSpawnTime then
		rndLoc = math.random(1,8)
		theSpawnTime = theCurrTime + 5000
		newEnemy = gfx.sprite:new()
		newEnemy:setImage(gfx.image.new('Resources/Sprites/Enemy2'))
		newEnemy:moveTo(player.x + enemyX[rndLoc], player.y + enemyY[rndLoc])
		--newEnemy:setRotation(player:getRotation() + 90)
		newEnemy:addSprite()
		newEnemy:setCollideRect(newEnemy::getBounds())
		enemies[#enemies + 1] = newEnemy
		-- print("Firing!")
	end
	-- animationLoop:draw(player.x, player.y)
	-- animationLoop:draw(0, 0)
	-- print(player.x .. "," .. player.y)
end
