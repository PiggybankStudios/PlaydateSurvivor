local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2

local bannerHeight <const> = 30
local halfBannerHeight <const> = bannerHeight / 2


-- +--------------------------------------------------------------+
-- |                          Draw Banner                         |
-- +--------------------------------------------------------------+

local bannerImage = gfx.image.new('Resources/Sprites/UIBanner')
local bannerSprite = gfx.sprite.new(bannerImage)
bannerSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
bannerSprite:setZIndex(ZINDEX.uibanner)
bannerSprite:moveTo(halfScreenWidth, halfBannerHeight)


-- +--------------------------------------------------------------+
-- |                       Banner Functions                       |
-- +--------------------------------------------------------------+


function addUIBanner()
	bannerSprite:add()
end


function getHalfUIBannerHeight()
	return halfBannerHeight
end