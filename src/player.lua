
gfx = playdate.graphics

playerSheet = gfx.imagetable.new('Resources/Sheets/player')
animationLoop = gfx.animation.loop.new(16, playerSheet)

player = gfx.sprite:new()
-- player:setImage(gfx.image.new('Resources/Sprites/Enemy1'))
player:setImage(animationLoop:image())
player:moveTo(100,100)
player:addSprite()

bullets = {}

playerSpeed = 200
bulletSpeed = 200

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

function playdate.AButtonDown()
	newBullet = gfx.sprite:new();
	newBullet:setImage(gfx.image.new('Resources/Sprites/Bullet1'))
	newBullet:moveTo(player.x, player.y)
	newBullet:setRotation(player:getRotation() + 90)
	newBullet:addSprite()
	bullets[#bullets + 1] = newBullet
	print("Firing!")
end

function playdate.cranked(change, acceleratedChange)
	crankAngle += change
end

-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updatePlayer(dt)
	moveSpeed = playerSpeed * dt
	player:moveTo(player.x + inputX * moveSpeed, player.y + inputY * moveSpeed)
	player:setRotation(crankAngle)
	for bIndex,bullet in pairs(bullets) do
		rotation = ((bullet:getRotation() - 90) / 180) * 3.1415926
		bullet:moveTo(bullet.x + (math.cos(rotation)) * bulletSpeed * dt, bullet.y + (math.sin(rotation)) * bulletSpeed * dt)
	end
	-- animationLoop:draw(player.x, player.y)
	-- animationLoop:draw(0, 0)
	-- print(player.x .. "," .. player.y)
end
