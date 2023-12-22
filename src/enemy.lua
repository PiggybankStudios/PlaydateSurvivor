local gfx <const> = playdate.graphics

class('enemy').extends(gfx.sprite)


local healthbarOffsetY = 20


function enemy:init(x, y)
	enemy.super.init(self)
	self:setImage(gfx.image.new('Resources/Sprites/Enemy2'))
	self:moveTo(x, y)
	self:setTag(TAGS.enemy)
	self:setCollideRect(0, 0, self:getSize())

	self.health = 9

	-- draw healthbar
	self.healthbar = healthbar(x, y - healthbarOffsetY, self.health)
end


function enemy:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.player then
		return 'bounce'
	elseif tag == TAGS.weapon then
		return 'freeze'
	elseif tag == TAGS.enemy then
		return 'overlap'
	else --tag == walls
		return 'overlap'
	end
end


function enemy:damage(amount)
	self.health -= amount
	if self.health <= 0 then self.healt = 0 end

	self.healthbar:damage(amount)
end


function enemy:move(x, y)
	self:moveTo(x, y)
	self.healthbar:moveTo(x, y - healthbarOffsetY)
end