local gfx <const> = playdate.graphics

class('bulletGraphic').extends(gfx.sprite)

-- sheet
local pea = gfx.imagetable.new('Resources/Sheets/BulletPeagun')
local burst = gfx.imagetable.new('Resources/Sheets/BulletBurst')
local cannon = gfx.imagetable.new('Resources/Sheets/BulletCannon')
local grenade = gfx.imagetable.new('Resources/Sheets/BulletGrenade')
local pellet = gfx.imagetable.new('Resources/Sheets/BulletGrenadePellet')
local mini = gfx.imagetable.new('Resources/Sheets/BulletMinigun')
local rang = gfx.imagetable.new('Resources/Sheets/BulletRanggun')
local shot = gfx.imagetable.new('Resources/Sheets/BulletShotgun')
local wave = gfx.imagetable.new('Resources/Sheets/BulletWavegun')
local wave1 = gfx.image.new('Resources/Sprites/bullet/BulletWavegun1')
local wave2 = gfx.image.new('Resources/Sprites/bullet/BulletWavegun2')
local wave3 = gfx.image.new('Resources/Sprites/bullet/BulletWavegun3')
local wave4 = gfx.image.new('Resources/Sprites/bullet/BulletWavegun4')
local wave5 = gfx.image.new('Resources/Sprites/bullet/BulletWavegun5')
local wave6 = gfx.image.new('Resources/Sprites/bullet/BulletWavegun6')
local wave7 = gfx.image.new('Resources/Sprites/bullet/BulletWavegun7')
local wave8 = gfx.image.new('Resources/Sprites/bullet/BulletWavegun8')


function whichBullet(type,rotation)
	if type == 1 then 
		return pea:getImage(rotation, 1)
	elseif type == 2 then 
		return cannon:getImage(rotation, 1)
	elseif type == 3 then 
		return mini:getImage(rotation, 1)
	elseif type == 4 then 
		return shot:getImage(rotation, 1)
	elseif type == 5 then 
		return burst:getImage(rotation, 1)
	elseif type == 6 then 
		return grenade:getImage(rotation, 1)
	elseif type == 7 then 
		return rang:getImage(rotation, 1)
	elseif type == 8 then 
		if rotation == 1 then return wave1
		elseif rotation == 2 then return wave1
		elseif rotation == 3 then return wave3
		elseif rotation == 4 then return wave3
		elseif rotation == 5 then return wave5
		elseif rotation == 6 then return wave5
		elseif rotation == 7 then return wave7
		elseif rotation == 8 then return wave7
		else return wave1
		end
	elseif type == 99 then 
		return pellet:getImage(rotation, 1)
	else 
		return pea:getImage(rotation, 1)
	end
end