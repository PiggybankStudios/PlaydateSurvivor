local gfx <const> = playdate.graphics
local ldtk <const> = LDtk

ldtk.load("Resources/Levels/world.ldtk", false)

class('gameScene').extends()


function gameScene:init()
	self:goToLevel("Level_0")
end


function gameScene:goToLevel(level_name)
	gfx.sprite.removeAll()

	-- catch for if a tileset png name follows the naming convention required by LDtk
	if ldtk.get_layers(level_name) == nil then
		print("no layers in level - something might be wrong with a file name")
		return
	end

	-- load in the level's tileset and (hopefully) collision
	for layer_name, layer in pairs(ldtk.get_layers(level_name)) do
		if layer.tiles then
			local tilemap = ldtk.create_tilemap(level_name, layer_name)
			
			local layerSprite = gfx.sprite.new()
			layerSprite:setTilemap(tilemap)
			layerSprite:setCenter(0, 0)
			layerSprite:moveTo(0, 0)
			layerSprite:setZIndex(layer.zIndex)
			layerSprite:add()

			local emptyTiles = ldtk.get_empty_tileIDs(level_name, "Solid", layer_name)
			if (emptyTiles) then
				local wallSpriteList = gfx.sprite.addWallSprites(tilemap, emptyTiles)
				for i = 1, #wallSpriteList do
					wallSpriteList[i]:setGroups(GROUPS.walls)	-- set each collider to the wall group
					wallSpriteList[i]:setTag(TAGS.walls)
				end
			end
		end
	end

	-- add the player's sprite back to the list and start the scene
	addPlayerSpritesToList()
	addUIBanner()
	snapCamera()
end