
local gfx <const> = playdate.graphics

class('item').extends(gfx.sprite)


function item:init(x, y, type)
	item.super.init(self)
	if type >= 10 then
		self.type = 2
	elseif type >= 7 then
		self.type = 1
	else
		self.type = 0
	end
	
	if (type == 1) then
		self:setImage(gfx.image.new('Resources/Sprites/iHealth'))
	elseif (type == 2) then
		self:setImage(gfx.image.new('Resources/Sprites/iAmmo'))
	else
		self:setImage(gfx.image.new('Resources/Sprites/iEXP'))
	end
	
	self.pickedUp = 0
	self:moveTo(x, y)
	self:setTag(TAGS.item)
	self:setCollideRect(0, 0, self:getSize())
end


function item:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.player then
		return 'overlap'
	else --tag == walls
		return 'overlap'
	end 
end

function item:itemGrab()
	self.pickedUp = 1
end
