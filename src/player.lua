
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

playerSpeed = 50
playerRunSpeed = 1
bulletSpeed = 200

theTargTime = 0

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
	moveSpeed = playerSpeed * playerRunSpeed * dt
	theCurrTime = playdate.getCurrentTimeMilliseconds()
	
	player:moveTo(player.x + inputX * moveSpeed, player.y + inputY * moveSpeed)
	player:setRotation(crankAngle)

	for bIndex,bullet in pairs(bullets) do
		rotation = ((bullet:getRotation() - 90) / 180) * 3.1415926
		bullet:moveTo(bullet.x + (math.cos(rotation)) * bulletSpeed * dt, bullet.y + (math.sin(rotation)) * bulletSpeed * dt)
		if theCurrTime >= bulletLife[bIndex] then
			bullet:remove()
			table.remove(bullets,bIndex)
			table.remove(bulletLife,bIndex)
			--print("Dying!")
		end
	end
	
	if theCurrTime >= theTargTime then
		theTargTime = theCurrTime + 200
		newBullet = gfx.sprite:new()
		newBullet:setImage(gfx.image.new('Resources/Sprites/Bullet1'))
		newBullet:moveTo(player.x, player.y)
		newBullet:setRotation(player:getRotation() + 90)
		newBullet:addSprite()
		bullets[#bullets + 1] = newBullet
		newBulletLife = theCurrTime + 1000
		bulletLife[#bulletLife + 1] = newBulletLife
		-- print("Firing!")
	end
	-- animationLoop:draw(player.x, player.y)
	-- animationLoop:draw(0, 0)
	-- print(player.x .. "," .. player.y)
end
