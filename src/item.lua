
local gfx <const> = playdate.graphics

class('item').extends(gfx.sprite)


function item:init(x, y, type)
	item.super.init(self)
	if (type == 1) then
		self:setImage(gfx.image.new('Resources/Sprites/iHealth'))
	elseif (type == 2) then
		self:setImage(gfx.image.new('Resources/Sprites/iAmmo'))
	end
	self.type = type
	self:moveTo(x, y)
	self:setTag(TAGS.item)
	self:setCollideRect(0, 0, self:getSize())
end


function item:collisionResponse(other)
	local tag = other:getTag()
	if self.type == 1 then
		if tag == TAGS.player then
			other:heal(1)
			self:remove()
			return 'heal'
		else --tag == walls
			return 'overlap'
		end
	elseif self.type == 2 then
		if tag == TAGS.player then
			other:buff(1)
			self:remove()
			return 'buff'
		else --tag == walls
			return 'overlap'
		end
	end
end
