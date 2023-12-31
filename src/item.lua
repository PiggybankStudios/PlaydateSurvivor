
local gfx <const> = playdate.graphics

class('item').extends(gfx.sprite)


ITEM_TYPE = {
	health = 1,
	ammo = 2, 
	shield = 3, 
	exp9 = 4, 
	exp3 = 5, 
	exp1 = 6, 
	absorbAll = 7
}


function item:init(x, y, type)
	item.super.init(self)
	--[[
	if type >= 99 then
		self.type = 3
	elseif type >= 35 then
		self.type = 2
	elseif type >= 65 then
		self.type = 1
	elseif type >= 60 then
		self.type = 4
	elseif type >= 45 then
		self.type = 5
	else
		self.type = 0
	end
	]]--
	self.type = type
	if (self.type == ITEM_TYPE.health) then
		self:setImage(gfx.image.new('Resources/Sprites/iHealth'))
	elseif (self.type == ITEM_TYPE.ammo) then
		self:setImage(gfx.image.new('Resources/Sprites/iAmmo'))
	elseif (self.type == ITEM_TYPE.shield) then
		self:setImage(gfx.image.new('Resources/Sprites/iShield'))
	elseif (self.type == ITEM_TYPE.exp9) then
		self:setImage(gfx.image.new('Resources/Sprites/iEXP9'))
	elseif (self.type == ITEM_TYPE.exp3) then
		self:setImage(gfx.image.new('Resources/Sprites/iEXP3'))
	elseif (self.type == ITEM_TYPE.exp1) then
		self:setImage(gfx.image.new('Resources/Sprites/iEXP1'))
	elseif (self.type == ITEM_TYPE.absorbAll) then
		self:setImage(gfx.image.new('Resources/Sprites/iAbsorbAll'))
	else
		-- default to exp1
		self.type = ITEM_TYPE.exp1
		self:setImage(gfx.image.new('Resources/Sprites/iEXP1'))
	end
	
	self.pickedUp = 0
	self.massAttraction = false
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


-- Only allow certain types of items ability to be mass attracted
function item:startMassAttraction()
	if self.type == ITEM_TYPE.absorbAll then
		self.massAttraction = false
	else
		self.massAttraction = true
	end
end


-- Function for getting mass attraction to avoid mistakes of accidentally setting it
function item:getMassAttraction()
	return self.massAttraction
end