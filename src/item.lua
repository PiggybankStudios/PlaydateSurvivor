
local gfx <const> = playdate.graphics

class('item').extends(gfx.sprite)


function item:init(x, y, type)
	
	item.super.init(self)
	self.type = type

	if (self.type == ITEM_TYPE.health) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iHealth'))

	elseif (self.type == ITEM_TYPE.weapon) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iWeapon'))

	elseif (self.type == ITEM_TYPE.shield) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iShield'))

	elseif (self.type == ITEM_TYPE.absorbAll) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iAbsorbAll'))

	elseif (self.type == ITEM_TYPE.luck) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iLuck'))

	elseif (self.type == ITEM_TYPE.exp1) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iEXP1'))

	elseif (self.type == ITEM_TYPE.exp2) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iEXP2'))

	elseif (self.type == ITEM_TYPE.exp3) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iEXP3'))

	elseif (self.type == ITEM_TYPE.exp6) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iEXP6'))

	elseif (self.type == ITEM_TYPE.exp9) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iEXP9'))

	elseif (self.type == ITEM_TYPE.exp16) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iEXP16'))
		
	elseif (self.type == ITEM_TYPE.mun2) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iMun2'))
		
	elseif (self.type == ITEM_TYPE.mun10) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iMun10'))
		
	elseif (self.type == ITEM_TYPE.mun50) then
		self:setImage(gfx.image.new('Resources/Sprites/item/iMun50'))

	else
		-- default to exp1
		self.type = ITEM_TYPE.exp1
		self:setImage(gfx.image.new('Resources/Sprites/item/iEXP1'))
	end
	
	self.pickedUp = 0
	self.massAttraction = false
	self:moveTo(x, y)
	self:setTag(TAGS.item)
	self:setCollideRect(0, 0, self:getSize())
end


function item:collisionResponse(other)
	return 'overlap'
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